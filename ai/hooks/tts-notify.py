#!/usr/bin/env python3
"""Speak only "an agent needs you" hook events through mcp-tts (say_tts).

Routine turn completions are intentionally silent — milestone summaries are the
agent's job via the /speak skill. We announce ONLY when an agent is blocked on
input/approval or has errored, so you know to come back. Every alert leads with
the project name (which tmux/project is calling) and uses a distinct voice per
event type so you can tell WHAT it needs by sound alone:

    approval (permission / Codex approval)        -> system voice (a Siri voice)
    input    (question / plan / elicitation)      -> Serena (Premium)
    failure  (StopFailure)                        -> Matilda (Premium)

Override any voice via DOTFILES_TTS_VOICE_{APPROVAL,INPUT,FAILURE}; an empty
value means "no -v", so say_tts speaks with the macOS System Voice (a Siri voice).

Speech goes through `mcp-tts say_tts`, whose system-wide lock
(/tmp/mcp-tts-global.lock.d, taken via atomic mkdir) serializes audio across
every agent and hook so alerts never talk over each other. A bare `say` is the
last-resort fallback when the mcp-tts binary is missing.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import select
import shutil
import subprocess
import sys
import textwrap
import time
from pathlib import Path
from typing import Any

# Per-event voices ("" => no -v => the macOS System Voice). Override via env.
VOICE_APPROVAL = os.environ.get("DOTFILES_TTS_VOICE_APPROVAL", "")
VOICE_INPUT = os.environ.get("DOTFILES_TTS_VOICE_INPUT", "Serena (Premium)")
VOICE_FAILURE = os.environ.get("DOTFILES_TTS_VOICE_FAILURE", "Matilda (Premium)")
RATE = int(os.environ.get("DOTFILES_TTS_RATE", "220"))
MAX_CHARS = 200
MCP_PROTOCOL_VERSION = "2025-06-18"
MCP_DEADLINE_SECS = 45.0
SAY_TIMEOUT_SECS = 45


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", nargs="?", default="auto")
    parser.add_argument("--background", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--speak-text")
    parser.add_argument("--voice", default="")
    parser.add_argument("json_args", nargs="*")
    return parser.parse_args()


def load_event(args: argparse.Namespace) -> dict[str, Any]:
    for arg in reversed(args.json_args):
        value = arg.strip()
        if value.startswith("{") and value.endswith("}"):
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                pass
    if not sys.stdin.isatty():
        data = sys.stdin.read().strip()
        if data:
            try:
                return json.loads(data)
            except json.JSONDecodeError:
                return {}
    return {}


def clean(value: Any) -> str:
    """Speech-friendly text: drop code spans / links; textwrap.shorten then
    collapses whitespace and trims. Use field() for raw, non-spoken values."""
    text = "" if value is None else str(value)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"https?://\S+", " a link ", text)
    return textwrap.shorten(text, width=MAX_CHARS, placeholder="...")


def field(event: dict[str, Any], key: str) -> str:
    """A raw event field as a trimmed string — for comparison, not speech."""
    return str(event.get(key) or "").strip()


def project(event: dict[str, Any]) -> str:
    cwd = clean(event.get("cwd"))
    return (Path(cwd).name or cwd) if cwd else Path.cwd().name


def build(mode: str, event: dict[str, Any]) -> tuple[str, str]:
    """Return (spoken_text, voice) for 'needs-you' events; ('', '') = stay silent.

    Fires only on events that mean a human is genuinely required. AskUserQuestion,
    ExitPlanMode, and elicitation are mode-proof (auto modes can't answer them).
    `permission_prompt` is gated on permission_mode because it fires spuriously
    (phantom events + auto-allowed checks) in the auto modes — see Claude Code
    issues #16102 / #29212.
    """
    hook = field(event, "hook_event_name")
    phrase, voice = "", ""

    if hook == "PreToolUse":  # genuine "needs you" tools, regardless of mode
        tool = field(event, "tool_name")
        if tool == "AskUserQuestion":
            phrase, voice = "has a question for you.", VOICE_INPUT
        elif tool == "ExitPlanMode":
            phrase, voice = "has a plan for you to review.", VOICE_INPUT
    elif hook == "Notification":
        ntype = field(event, "notification_type")
        # permission_prompt is a real, blocking prompt only in `default` mode;
        # the auto modes auto-resolve it (and the field is often absent on
        # phantom events) -> stay silent; PreToolUse triggers cover real needs.
        if ntype == "permission_prompt" and field(event, "permission_mode") == "default":
            phrase, voice = "needs your approval.", VOICE_APPROVAL
        elif ntype == "elicitation_dialog":
            phrase, voice = "needs your input.", VOICE_INPUT
    elif hook == "StopFailure":
        err = clean(event.get("error") or event.get("error_type")) or "an error"
        phrase, voice = f"stopped on {err}.", VOICE_FAILURE
    elif hook == "PermissionRequest":  # Codex approval gate (fires only on real asks)
        phrase, voice = f"needs approval for {clean(event.get('tool_name')) or 'a tool'}.", VOICE_APPROVAL

    if not phrase:
        return "", ""
    agent = "Codex" if mode.lower().startswith("codex") else "Claude"
    return f"{project(event)}: {agent} {phrase}", voice


def speak_via_mcp(text: str, voice: str) -> bool:
    mcp_tts = shutil.which("mcp-tts")
    if not mcp_tts:
        return False

    arguments: dict[str, Any] = {"text": text, "rate": RATE}
    if voice:
        arguments["voice"] = voice
    messages = [
        {
            "jsonrpc": "2.0", "id": 1, "method": "initialize",
            "params": {
                "protocolVersion": MCP_PROTOCOL_VERSION, "capabilities": {},
                "clientInfo": {"name": "dotfiles-tts-hook", "version": "2.0.0"},
            },
        },
        {"jsonrpc": "2.0", "method": "notifications/initialized"},
        {
            "jsonrpc": "2.0", "id": 2, "method": "tools/call",
            "params": {"name": "say_tts", "arguments": arguments},
        },
    ]
    payload = "".join(json.dumps(m, separators=(",", ":")) + "\n" for m in messages)

    try:
        proc = subprocess.Popen(
            [mcp_tts],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, text=True,
        )
    except OSError:
        return False

    try:
        if proc.stdin is None or proc.stdout is None:
            return False
        proc.stdin.write(payload)
        proc.stdin.flush()

        deadline = time.monotonic() + MCP_DEADLINE_SECS
        while time.monotonic() < deadline:
            ready, _, _ = select.select(
                [proc.stdout], [], [], min(deadline - time.monotonic(), 0.5)
            )
            if not ready:
                if proc.poll() is not None:
                    return False
                continue
            line = proc.stdout.readline()
            if not line:
                return False
            try:
                response = json.loads(line)
            except json.JSONDecodeError:
                continue
            if response.get("id") != 2:
                continue
            result = response.get("result")
            return (
                "error" not in response
                and isinstance(result, dict)
                and result.get("isError") is not True
            )
        return False
    except OSError:
        return False
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=1)
        except subprocess.TimeoutExpired:
            proc.kill()


def speak_native(text: str, voice: str) -> bool:
    say = shutil.which("say") or "/usr/bin/say"
    cmd = [say]
    if voice:
        cmd += ["-v", voice]
    cmd += ["-r", str(RATE), text]
    try:
        return subprocess.run(cmd, check=False, timeout=SAY_TIMEOUT_SECS).returncode == 0
    except (OSError, subprocess.TimeoutExpired):
        return False


def spawn_background(text: str, voice: str, mode: str) -> int:
    try:
        subprocess.Popen(
            [
                sys.executable, str(Path(__file__).resolve()), mode,
                "--speak-text", text, "--voice", voice,
            ],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL, start_new_session=True,
        )
    except OSError:
        return 1
    return 0


def main() -> int:
    args = parse_args()
    if args.speak_text is not None:
        text, voice = clean(args.speak_text), args.voice
    else:
        text, voice = build(args.mode, load_event(args))
    if not text:
        return 0
    if args.dry_run:
        print(f"[{voice or 'system voice'}] {text}")
        return 0
    if args.background:
        return spawn_background(text, voice, args.mode)
    return 0 if (speak_via_mcp(text, voice) or speak_native(text, voice)) else 1


if __name__ == "__main__":
    raise SystemExit(main())
