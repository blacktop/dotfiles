#!/usr/bin/env python3
"""Recognize ordinary shell Git push invocations without executing command text.

This is a command guardrail, not an interpreter: commands built at run time by
another program (Python, make, a script file) still require sandboxing and
approval controls.
"""

import dataclasses
import os
import re
import shlex
import subprocess
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
KEYWORDS = {"!", "{", "}", "if", "then", "elif", "else", "do", "while", "until"}
SHELLS = {"sh", "bash", "zsh", "fish", "dash", "ksh"}
# Wrappers take their own options and operands before the real command, so any
# later Git invocation in the same segment is inspected.
WRAPPERS = {
    "sudo",
    "doas",
    "time",
    "nohup",
    "nice",
    "ionice",
    "timeout",
    "stdbuf",
    "caffeinate",
    "xargs",
    "watch",
}
PUNCTUATION = ";&|()\n`"
ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
SUBSTITUTION = re.compile(r"\$\(|`")
# A single-quoted span, a double-quoted span, or one escaped character.
QUOTED = re.compile(r"""'[^']*'|"(?:\\.|[^"\\])*"|\\.""", re.DOTALL)
MASKED_TICK = "\x01"
MASKED_DOLLAR = "\x02"
HEREDOC = re.compile(
    r"(?<!<)<<(?!<)-?\s*(?P<quote>['\"\\]?)(?P<tag>[A-Za-z_][A-Za-z0-9_]*)(?P=quote)?"
)


MAX_ALIAS_DEPTH = 10
# An alias whose body arrives through an environment variable cannot be read
# here, so it is treated as a push. No ordinary workflow defines one that way.
UNSEEN = "push"
ENV_ALIAS = re.compile(r"^GIT_CONFIG_KEY_\d+=alias\.(.+)$")


@dataclasses.dataclass(frozen=True)
class GitContext:
    """Where Git will look up aliases for one invocation."""

    cwd: str | None = None
    # Global options that select the repository, such as `-C dir`.
    locate: tuple[str, ...] = ()
    # Aliases defined on the command line with `-c alias.<name>=<body>`.
    inline: tuple[tuple[str, str], ...] = ()
    # Alias names already expanded, to stop cycles and runaway chains.
    seen: frozenset[str] = frozenset()

    def with_option(self, option: str, value: str) -> "GitContext":
        if option in {"-C", "--git-dir"}:
            located = (*self.locate, option, expand_path(value))
            return dataclasses.replace(self, locate=located)
        if option == "-c" and value.startswith("alias.") and "=" in value:
            key, _, body = value.partition("=")
            alias = (key.removeprefix("alias."), body)
            return dataclasses.replace(self, inline=(*self.inline, alias))
        if option == "--config-env" and value.startswith("alias."):
            name = value.partition("=")[0].removeprefix("alias.")
            return dataclasses.replace(self, inline=(*self.inline, (name, UNSEEN)))
        return self

    def alias_body(self, name: str) -> str:
        """Return the expansion of a Git alias, or an empty string."""
        inline = dict(self.inline)
        if name in inline:
            return inline[name]
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]*", name):
            return ""
        # The directory may not exist yet (`mkdir x && cd x`) or may not be a
        # repository. Global aliases still apply there, so look those up instead.
        for locate, cwd in ((self.locate, self.cwd), ((), None)):
            try:
                result = subprocess.run(
                    ["git", *locate, "config", "--get", f"alias.{name}"],
                    capture_output=True,
                    text=True,
                    timeout=2,
                    check=False,
                    cwd=cwd,
                )
            except (OSError, subprocess.SubprocessError):
                continue
            # 0 is found and 1 is not set; anything else means the lookup failed.
            if result.returncode in (0, 1):
                return result.stdout.strip()
        return ""


def expand_path(path: str) -> str:
    """Expand `~` and `$VAR` the way the shell would before Git sees the path."""
    return os.path.expanduser(os.path.expandvars(path))


def alias_pushes(name: str, context: GitContext) -> bool:
    """Follow an alias, and the aliases it names, until a push or a dead end."""
    if name in context.seen or len(context.seen) >= MAX_ALIAS_DEPTH:
        return False
    body = context.alias_body(name)
    if not body:
        return False
    if body.startswith("!"):
        return contains_push(body[1:], context.cwd)
    deeper = dataclasses.replace(context, seen=context.seen | {name})
    return git_push(shlex.split(body), deeper)


def split_option(arguments: list[str], index: int) -> tuple[str, str, int] | None:
    """Return (option, value, words used) for a global option, else None."""
    word = arguments[index]
    if word in VALUE_OPTIONS:
        return word, "".join(arguments[index + 1 : index + 2]), 2
    if word in FLAG_OPTIONS:
        return word, "", 1
    if word.startswith(("-C", "-c")) and len(word) > 2:
        return word[:2], word[2:], 1
    option, separator, value = word.partition("=")
    if separator and option in VALUE_OPTIONS:
        return option, value, 1
    return None


def git_push(arguments: list[str], context: GitContext) -> bool:
    index = 0
    while index < len(arguments):
        if arguments[index] == "--":
            index += 1
            break
        parsed = split_option(arguments, index)
        if parsed is None:
            break
        option, value, used = parsed
        context = context.with_option(option, value)
        index += used
    if index >= len(arguments):
        return False
    subcommand = arguments[index]
    return subcommand == "push" or alias_pushes(subcommand, context)


def skip_env_options(words: list[str], index: int) -> int:
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
    return index


