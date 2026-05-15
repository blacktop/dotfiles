#!/usr/bin/env python3
"""Speak Codex and Claude hook events through mcp-tts."""

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

try:
    import fcntl
except ImportError:  # pragma: no cover - this dotfiles hook is macOS/Linux oriented.
    fcntl = None


MCP_PROTOCOL_VERSION = "2025-06-18"
DEFAULT_TOOL = os.environ.get("DOTFILES_TTS_HOOK_PROVIDER") or "google_tts"
DEFAULT_RATE = 220
MAX_SPOKEN_CHARS = 520
MCP_RESPONSE_TIMEOUT_SECS = 7.0
PROCESS_SHUTDOWN_TIMEOUT_SECS = 0.5
SAY_TIMEOUT_SECS = 30
TTS_TOOL_CHAIN = ("google_tts", "openai_tts", "elevenlabs_tts", "say_tts")
TTS_TOOL_ALIASES = {
    "google": "google_tts",
    "openai": "openai_tts",
    "elevenlabs": "elevenlabs_tts",
    "say": "say_tts",
}
MCP_TOOL_VOICES = {
    "google_tts": "Kore",
    "openai_tts": "sage",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", nargs="?", default="auto")
    parser.add_argument("--background", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--speak-text")
    parser.add_argument("--tool", default=DEFAULT_TOOL)
    parser.add_argument("--rate", type=int, default=DEFAULT_RATE)
    parser.add_argument("--mcp-no-play-dir")
    parser.add_argument("json_args", nargs="*")
    return parser.parse_args()


def load_event(args: argparse.Namespace) -> dict[str, Any]:
    for arg in reversed(args.json_args):
        value = arg.strip()
        if value.startswith("{") and value.endswith("}"):
            return json.loads(value)

    stdin = sys.stdin.read().strip()
    if stdin:
        return json.loads(stdin)
    return {}


def clean_text(value: Any) -> str:
    text = "" if value is None else str(value)
    text = re.sub(r"```.*?```", " see the code block. ", text, flags=re.DOTALL)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"https?://\S+", " see the link ", text)
    text = re.sub(r"(?m)^\s*[-*+]\s+", "", text)
    text = re.sub(r"(?m)^\s{0,3}#{1,6}\s*", "", text)
    text = text.replace("~", " ")
    text = re.sub(r"\s+", " ", text).strip()
    return textwrap.shorten(text, width=MAX_SPOKEN_CHARS, placeholder="...")


def short_id(value: Any) -> str:
    text = clean_text(value)
    if not text:
        return "unknown"
    return text[:8]


def project_name(event: dict[str, Any]) -> str:
    cwd = clean_text(event.get("cwd"))
    if not cwd:
        return Path.cwd().name
    return Path(cwd).name or cwd


def common_suffix(event: dict[str, Any]) -> str:
    session = (
        event.get("session_id")
        or event.get("thread-id")
        or event.get("thread_id")
        or event.get("sessionId")
    )
    turn = event.get("turn_id") or event.get("turn-id")
    pieces = [f"project {project_name(event)}"]
    if session:
        pieces.append(f"session {short_id(session)}")
    if turn:
        pieces.append(f"turn {short_id(turn)}")
    return ", ".join(pieces)


def codex_text(event: dict[str, Any]) -> str:
    event_type = clean_text(event.get("type"))
    hook_event = clean_text(event.get("hook_event_name"))

    if event_type == "agent-turn-complete":
        summary = clean_text(
            event.get("last-assistant-message") or event.get("last_assistant_message")
        )
        if summary:
            return f"Codex finished a turn in {common_suffix(event)}. {summary}"
        return f"Codex finished a turn in {common_suffix(event)}."

    if hook_event == "PermissionRequest":
        tool = clean_text(event.get("tool_name")) or "a tool"
        tool_input = (
            event.get("tool_input") if isinstance(event.get("tool_input"), dict) else {}
        )
        reason = clean_text(tool_input.get("description") or tool_input.get("command"))
        if reason:
            return f"Codex needs approval in {common_suffix(event)}. {tool} requested permission: {reason}"
        return f"Codex needs approval in {common_suffix(event)}. {tool} requested permission."

    if hook_event == "Stop":
        summary = clean_text(event.get("last_assistant_message"))
        if summary:
            return f"Codex stopped in {common_suffix(event)}. {summary}"
        return f"Codex stopped in {common_suffix(event)}."

    return ""


def claude_text(event: dict[str, Any]) -> str:
    hook_event = clean_text(event.get("hook_event_name"))

    if hook_event == "Notification":
        notification_type = clean_text(event.get("notification_type"))
        if notification_type in {
            "idle_prompt",
            "auth_success",
            "elicitation_complete",
            "elicitation_response",
        }:
            return ""
        message = clean_text(event.get("message") or event.get("title"))
        if notification_type == "permission_prompt":
            if message:
                return f"Claude needs approval in {common_suffix(event)}. {message}"
            return f"Claude needs approval in {common_suffix(event)}."
        if notification_type == "elicitation_dialog":
            if message:
                return f"Claude needs input in {common_suffix(event)}. {message}"
            return f"Claude needs input in {common_suffix(event)}."
        if message:
            return f"Claude needs attention in {common_suffix(event)}. {message}"
        return f"Claude needs attention in {common_suffix(event)}."

    if hook_event == "Stop":
        if event.get("stop_hook_active") is True:
            return ""
        summary = clean_text(event.get("last_assistant_message"))
        if summary:
            return f"Claude finished a turn in {common_suffix(event)}. {summary}"
        return f"Claude finished a turn in {common_suffix(event)}."

    if hook_event == "SubagentStop":
        if event.get("stop_hook_active") is True:
            return ""
        agent = (
            clean_text(event.get("agent_type") or event.get("agent_id")) or "subagent"
        )
        summary = clean_text(event.get("last_assistant_message"))
        if summary:
            return f"Claude {agent} finished in {common_suffix(event)}. {summary}"
        return f"Claude {agent} finished in {common_suffix(event)}."

    if hook_event == "StopFailure":
        failure = (
            clean_text(event.get("error") or event.get("error_type")) or "an API error"
        )
        details = clean_text(
            event.get("error_details") or event.get("last_assistant_message")
        )
        if details:
            return f"Claude hit {failure} in {common_suffix(event)}. {details}"
        return f"Claude hit {failure} in {common_suffix(event)}."

    return ""


def build_text(mode: str, event: dict[str, Any]) -> str:
    mode = mode.lower()
    if mode.startswith("codex"):
        return codex_text(event)
    if mode.startswith("claude"):
        return claude_text(event)

    return codex_text(event) or claude_text(event)


def json_rpc_message(
    message_id: int, method: str, params: dict[str, Any]
) -> dict[str, Any]:
    return {
        "jsonrpc": "2.0",
        "id": message_id,
        "method": method,
        "params": params,
    }


def normalize_tool(tool: str) -> str:
    normalized = tool.strip().lower().replace("-", "_")
    return TTS_TOOL_ALIASES.get(normalized, normalized)


def fallback_tools(tool: str) -> tuple[str, ...]:
    normalized = normalize_tool(tool)
    if normalized not in TTS_TOOL_CHAIN:
        return (normalized,)
    return TTS_TOOL_CHAIN[TTS_TOOL_CHAIN.index(normalized) :]


def tool_arguments(text: str, tool: str, rate: int) -> dict[str, Any]:
    arguments: dict[str, Any] = {"text": text}
    voice = MCP_TOOL_VOICES.get(tool)
    if voice:
        arguments["voice"] = voice
    if tool == "say_tts":
        arguments["rate"] = rate
    return arguments


def call_mcp_tts(text: str, tool: str, rate: int, no_play_dir: str | None) -> bool:
    mcp_tts = shutil.which("mcp-tts")
    if not mcp_tts:
        return False

    command = [mcp_tts, "--suppress-speaking-output"]
    if no_play_dir:
        command.extend(["--no-play", "--output-dir", no_play_dir])

    arguments = tool_arguments(text, tool, rate)

    messages = [
        json_rpc_message(
            1,
            "initialize",
            {
                "protocolVersion": MCP_PROTOCOL_VERSION,
                "capabilities": {},
                "clientInfo": {"name": "dotfiles-tts-hook", "version": "1.0.0"},
            },
        ),
        {"jsonrpc": "2.0", "method": "notifications/initialized"},
        json_rpc_message(2, "tools/call", {"name": tool, "arguments": arguments}),
    ]
    payload = "".join(
        json.dumps(message, separators=(",", ":")) + "\n" for message in messages
    )

    try:
        proc = subprocess.Popen(
            command,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except OSError:
        return False

    try:
        if proc.stdin is None or proc.stdout is None:
            return False
        for line in payload.splitlines():
            proc.stdin.write(line + "\n")
            proc.stdin.flush()

        deadline = time.monotonic() + MCP_RESPONSE_TIMEOUT_SECS
        while time.monotonic() < deadline:
            timeout = min(deadline - time.monotonic(), 0.5)
            ready, _, _ = select.select([proc.stdout], [], [], timeout)
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
            if "error" in response:
                return False
            result = response.get("result")
            return isinstance(result, dict) and result.get("isError") is not True
        return False
    except OSError:
        return False
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=PROCESS_SHUTDOWN_TIMEOUT_SECS)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=PROCESS_SHUTDOWN_TIMEOUT_SECS)


