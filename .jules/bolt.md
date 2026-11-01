## 2023-11-01 - ADB Shell Initialization Overhead
**Learning:** ADB shell calls have a significant initialization overhead (~100-300ms per call). Running multiple consecutive `adb shell` calls can drastically slow down scripts, introducing unnecessary bottlenecks.
**Action:** Always batch multiple device shell commands into a single `adb shell` invocation with a multi-line string to reduce initialization latency.
