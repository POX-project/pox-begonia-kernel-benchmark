## 2023-11-09 - Performance pattern (ADB)
**Learning:** ADB shell calls have a significant initialization overhead (~100-300ms).
**Action:** Always batch multiple device shell commands into a single `adb shell` invocation to reduce latency.
