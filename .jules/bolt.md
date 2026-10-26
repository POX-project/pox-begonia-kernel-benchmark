## 2026-10-26 - Eliminate repeated ADB shell connection overhead
**Learning:** ADB shell calls have a significant initialization overhead (~100-300ms per invocation). Executing multiple sequential ADB shell commands individually within a loop introduces massive unnecessary latency.
**Action:** Always batch multiple device shell commands into a single `adb shell` invocation script block to reduce connection latency and guarantee tighter execution timing.
