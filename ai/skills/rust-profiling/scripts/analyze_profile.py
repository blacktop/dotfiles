#!/usr/bin/env python3
"""
Samply Profile Analyzer

Analyzes Firefox Profiler JSON files (from samply) to identify performance bottlenecks.

Features:
  - Self time and total time analysis
  - Call tree visualization
  - Caller/callee relationships
  - Library breakdown
  - Rust symbol demangling
  - Filtering by library or threshold
  - JSON output for automation
  - Diff mode for comparing profiles

Usage:
  analyze_profile.py profile.json                    # Basic analysis
  analyze_profile.py profile.json --top 30           # Show top 30 functions
  analyze_profile.py profile.json --lib mylib        # Filter to specific library
  analyze_profile.py profile.json --callers main     # Show callers of 'main'
  analyze_profile.py profile.json --tree             # Show call tree
  analyze_profile.py profile.json --json             # Output as JSON
  analyze_profile.py before.json --diff after.json   # Compare two profiles
"""

import json
import sys
import argparse
import re
from pathlib import Path
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class FunctionStats:
    """Statistics for a single function."""
    name: str
    self_samples: int = 0
    total_samples: int = 0
    callers: dict = field(default_factory=lambda: defaultdict(int))
    callees: dict = field(default_factory=lambda: defaultdict(int))
    library: str = "unknown"


def demangle_rust(name: str) -> str:
    """Simplify Rust mangled names for readability."""
    if not name:
        return "unknown"

    # Remove hash suffixes like ::h1234abcd
    name = re.sub(r'::h[0-9a-f]{16}$', '', name)

    # Simplify common patterns
    name = name.replace('$LT$', '<').replace('$GT$', '>')
    name = name.replace('$u20$', ' ').replace('$u27$', "'")
    name = name.replace('$RF$', '&').replace('$BP$', '*')
    name = name.replace('$C$', ',').replace('$SP$', '@')

    # Shorten very long generic parameters
    if len(name) > 120:
        # Truncate long generic params but keep function name visible
        if '<' in name:
            base = name.split('<')[0]
            name = f"{base}<...>"

    return name


def shorten_name(name: str, max_len: int = 80) -> str:
    """Shorten function name for display."""
    if len(name) <= max_len:
        return name
    return name[:max_len-3] + "..."


