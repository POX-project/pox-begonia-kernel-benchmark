## 2023-10-24 - Batching ADB Shell Calls to Minimize Initialization Latency
**Learning:** ADB shell calls have a significant initialization overhead (~100-300ms each). Making multiple sequential calls to retrieve system metadata (like `getprop` or `uname`) incurs a severe cumulative latency penalty.
**Action:** Always batch multiple device shell commands into a single `adb shell` invocation using semicolons (e.g. `adb shell "cmd1; cmd2"`) and parse the consolidated output block to reduce performance bottleneck.
