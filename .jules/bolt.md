## 2024-05-18 - ADB Shell Initialization Overhead
**Learning:** ADB shell calls have a significant initialization overhead (~100-300ms per call). Running sequential shell commands creates a large performance bottleneck when communicating with a physical Android device.
**Action:** Always batch multiple device shell commands into a single `adb shell` invocation (e.g., separating with semicolons) and extract the output via sed/awk to reduce latency.