class ProfileAnalyzer:
    """Analyzes samply/Firefox Profiler JSON files."""

    def __init__(self, data: dict):
        self.data = data
        self.libs_by_index, self.libs_by_addr = self._load_libs()
        self.threads = data.get('threads', [])
        self.functions: dict[str, FunctionStats] = {}
        self.total_samples = 0

    def _load_libs(self) -> tuple[list[tuple], list[tuple]]:
        """Load library address ranges and preserve original order for libIndex."""
        libs = self.data.get('libs', [])
        lib_ranges = []
        for lib in libs:
            name = lib.get('name') or lib.get('debugName') or Path(lib.get('path', '')).name or 'unknown'
            start = lib.get('start', 0)
            end = lib.get('end')
            lib_ranges.append((start, end, name))
        lib_ranges_by_addr = sorted(lib_ranges, key=lambda x: x[0])
        return lib_ranges, lib_ranges_by_addr

    def _addr_to_lib(self, addr: int) -> str:
        """Map address to library name."""
        for start, end, name in self.libs_by_addr:
            if start <= addr:
                if end is None or addr < end:
                    return name
        return "unknown"

    def _resolve_frame_name(self, thread: dict, frame_idx: int) -> tuple[str, str]:
        """Resolve frame index to (function_name, library)."""
        string_table = thread.get('stringArray', [])

        # Try native symbols first
        ns = thread.get('nativeSymbols', {})
        ns_names = ns.get('name', [])
        ns_libs = ns.get('libIndex', [])

        frame_table = thread.get('frameTable', {})
        frame_ns_indices = frame_table.get('nativeSymbol', [])
        frame_func_indices = frame_table.get('func', [])
        frame_addresses = frame_table.get('address', [])

        name = None
        lib = "unknown"

        # Try native symbol
        if frame_idx < len(frame_ns_indices):
            ns_idx = frame_ns_indices[frame_idx]
            if ns_idx is not None and ns_idx < len(ns_names):
                name_idx = ns_names[ns_idx]
                if isinstance(name_idx, int) and name_idx < len(string_table):
                    name = string_table[name_idx]
                if ns_idx < len(ns_libs):
                    lib_idx = ns_libs[ns_idx]
                    if lib_idx is not None and lib_idx < len(self.libs_by_index):
                        lib = self.libs_by_index[lib_idx][2]

        # Fallback to func table
        if not name:
            func_table = thread.get('funcTable', {})
            func_names = func_table.get('name', [])
            if frame_idx < len(frame_func_indices):
                func_idx = frame_func_indices[frame_idx]
                if func_idx is not None and func_idx < len(func_names):
                    name_idx = func_names[func_idx]
                    if isinstance(name_idx, int) and name_idx < len(string_table):
                        name = string_table[name_idx]

        # Fallback to address
        if not name and frame_idx < len(frame_addresses):
            addr = frame_addresses[frame_idx]
            if addr is not None:
                lib = self._addr_to_lib(addr)
                name = f"0x{addr:x}"

        return (demangle_rust(name) if name else "unknown", lib)

    def analyze(self, thread_filter: Optional[str] = None):
        """Analyze all threads (or filtered thread)."""
        for thread in self.threads:
            thread_name = thread.get('name', 'Unknown')
            if thread_filter and thread_filter.lower() not in thread_name.lower():
                continue
            self._analyze_thread(thread)

    def _analyze_thread(self, thread: dict):
        """Analyze a single thread."""
        samples = thread.get('samples', {})
        stack_indices = samples.get('stack', [])

        stack_table = thread.get('stackTable', {})
        stack_frames = stack_table.get('frame', [])
        stack_prefixes = stack_table.get('prefix', [])

        for stack_idx in stack_indices:
            if stack_idx is None:
                continue

            self.total_samples += 1

            # Walk the stack
            seen_in_stack = set()
            prev_name = None
            current_idx = stack_idx
            is_leaf = True

            while current_idx is not None and current_idx < len(stack_frames):
                frame_idx = stack_frames[current_idx]
                name, lib = self._resolve_frame_name(thread, frame_idx)

                # Get or create function stats
                if name not in self.functions:
                    self.functions[name] = FunctionStats(name=name, library=lib)
                stats = self.functions[name]

                # Self time (leaf frame only)
                if is_leaf:
                    stats.self_samples += 1
                    is_leaf = False

                # Total time (count once per stack)
                if name not in seen_in_stack:
                    stats.total_samples += 1
                    seen_in_stack.add(name)

                # Track caller/callee relationships
                if prev_name and prev_name != name:
                    stats.callees[prev_name] += 1
                    if prev_name in self.functions:
                        self.functions[prev_name].callers[name] += 1

                prev_name = name

                # Move to parent frame
                if current_idx < len(stack_prefixes):
                    current_idx = stack_prefixes[current_idx]
                else:
                    break

    def get_hot_functions(self, by: str = "self", top_n: int = 20,
                          lib_filter: Optional[str] = None,
                          min_pct: float = 0.0) -> list[FunctionStats]:
        """Get hottest functions sorted by self or total time."""
        funcs = list(self.functions.values())

        # Filter by library
        if lib_filter:
            funcs = [f for f in funcs if lib_filter.lower() in f.library.lower()]

        # Filter by minimum percentage
        if min_pct > 0 and self.total_samples > 0:
            threshold = self.total_samples * (min_pct / 100.0)
            key = 'self_samples' if by == 'self' else 'total_samples'
            funcs = [f for f in funcs if getattr(f, key) >= threshold]

        # Sort
        if by == "self":
            funcs.sort(key=lambda f: f.self_samples, reverse=True)
        else:
            funcs.sort(key=lambda f: f.total_samples, reverse=True)

        return funcs[:top_n]

    def get_library_breakdown(self) -> dict[str, dict]:
        """Get samples grouped by library."""
        libs = defaultdict(lambda: {"self": 0, "total": 0, "functions": 0})
        for func in self.functions.values():
            libs[func.library]["self"] += func.self_samples
            libs[func.library]["total"] += func.total_samples
            libs[func.library]["functions"] += 1
        return dict(sorted(libs.items(), key=lambda x: x[1]["self"], reverse=True))

    def get_callers(self, func_name: str, top_n: int = 10) -> list[tuple[str, int]]:
        """Get top callers of a function."""
        for name, stats in self.functions.items():
            if func_name.lower() in name.lower():
                callers = sorted(stats.callers.items(), key=lambda x: x[1], reverse=True)
                return callers[:top_n]
        return []

    def get_callees(self, func_name: str, top_n: int = 10) -> list[tuple[str, int]]:
        """Get top callees of a function."""
        for name, stats in self.functions.items():
            if func_name.lower() in name.lower():
                callees = sorted(stats.callees.items(), key=lambda x: x[1], reverse=True)
                return callees[:top_n]
        return []

    def print_summary(self, top_n: int = 20, lib_filter: Optional[str] = None):
        """Print analysis summary."""
        print(f"\n{'='*70}")
        print(f"PROFILE SUMMARY")
        print(f"{'='*70}")
        print(f"Total samples: {self.total_samples:,}")
        print(f"Unique functions: {len(self.functions):,}")
        print(f"Libraries: {len(self.libs_by_index)}")

        # Library breakdown
        print(f"\n{'='*70}")
        print(f"LIBRARY BREAKDOWN (by self time)")
        print(f"{'='*70}")
        print(f"{'Library':<40} {'Self %':>10} {'Total %':>10} {'Funcs':>8}")
        print(f"{'-'*70}")

        libs = self.get_library_breakdown()
        for lib, stats in list(libs.items())[:10]:
            self_pct = (stats['self'] / self.total_samples * 100) if self.total_samples else 0
            total_pct = (stats['total'] / self.total_samples * 100) if self.total_samples else 0
            print(f"{shorten_name(lib, 40):<40} {self_pct:>9.1f}% {total_pct:>9.1f}% {stats['functions']:>8}")

        # Hot functions by self time
        print(f"\n{'='*70}")
        print(f"HOT FUNCTIONS (by self time){' - filtered: ' + lib_filter if lib_filter else ''}")
        print(f"{'='*70}")
        print(f"{'Samples':>8} {'Self%':>7} {'Total%':>7}  {'Function'}")
        print(f"{'-'*70}")

        hot = self.get_hot_functions(by="self", top_n=top_n, lib_filter=lib_filter)
        for func in hot:
            self_pct = (func.self_samples / self.total_samples * 100) if self.total_samples else 0
            total_pct = (func.total_samples / self.total_samples * 100) if self.total_samples else 0
            print(f"{func.self_samples:>8} {self_pct:>6.1f}% {total_pct:>6.1f}%  {shorten_name(func.name)}")

    def print_callers(self, func_name: str):
        """Print callers of a function."""
        callers = self.get_callers(func_name)
        if not callers:
            print(f"No function matching '{func_name}' found.")
            return

        print(f"\n{'='*70}")
        print(f"CALLERS OF: {func_name}")
        print(f"{'='*70}")
        for caller, count in callers:
            pct = (count / self.total_samples * 100) if self.total_samples else 0
            print(f"{count:>8} ({pct:>5.1f}%)  {shorten_name(caller)}")

    def print_callees(self, func_name: str):
        """Print callees of a function."""
        callees = self.get_callees(func_name)
        if not callees:
            print(f"No function matching '{func_name}' found.")
            return

        print(f"\n{'='*70}")
        print(f"CALLEES OF: {func_name}")
        print(f"{'='*70}")
        for callee, count in callees:
            pct = (count / self.total_samples * 100) if self.total_samples else 0
            print(f"{count:>8} ({pct:>5.1f}%)  {shorten_name(callee)}")

    def print_call_tree(self, max_depth: int = 5, min_pct: float = 1.0):
        """Print a simplified call tree from hot roots."""
        print(f"\n{'='*70}")
        print(f"CALL TREE (min {min_pct}% of samples, depth {max_depth})")
        print(f"{'='*70}")

        threshold = self.total_samples * (min_pct / 100.0)

        # Find root functions (high total time, few/no callers)
        roots = []
        for func in self.functions.values():
            if func.total_samples >= threshold:
                caller_samples = sum(func.callers.values())
                if caller_samples < func.total_samples * 0.5:  # Less than 50% from tracked callers
                    roots.append(func)

        roots.sort(key=lambda f: f.total_samples, reverse=True)

        def print_tree(func: FunctionStats, depth: int, prefix: str):
            if depth > max_depth:
                return
            pct = (func.total_samples / self.total_samples * 100) if self.total_samples else 0
            self_pct = (func.self_samples / self.total_samples * 100) if self.total_samples else 0

            marker = "└── " if depth > 0 else ""
            print(f"{prefix}{marker}{pct:>5.1f}% ({self_pct:>4.1f}% self) {shorten_name(func.name, 50)}")

            # Print significant callees
            callees = sorted(func.callees.items(), key=lambda x: x[1], reverse=True)
            child_prefix = prefix + ("    " if depth > 0 else "")
            for callee_name, count in callees[:3]:
                if count >= threshold and callee_name in self.functions:
                    print_tree(self.functions[callee_name], depth + 1, child_prefix)

        for root in roots[:5]:
            print_tree(root, 0, "")
            print()

    def to_json(self) -> dict:
        """Export analysis as JSON."""
        return {
            "total_samples": self.total_samples,
            "libraries": self.get_library_breakdown(),
            "functions": [
                {
                    "name": f.name,
                    "library": f.library,
                    "self_samples": f.self_samples,
                    "total_samples": f.total_samples,
                    "self_pct": round(f.self_samples / self.total_samples * 100, 2) if self.total_samples else 0,
                    "total_pct": round(f.total_samples / self.total_samples * 100, 2) if self.total_samples else 0,
                }
                for f in sorted(self.functions.values(), key=lambda x: x.self_samples, reverse=True)[:100]
            ]
        }


