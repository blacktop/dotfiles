#!/usr/bin/env python3
"""Claude PreToolUse Bash hook: keep every trash call standalone.

Claude's sandbox does not make ~/.Trash writable, so trash works only when the
whole Bash call matches sandbox.excludedCommands ("trash *"). A call that adds
another command, a redirect, a cd or a substitution stays sandboxed and trash
fails, which pushes agents toward rm. The unsandboxed call also sees a
different TMPDIR, so $TMPDIR paths name the wrong directory.
"""

from __future__ import annotations

import json
import re
import shlex
import sys

TRASH = {"trash", "/usr/bin/trash"}
LAUNCHERS = {
    "xargs",
    "-exec",
    "-execdir",
    "-ok",
    "-okdir",
    "env",
    "exec",
    "nice",
    "nohup",
    "time",
}
SHELLS = {"sh", "bash", "zsh", "fish", "/bin/sh", "/bin/bash", "/bin/zsh"}
ASSIGNMENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*=")
SEPARATOR_CHARS = set(";&|()")
REDIRECT_CHARS = set("<>")

CHAINED = (
    "BLOCKED: run trash as its own Bash call, e.g. `trash /absolute/path1 /absolute/path2`. "
    "Only a call that is exactly one trash command, with no other command, cd, pipe, "
    "redirect or $(...), runs outside the sandbox; otherwise ~/.Trash is not writable and "
    "trash fails. Never fall back to rm."
)
TMPDIR = (
    "BLOCKED: give trash the literal absolute path instead of $TMPDIR. trash runs outside "
    "the sandbox, where TMPDIR names a different directory."
)


def words(command: str) -> list[str]:
    """Split a shell command into words and operator tokens.

    Newlines and backticks become separators so each line or substitution is
    examined as its own command.
    """
    text = command.replace("\n", " ; ").replace("`", " ; ")
    lexer = shlex.shlex(text, posix=True, punctuation_chars=";&|()<>")
    lexer.whitespace_split = True
    lexer.commenters = ""
    return list(lexer)


def segments(tokens: list[str]) -> list[list[str]]:
    parts: list[list[str]] = [[]]
    for token in tokens:
        if set(token) <= SEPARATOR_CHARS:
            parts.append([])
        else:
            parts[-1].append(token)
    return parts


def invokes_trash(segment: list[str]) -> bool:
    start = 0
    while start < len(segment) and ASSIGNMENT.match(segment[start]):
        start += 1
    for position in range(start, len(segment)):
        if segment[position] not in TRASH:
            continue
        if position == start or LAUNCHERS.intersection(segment[start:position]):
            return True
    if start < len(segment) and segment[start] in SHELLS and "-c" in segment:
        script = segment.index("-c") + 1
        return script < len(segment) and text_invokes_trash(segment[script])
    return False


def text_invokes_trash(text: str) -> bool:
    try:
        return any(invokes_trash(part) for part in segments(words(text)))
    except ValueError:
        return False


def check(command: str) -> str | None:
    """Return the block message for a command, or None to allow it."""
    try:
        parts = segments(words(command))
    except ValueError:
        # Unbalanced quoting: the shell rejects this command before trash can run.
        return None
    if not any(invokes_trash(part) for part in parts):
        return None
    only = parts[0]
    standalone = (
        len(parts) == 1
        and only[0] in TRASH
        and not any(set(token) <= REDIRECT_CHARS for token in only)
    )
    if not standalone:
        return CHAINED
    if any("TMPDIR" in token for token in only):
        return TMPDIR
    return None


def main() -> int:
    payload = json.load(sys.stdin)
    message = check(payload.get("tool_input", {}).get("command") or "")
    if message is None:
        return 0
    print(message, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
