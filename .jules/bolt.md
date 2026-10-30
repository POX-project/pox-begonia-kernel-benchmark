## 2024-05-14 - Batch ADB Shell Commands for Initialization
**Learning:** ADB shell commands have a significant initialization overhead (~100-300ms). The `harness/common.sh` file currently queries `getprop` and `uname` multiple times sequentially to gather system properties, causing unnecessary delay.
**Action:** Always batch multiple device shell commands into a single `adb shell` invocation to reduce latency when fetching device metadata.