def compare_profiles(before: ProfileAnalyzer, after: ProfileAnalyzer, top_n: int = 20):
    """Compare two profiles and show differences."""
    print(f"\n{'='*70}")
    print(f"PROFILE COMPARISON")
    print(f"{'='*70}")
    print(f"Before: {before.total_samples:,} samples")
    print(f"After:  {after.total_samples:,} samples")

    # Normalize to percentages for comparison
    def get_pct(analyzer: ProfileAnalyzer) -> dict[str, float]:
        total = analyzer.total_samples or 1
        return {name: (f.self_samples / total * 100) for name, f in analyzer.functions.items()}

    before_pct = get_pct(before)
    after_pct = get_pct(after)

    all_funcs = set(before_pct.keys()) | set(after_pct.keys())

    diffs = []
    for name in all_funcs:
        b = before_pct.get(name, 0)
        a = after_pct.get(name, 0)
        diff = a - b
        if abs(diff) >= 0.1:  # At least 0.1% change
            diffs.append((name, b, a, diff))

    # Sort by absolute diff
    diffs.sort(key=lambda x: abs(x[3]), reverse=True)

    print(f"\n{'='*70}")
    print(f"BIGGEST CHANGES (by self time %)")
    print(f"{'='*70}")
    print(f"{'Before%':>8} {'After%':>8} {'Diff':>8}  {'Function'}")
    print(f"{'-'*70}")

    for name, b, a, diff in diffs[:top_n]:
        sign = "+" if diff > 0 else ""
        color = ""
        print(f"{b:>7.1f}% {a:>7.1f}% {sign}{diff:>7.1f}%  {shorten_name(name, 50)}")

    # Summary
    improved = sum(1 for _, _, _, d in diffs if d < -0.5)
    regressed = sum(1 for _, _, _, d in diffs if d > 0.5)
    print(f"\nSummary: {improved} functions improved, {regressed} regressed (>0.5% change)")


