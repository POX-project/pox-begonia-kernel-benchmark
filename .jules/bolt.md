## 2024-05-24 - ADB Shell Invocation Overhead
**Learning:** ADB shell calls have a significant initialization overhead (~100-300ms). When executing multiple sequential commands or running loops on the device, calling `adb shell` repeatedly drastically inflates benchmark duration and can introduce measurement noise.
**Action:** Always batch multiple device shell commands into a single `adb shell` invocation using multi-line strings or here-docs, pushing loops and short sleeps to execute directly on the device side.
