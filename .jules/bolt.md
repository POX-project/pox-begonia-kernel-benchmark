## 2024-05-24 - Bash ADB Connection Overhead
**Learning:** ADB shell calls have a significant initialization overhead (~100-300ms) on this device structure. Executing individual `adb_cmd shell` commands within loops running on the host significantly degrades test accuracy and execution speed, causing jitter.
**Action:** Always batch multiple device shell commands into a single `adb shell` invocation. If a loop needs to run on the device, construct the loop logic inside the multi-line string passed to `adb shell` to execute it entirely on the device, saving repeated overhead.