def main():
    parser = argparse.ArgumentParser(
        description="Analyze Samply/Firefox Profiler JSON files",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument("profile", help="Path to profile.json")
    parser.add_argument("--top", "-n", type=int, default=20, help="Number of top functions to show")
    parser.add_argument("--lib", "-l", help="Filter to functions in this library")
    parser.add_argument("--thread", "-t", help="Filter to thread name containing this string")
    parser.add_argument("--callers", "-c", help="Show callers of function matching this name")
    parser.add_argument("--callees", help="Show callees of function matching this name")
    parser.add_argument("--tree", action="store_true", help="Show call tree")
    parser.add_argument("--tree-depth", type=int, default=5, help="Max call tree depth")
    parser.add_argument("--min-pct", type=float, default=1.0, help="Minimum percentage for tree/filtering")
    parser.add_argument("--json", "-j", action="store_true", help="Output as JSON")
    parser.add_argument("--diff", "-d", help="Compare against another profile")

    args = parser.parse_args()

    # Load profile
    path = Path(args.profile)
    if not path.exists():
        print(f"Error: File not found: {path}", file=sys.stderr)
        sys.exit(1)

    print(f"Loading {path}...", file=sys.stderr)
    with open(path) as f:
        data = json.load(f)

    analyzer = ProfileAnalyzer(data)
    analyzer.analyze(thread_filter=args.thread)

    # Handle diff mode
    if args.diff:
        diff_path = Path(args.diff)
        if not diff_path.exists():
            print(f"Error: Diff file not found: {diff_path}", file=sys.stderr)
            sys.exit(1)

        print(f"Loading {diff_path}...", file=sys.stderr)
        with open(diff_path) as f:
            diff_data = json.load(f)

        diff_analyzer = ProfileAnalyzer(diff_data)
        diff_analyzer.analyze(thread_filter=args.thread)
        compare_profiles(analyzer, diff_analyzer, top_n=args.top)
        return

    # JSON output
    if args.json:
        print(json.dumps(analyzer.to_json(), indent=2))
        return

    # Callers/callees
    if args.callers:
        analyzer.print_callers(args.callers)
        return

    if args.callees:
        analyzer.print_callees(args.callees)
        return

    # Call tree
    if args.tree:
        analyzer.print_call_tree(max_depth=args.tree_depth, min_pct=args.min_pct)
        return

    # Default: summary
    analyzer.print_summary(top_n=args.top, lib_filter=args.lib)


if __name__ == "__main__":
    main()
