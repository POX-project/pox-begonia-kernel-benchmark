## 2024-05-25 - Batching ADB Shell Commands
**Learning:** ADB shell calls have a significant initialization overhead (~100-300ms). Executing multiple commands in a loop from the host incurs this penalty repeatedly.
**Action:** Always batch multiple device shell commands into a single `adb shell` invocation to reduce latency.