def fallback_say(text: str, rate: int) -> bool:
    say = shutil.which("say") or "/usr/bin/say"
    try:
        result = subprocess.run(
            [say, "-r", str(rate), text],
            check=False,
            timeout=SAY_TIMEOUT_SECS,
        )
    except (OSError, subprocess.TimeoutExpired):
        return False
    return result.returncode == 0


def speak(text: str, tool: str, rate: int, no_play_dir: str | None) -> int:
    text = clean_text(text)
    if not text:
        return 0

    lock_path = Path("/tmp/dotfiles-ai-tts-hook.lock")
    with lock_path.open("w", encoding="utf-8") as lock:
        locked = False
        if fcntl is not None:
            try:
                fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                return 0
            locked = True
        try:
            ok = False
            tried_direct_say = False
            for current_tool in fallback_tools(tool):
                if current_tool == "say_tts":
                    tried_direct_say = True
                    ok = no_play_dir is None and fallback_say(text, rate)
                else:
                    ok = call_mcp_tts(text, current_tool, rate, no_play_dir)
                if ok:
                    break
            if not ok and no_play_dir is None and not tried_direct_say:
                ok = fallback_say(text, rate)
        finally:
            if locked:
                fcntl.flock(lock.fileno(), fcntl.LOCK_UN)
    return 0 if ok else 1


def spawn_background(text: str, args: argparse.Namespace) -> int:
    command = [
        sys.executable,
        str(Path(__file__).resolve()),
        "--speak-text",
        text,
        "--tool",
        args.tool,
        "--rate",
        str(args.rate),
    ]
    if args.mcp_no_play_dir:
        command.extend(["--mcp-no-play-dir", args.mcp_no_play_dir])

    try:
        subprocess.Popen(
            command,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError:
        return 1
    return 0


def main() -> int:
    args = parse_args()
    text = (
        clean_text(args.speak_text)
        if args.speak_text
        else build_text(args.mode, load_event(args))
    )
    if not text:
        return 0
    if args.dry_run:
        print(text)
        return 0
    if args.background:
        return spawn_background(text, args)
    return speak(text, args.tool, args.rate, args.mcp_no_play_dir)


if __name__ == "__main__":
    raise SystemExit(main())
