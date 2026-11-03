## 2024-11-03 - Batch ADB shell calls
**Learning:** Each ADB shell call incurs a significant initialization overhead (~100-300ms). When multiple properties or commands need to be run sequentially, executing them in individual `adb shell` calls creates a bottleneck.
**Action:** Always batch multiple device shell commands into a single `adb shell` invocation by passing a multi-line string or separating commands with semicolons to reduce network and initialization latency.
