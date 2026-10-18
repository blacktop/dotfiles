---
name: apple-perf
description: |
  Diagnose and improve runtime performance of native Apple apps and tools using measured evidence.
  Use for Instruments trace analysis, Time Profiler or CPU Profiler hotspots, Top Functions and
  flame graphs, hangs and hitches, and before/after performance comparisons. For recording or
  exporting a trace without diagnosing a bottleneck, use instruments-profiling.
---

# Apple Performance

Turn a reproducible performance problem into an attributed cost, a focused fix,
and a repeatable measurement. Start from the user's trace or reproduction; do not
replace a requested analysis with an unsolicited profiling run.

## Establish the measurement

Identify the slow operation and its useful metric: elapsed time, CPU time or
cycles, throughput, hang duration, or missed frame deadlines. Record the build,
workload, device/OS, and selected time range. Use the project's optimized profiling
configuration with matching symbols; Debug timings can misrepresent shipping
behavior. Keep a correctness check for the work the benchmark performs.

For a new recording, use [instruments-profiling](../instruments-profiling/SKILL.md)
to select the actual executable, limit capture duration, and export or symbolicate
the trace. Discover templates with the selected Xcode's `xcrun xctrace list
templates`. A named `OSSignposter` interval helps isolate a repeatable operation.
Retain the original trace and matching build artifacts. If capture needs a device,
process, or permission outside the authorized scope, report that specific blocker.

Choose the instrument from what the trace shows:

| Observation | Next investigation |
| --- | --- |
| The affected thread is busy on CPU | Time Profiler or available CPU Profiler; inspect Top Functions and callers. |
| The app is unresponsive while the affected thread is off CPU | Hangs, System Trace, or Swift Concurrency; examine blocking, runnable delay, locks, I/O, and actor/task scheduling. |
| View updates or rendering dominate | Use the SwiftUI instrument and `swiftui-performance-audit` for view-level evidence. |
| Memory, GPU, or energy is the actual problem | Select the corresponding instrument; a CPU ranking alone cannot establish that cause. |

Do not infer a blocked thread from whole-process CPU alone. Inspect the affected
thread during the problem interval. When symbols, workload coverage, or samples
are insufficient, state the missing evidence before proposing an optimization.

## Find CPU hotspots with Top Functions

Top Functions is available in Instruments starting with Xcode 26.4. In a
supported call-tree detail view, select the **Top Functions** segment and focus
the time range on the slow operation. Keep the same process, thread, and call-tree
filters when comparing views or runs.

- Start with **Self Weight** in Time Profiler or **Self Cycles** in CPU Profiler.
  Self cost is charged to the function itself; inclusive cost also covers its
  callees. Samples and cycle weights are not invocation counts or elapsed time.
- Top Functions combines a symbol's cost across callers. This exposes small
  repeated operations whose aggregate cost is easy to miss in an ordinary tree.
  Select a row to inspect its callers in the adjacent flame graph, then switch
  toward callees when the inclusive cost needs explanation. Toggle labels depend
  on whether the tree is inverted.
- Follow expensive runtime, allocation, or framework symbols back to code the
  project controls before hiding system libraries. Use the selected stack and
  source view to identify the responsible call site. A wide flame-graph block
  represents aggregate weight; horizontal position is not chronological order.
- Separate the measured observation from the proposed mechanism. Prefer removing
  redundant work, reducing frequency, or fixing an algorithm before adding
  concurrency, caches, or low-level tuning.

For offline analysis, inspect `xcrun xctrace export --toc` with the actual trace
path before choosing an export schema. Preserve process, image, symbol, metric,
and time-range identity when aggregating data. Do not promise that a raw export
reproduces Instruments' Top Functions view unless its weighting and filters match.

## Change and verify

Make the smallest change supported by the profile, run the relevant correctness
checks, and repeat the same workload on the same device and build configuration.
Use multiple measurements when the delta is small or noisy. Compare absolute
metrics as well as percentages, and account for instrumentation, thermal state,
background load, and changed amounts of work.

When supported, use Instruments **Run Comparison** to compare corresponding
tracks and intervals in baseline and candidate runs. Inspect both improvements
and regressions. A hotspot moving down the ranking is not enough: the operation's
metric and behavior must improve. Simulator results describe the simulator;
device or shipping-app claims need matching evidence.

Report the bottleneck with a trace interval and source location, the change and
its reason, the before/after metric, the correctness result, and any remaining
uncertainty. If no reliable improvement was measured, say so.

## Further guidance

- [Apple's call-tree and Top Functions guide](https://developer.apple.com/documentation/xcode/analyzing-cpu-profiles-with-call-tree-views)
- [Apple's responsiveness diagnostic workflow](https://developer.apple.com/videos/play/wwdc2026/268/)
- [Recording performance intervals](https://developer.apple.com/documentation/os/recording-performance-data)
- [Xcode 26.4 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-26_4-release-notes)
- [Swift Dev Journal article that prompted this skill](https://swiftdevjournal.com/posts/top-functions/)
