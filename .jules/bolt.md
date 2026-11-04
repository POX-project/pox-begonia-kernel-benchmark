## 2024-05-13 - ADB Shell Overhead Bottleneck
**Learning:** ADB shell calls have a significant initialization overhead (~100-300ms) in this test harness. When reading device metadata sequentially, this results in multiple seconds of unnecessary delay.
**Action:** Always batch multiple device shell commands into a single `adb shell` invocation outputting a multi-line string, and parse it locally to eliminate initialization latency.
