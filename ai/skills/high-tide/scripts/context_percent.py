#!/usr/bin/env python3
"""Normalize measured context usage into a used percentage.

The helper accepts Claude status-line JSON, rendered status text, or Codex
`/status` snippets. It intentionally does not read environment variables or
infer usage from transcript length.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from dataclasses import dataclass
from pathlib import Path


ANSI_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
NUMBER_RE = r"([0-9]+(?:\.[0-9]+)?)"

USED_KEYS = {
    "used_percentage",
    "used_percent",
    "percent_used",
    "usage_percentage",
    "usage_percent",
}

REMAINING_KEYS = {
    "remaining_percentage",
    "remaining_percent",
    "free_percentage",
    "free_percent",
    "available_percentage",
    "available_percent",
}

USED_TOKEN_KEYS = ("used_tokens", "used", "input_tokens")
REMAINING_TOKEN_KEYS = ("remaining_tokens", "remaining", "available_tokens")
TOTAL_TOKEN_KEYS = (
    "total_tokens",
    "total",
    "limit",
    "max_tokens",
    "window_tokens",
    "context_window",
)


@dataclass(frozen=True)
class Result:
    used_percentage: float
    source: str
    input_kind: str
    note: str = ""


def pct(value: object) -> float | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        number = float(value)
    elif isinstance(value, str):
        match = re.search(NUMBER_RE, value.replace(",", ""))
        if not match:
            return None
        number = float(match.group(1))
    else:
        return None

    if not math.isfinite(number) or number < 0.0 or number > 100.0:
        return None
    return number


def token_count(value: object) -> float | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        number = float(value)
    elif isinstance(value, str):
        match = re.fullmatch(r"\s*([0-9]+(?:\.[0-9]+)?)\s*", value.replace(",", ""))
        if not match:
            return None
        number = float(match.group(1))
    else:
        return None

    if not math.isfinite(number) or number < 0.0:
        return None
    return number


def format_pct(value: float) -> str:
    if value.is_integer():
        return str(int(value))
    return f"{value:.2f}".rstrip("0").rstrip(".")


def path_get(value: object, path: tuple[str, ...]) -> object | None:
    current = value
    for part in path:
        if not isinstance(current, dict) or part not in current:
            return None
        current = current[part]
    return current


def path_label(path: tuple[str, ...]) -> str:
    return ".".join(path)


def walk_json(value: object, path: tuple[str, ...] = ()) -> list[tuple[tuple[str, ...], object]]:
    out: list[tuple[tuple[str, ...], object]] = []
    if isinstance(value, dict):
        for key, child in value.items():
            if isinstance(key, str):
                child_path = (*path, key)
                out.append((child_path, child))
                out.extend(walk_json(child, child_path))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            child_path = (*path, str(index))
            out.append((child_path, child))
            out.extend(walk_json(child, child_path))
    return out


def is_context_path(path: tuple[str, ...]) -> bool:
    lowered = ".".join(part.lower() for part in path)
    return "context" in lowered or lowered.endswith(".tokens") or ".tokens." in lowered


def object_number(mapping: dict[object, object], names: tuple[str, ...]) -> tuple[str, float] | None:
    for name in names:
        if name in mapping:
            number = token_count(mapping[name])
            if number is not None:
                return name, number
    return None


def compute_from_tokens(mapping: dict[object, object], base_path: tuple[str, ...]) -> Result | None:
    used = object_number(mapping, USED_TOKEN_KEYS)
    remaining = object_number(mapping, REMAINING_TOKEN_KEYS)
    total = object_number(mapping, TOTAL_TOKEN_KEYS)

    if used and total and total[1] > 0:
        return Result(
            used_percentage=(used[1] / total[1]) * 100.0,
            source=f"{path_label(base_path)}.{used[0]}/{total[0]}",
            input_kind="json",
        )

    if remaining and total and total[1] > 0:
        return Result(
            used_percentage=100.0 - ((remaining[1] / total[1]) * 100.0),
            source=f"{path_label(base_path)}.{remaining[0]}/{total[0]}",
            input_kind="json",
            note="computed from remaining tokens",
        )

    return None


def extract_json(value: object, mode: str) -> Result | None:
    explicit_used_paths = (
        ("context_window", "used_percentage"),
        ("context_window", "used_percent"),
        ("context", "used_percentage"),
        ("context", "used_percent"),
    )
    explicit_remaining_paths = (
        ("context_window", "remaining_percentage"),
        ("context_window", "remaining_percent"),
        ("context", "remaining_percentage"),
        ("context", "remaining_percent"),
    )

    if mode in ("auto", "used"):
        for path in explicit_used_paths:
            number = pct(path_get(value, path))
            if number is not None:
                return Result(number, path_label(path), "json")

    if mode in ("auto", "remaining"):
        for path in explicit_remaining_paths:
            number = pct(path_get(value, path))
            if number is not None:
                return Result(100.0 - number, path_label(path), "json", "converted from remaining")

    if isinstance(value, dict):
        context_window = path_get(value, ("context_window",))
        if isinstance(context_window, dict):
            result = compute_from_tokens(context_window, ("context_window",))
            if result:
                return result

    for path, child in walk_json(value):
        key = path[-1].lower() if path else ""
        if mode in ("auto", "used") and key in USED_KEYS and is_context_path(path):
            number = pct(child)
            if number is not None:
                return Result(number, path_label(path), "json")
        if mode in ("auto", "remaining") and key in REMAINING_KEYS and is_context_path(path):
            number = pct(child)
            if number is not None:
                return Result(100.0 - number, path_label(path), "json", "converted from remaining")
        if isinstance(child, dict) and is_context_path(path):
            result = compute_from_tokens(child, path)
            if result:
                return result

    return None


def text_candidates(text: str, mode: str) -> list[Result]:
    cleaned = ANSI_RE.sub("", text)
    candidates: list[Result] = []

    if mode in ("auto", "used"):
        used_patterns = (
            (rf"\bctx\s*:\s*{NUMBER_RE}\s*%", "ctx:<pct>%"),
            (rf"\bcontext(?:\s+window)?\s*(?:used|usage)\s*[:=]?\s*{NUMBER_RE}\s*%", "context used"),
            (rf"\bcontext(?:\s+window)?\s*[:=]\s*{NUMBER_RE}\s*%\s*(?:used|usage)\b", "context pct used"),
            (rf"\b(?:used|usage)\s+context(?:\s+window)?\s*[:=]?\s*{NUMBER_RE}\s*%", "used context"),
            (rf"\b{NUMBER_RE}\s*%\s*(?:context\s*)?(?:used|usage)\b", "pct context used"),
        )
        for pattern, source in used_patterns:
            for match in re.finditer(pattern, cleaned, flags=re.IGNORECASE):
                number = pct(match.group(1))
                if number is not None:
                    candidates.append(Result(number, source, "text"))

    if mode in ("auto", "remaining"):
        remaining_patterns = (
            (
                rf"\bcontext(?:\s+window|\s+capacity)?\s*(?:remaining|left|free|available)\s*[:=]?\s*{NUMBER_RE}\s*%",
                "context remaining",
            ),
            (
                rf"\bcontext(?:\s+window|\s+capacity)?\s*[:=]\s*{NUMBER_RE}\s*%\s*(?:remaining|left|free|available)\b",
                "context pct remaining",
            ),
            (
                rf"\b(?:remaining|left|free|available)\s+context(?:\s+window|\s+capacity)?\s*[:=]?\s*{NUMBER_RE}\s*%",
                "remaining context",
            ),
            (
                rf"\b{NUMBER_RE}\s*%\s*(?:context\s*)?(?:remaining|left|free|available)\b",
                "pct context remaining",
            ),
        )
        for pattern, source in remaining_patterns:
            for match in re.finditer(pattern, cleaned, flags=re.IGNORECASE):
                number = pct(match.group(1))
                if number is not None:
                    candidates.append(Result(100.0 - number, source, "text", "converted from remaining"))

    stripped = cleaned.strip()
    if mode in ("used", "remaining") and re.fullmatch(rf"{NUMBER_RE}\s*%?", stripped):
        number = pct(stripped)
        if number is not None:
            if mode == "used":
                candidates.append(Result(number, "explicit --mode used", "text"))
            else:
                candidates.append(
                    Result(100.0 - number, "explicit --mode remaining", "text", "converted from remaining")
                )

    return candidates


def extract_text(text: str, mode: str) -> Result | None:
    candidates = text_candidates(text, mode)
    if not candidates:
        return None

    first = candidates[0]
    for candidate in candidates[1:]:
        if abs(candidate.used_percentage - first.used_percentage) > 0.5:
            raise ValueError(
                "conflicting context percentages: "
                f"{format_pct(first.used_percentage)} from {first.source}, "
                f"{format_pct(candidate.used_percentage)} from {candidate.source}"
            )
    return first


def extract_payload(text: str, mode: str) -> Result | None:
    stripped = text.strip()
    if not stripped:
        return None

    try:
        decoded = json.loads(stripped)
    except json.JSONDecodeError:
        decoded = None

    if decoded is not None:
        result = extract_json(decoded, mode)
        if result:
            return result

    return extract_text(stripped, mode)


def load_sources(args: argparse.Namespace) -> list[tuple[str, str]]:
    sources: list[tuple[str, str]] = []

    for raw_path in args.file or []:
        path = Path(raw_path)
        try:
            sources.append((str(path), path.read_text(encoding="utf-8")))
        except OSError as exc:
            raise SystemExit(f"error: failed to read {path}: {exc}") from exc

    if args.input:
        sources.append(("argv", " ".join(args.input)))
    elif not sys.stdin.isatty():
        sources.append(("stdin", sys.stdin.read()))

    return sources


def emit(result: Result, args: argparse.Namespace) -> None:
    threshold = args.threshold
    if args.json:
        print(
            json.dumps(
                {
                    "measured": True,
                    "used_percentage": round(result.used_percentage, 4),
                    "source": result.source,
                    "input_kind": result.input_kind,
                    "note": result.note,
                    "threshold": threshold,
                    "trigger_gt_threshold": result.used_percentage > threshold,
                },
                sort_keys=True,
            )
        )
    elif args.value_only:
        print(format_pct(result.used_percentage))
    else:
        trigger = "trigger" if result.used_percentage > threshold else "no trigger"
        print(
            f"{format_pct(result.used_percentage)}% used "
            f"({trigger}; source: {result.source}; input: {result.input_kind})"
        )


def run_self_test() -> None:
    cases = (
        ('{"context_window":{"used_percentage":96.2}}', "auto", 96.2),
        ('{"context_window":{"remaining_percentage":4}}', "auto", 96.0),
        ('{"context_window":{"used_tokens":950,"total_tokens":1000}}', "auto", 95.0),
        ("ctx:87%", "auto", 87.0),
        ("Context: 13% remaining", "auto", 87.0),
        ("remaining context 13%", "auto", 87.0),
        ("42", "used", 42.0),
        ("42", "remaining", 58.0),
    )

    for payload, mode, expected in cases:
        result = extract_payload(payload, mode)
        if result is None:
            raise SystemExit(f"self-test failed: no result for {payload!r}")
        if abs(result.used_percentage - expected) > 0.01:
            raise SystemExit(
                f"self-test failed: {payload!r} expected {expected}, got {result.used_percentage}"
            )

    negative_cases = (
        ('{"rate_limits":{"five_hour":{"used_percentage":99}}}', "auto"),
        ("42", "auto"),
        ("lots of tool calls today", "auto"),
    )
    for payload, mode in negative_cases:
        result = extract_payload(payload, mode)
        if result is not None:
            raise SystemExit(f"self-test failed: unexpected result for {payload!r}: {result}")

    print("self-test passed")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract measured context used percentage from status-line JSON or status text."
    )
    parser.add_argument("input", nargs="*", help="Literal status text to parse. Omit to read stdin.")
    parser.add_argument("-f", "--file", action="append", help="Read a status payload or status text file.")
    parser.add_argument(
        "--mode",
        choices=("auto", "used", "remaining"),
        default="auto",
        help="Interpret a bare numeric value as used or remaining. Auto refuses bare numbers.",
    )
    parser.add_argument("--json", action="store_true", help="Emit machine-readable JSON.")
    parser.add_argument("--value-only", action="store_true", help="Print only the used percentage value.")
    parser.add_argument("--threshold", type=float, default=98.0, help="Trigger threshold for output metadata.")
    parser.add_argument("--self-test", action="store_true", help="Run built-in parser checks.")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    if args.self_test:
        run_self_test()
        return 0

    sources = load_sources(args)
    if not sources:
        print("no measured context input provided", file=sys.stderr)
        return 1

    try:
        for origin, text in sources:
            result = extract_payload(text, args.mode)
            if result:
                result = Result(
                    used_percentage=result.used_percentage,
                    source=f"{origin}:{result.source}",
                    input_kind=result.input_kind,
                    note=result.note,
                )
                emit(result, args)
                return 0
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.json:
        print(json.dumps({"measured": False, "error": "no measured context percentage found"}))
    else:
        print("no measured context percentage found", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
