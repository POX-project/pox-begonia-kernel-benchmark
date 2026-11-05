## 2024-03-01 - ADB Shell Batching Overhead
**Learning:** ADB shell calls have a significant initialization overhead (~100-300ms each). When executing multiple commands (like gathering metadata or checking various sysfs paths), invoking `adb shell` for each command compounds this latency, creating a noticeable delay.
**Action:** Always batch multiple device shell commands into a single `adb shell` invocation (e.g., using a single multiline string or separating commands with `&&` or `;`) to reduce initialization latency.