def shell_script_push(words: list[str], index: int, cwd: str | None) -> bool:
    for offset in range(index + 1, len(words) - 1):
        option = words[offset]
        # A cluster such as -lc, but not a long option such as --norc.
        if re.fullmatch(r"-[A-Za-z]*c[A-Za-z]*", option):
            return contains_push(unmask(words[offset + 1]), cwd)
    return False


def skip_prefix(words: list[str], index: int) -> int:
    """Return the index after one command prefix, or `index` when there is none."""
    word = words[index]
    base = os.path.basename(word)
    if ASSIGNMENT.match(word) or word in KEYWORDS:
        return index + 1
    if base == "env":
        return skip_env_options(words, index + 1)
    if base in {"command", "exec", "builtin"}:
        index += 1
        while index < len(words) and words[index] in {"--", "-p"}:
            index += 1
    return index


def wrapped_push(words: list[str], cwd: str | None) -> bool:
    """Inspect whatever a wrapper such as `timeout 60` or `sudo -u x` runs."""
    runners = {"git", "eval", "env", "command", *SHELLS}
    return any(
        os.path.basename(word) in runners and invocation_push(words[position:], cwd)
        for position, word in enumerate(words)
    )


def changed_directory(words: list[str], cwd: str | None) -> str | None:
    """Return the directory later commands run in after `cd` or `pushd`."""
    words = words[command_start(words) :]
    if len(words) < 2 or words[0] not in {"cd", "pushd"} or words[1].startswith("-"):
        return cwd
    return os.path.join(cwd or os.getcwd(), expand_path(words[1]))


def command_start(words: list[str]) -> int:
    """Return the index of the command word, after assignments and prefixes."""
    index = 0
    while index < len(words):
        following = skip_prefix(words, index)
        if following == index:
            break
        index = following
    return index


def invocation_push(words: list[str], cwd: str | None) -> bool:
    index = command_start(words)
    if index >= len(words):
        return False
    base = os.path.basename(words[index])
    rest = words[index + 1 :]
    if base == "git":
        env_aliases = tuple(
            (match[1], UNSEEN)
            for word in words[:index]
            if (match := ENV_ALIAS.match(word))
        )
        return git_push(rest, GitContext(cwd, inline=env_aliases))
    if base == "eval":
        return contains_push(unmask(" ".join(rest)), cwd)
    if base in WRAPPERS:
        return wrapped_push(rest, cwd)
    if base in SHELLS:
        return shell_script_push(words, index, cwd)
    return False


def strip_heredocs(command: str) -> tuple[str, list[str]]:
    """Remove here-document bodies, returning the ones a shell would execute.

    A body is executable when it feeds a shell, or when its delimiter is unquoted
    and the shell therefore expands command substitutions inside it.
    """
    kept: list[str] = []
    executable: list[str] = []
    lines = command.split("\n")
    index = 0
    while index < len(lines):
        line = lines[index]
        kept.append(line)
        index += 1
        for match in HEREDOC.finditer(line):
            # `1 << n` in code looks the same; only a terminator line makes it a
            # here-document, otherwise the following lines are real commands.
            remaining = [text.strip("\t") for text in lines[index:]]
            if match["tag"] not in remaining:
                continue
            end = index + remaining.index(match["tag"])
            text = "\n".join(lines[index:end])
            index = end + 1
            feeds_shell = any(
                os.path.basename(word) in SHELLS
                for word in re.split(r"[\s;&|()]+", line[: match.start()])
            )
            if feeds_shell:
                executable.append(text)
            elif not match["quote"]:
                executable.extend(substitutions(text))
    return "\n".join(kept), executable


def substitutions(text: str) -> list[str]:
    """Return text that may run inside `$(...)` or backticks, flattened."""
    if not SUBSTITUTION.search(text):
        return []
    return [re.sub(r"\$\(|[`)]", " ; ", text)]


def mask_single_quoted(command: str) -> str:
    """Hide substitutions the shell will not run because they are single-quoted."""

    def mask(match: re.Match[str]) -> str:
        text = match[0]
        if not text.startswith("'"):
            return text
        return text.replace("`", MASKED_TICK).replace("$(", MASKED_DOLLAR + "(")

    return QUOTED.sub(mask, command)


def unmask(script: str) -> str:
    """Restore masked substitutions in text that a shell is about to run."""
    return script.replace(MASKED_TICK, "`").replace(MASKED_DOLLAR, "$")


def contains_push(command: str, cwd: str | None = None) -> bool:
    command, scripts = strip_heredocs(command)
    if any(contains_push(script, cwd) for script in scripts):
        return True
    command = mask_single_quoted(command)
    lexer = shlex.shlex(command, posix=True, punctuation_chars=PUNCTUATION)
    lexer.whitespace = " \t\r"
    segment: list[str] = []
    for token in lexer:
        if token and all(char in PUNCTUATION for char in token):
            if invocation_push(segment, cwd):
                return True
            cwd = changed_directory(segment, cwd)
            segment = []
            continue
        # Quoting is gone after lexing, so a quoted substitution is inspected too.
        if any(contains_push(inner, cwd) for inner in substitutions(token)):
            return True
        segment.append(token)
    return invocation_push(segment, cwd)


if __name__ == "__main__":
    try:
        # The optional second argument is the directory the command will run in.
        blocked = contains_push(sys.argv[1], "".join(sys.argv[2:3]) or None)
    except (ValueError, RecursionError) as error:
        print(
            f"BLOCKED: unable to safely inspect shell command: {error}", file=sys.stderr
        )
        sys.exit(2)
    if blocked:
        print(
            "BLOCKED: Do not run git push from the agent; the user pushes manually.",
            file=sys.stderr,
        )
        sys.exit(2)
