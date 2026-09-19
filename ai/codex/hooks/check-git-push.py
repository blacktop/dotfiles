#!/usr/bin/env python3
"""Recognize ordinary shell Git invocations without executing command text.

This is a command guardrail, not an interpreter: dynamically constructed
commands and Git aliases still require sandboxing and approval controls.
"""

import os
import re
import shlex
import sys

VALUE_OPTIONS = {
    "-C",
    "-c",
    "--git-dir",
    "--work-tree",
    "--namespace",
    "--config-env",
    "--exec-path",
    "--attr-source",
    "--super-prefix",
}
FLAG_OPTIONS = {
    "--bare",
    "--no-pager",
    "--paginate",
    "-P",
    "-p",
    "--no-replace-objects",
    "--literal-pathspecs",
    "--glob-pathspecs",
    "--noglob-pathspecs",
    "--icase-pathspecs",
    "--no-optional-locks",
    "--no-lazy-fetch",
    "--no-advice",
}
ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")


def git_push(arguments: list[str]) -> bool:
    index = 0
    while index < len(arguments):
        word = arguments[index]
        if word == "--":
            return index + 1 < len(arguments) and arguments[index + 1] == "push"
        if word in VALUE_OPTIONS:
            index += 2
        elif (
            word in FLAG_OPTIONS
            or word.startswith(("-C", "-c"))
            and len(word) > 2
            or any(
                word.startswith(option + "=")
                for option in VALUE_OPTIONS
                if option.startswith("--")
            )
        ):
            index += 1
        else:
            return word == "push"
    return False


def invocation_push(words: list[str]) -> bool:
    index = 0
    while index < len(words):
        word = words[index]
        base = os.path.basename(word)
        if ASSIGNMENT.match(word) or word in {
            "!",
            "if",
            "then",
            "elif",
            "do",
            "while",
            "until",
        }:
            index += 1
        elif base in {"command", "exec"}:
            index += 1
            while index < len(words) and words[index] in {"--", "-p"}:
                index += 1
        elif base == "env":
            index += 1
            while index < len(words):
                option = words[index]
                if option in {"-u", "--unset", "-C", "--chdir"}:
                    index += 2
                elif (
                    option in {"-i", "--ignore-environment", "--"}
                    or option.startswith(("--unset=", "--chdir="))
                    or ASSIGNMENT.match(option)
                ):
                    index += 1
                else:
                    break
        elif base == "git":
            return git_push(words[index + 1 :])
        elif base in {"sh", "bash", "zsh", "fish"}:
            for offset, option in enumerate(words[index + 1 :], index + 1):
                if (
                    option.startswith("-")
                    and "c" in option[1:]
                    and offset + 1 < len(words)
                ):
                    return contains_push(words[offset + 1])
            return False
        else:
            return False
    return False


def contains_push(command: str) -> bool:
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()\n")
    lexer.whitespace = " \t\r"
    segment: list[str] = []
    for token in lexer:
        if token and all(char in ";&|()\n" for char in token):
            if invocation_push(segment):
                return True
            segment = []
        else:
            segment.append(token)
    return invocation_push(segment)


if __name__ == "__main__":
    try:
        blocked = contains_push(sys.argv[1])
    except (ValueError, RecursionError) as error:
        print(
            f"BLOCKED: unable to safely inspect shell command: {error}", file=sys.stderr
        )
        sys.exit(2)
    if blocked:
        print(
            "BLOCKED: Do not run git push from Codex; the user pushes manually.",
            file=sys.stderr,
        )
        sys.exit(2)
