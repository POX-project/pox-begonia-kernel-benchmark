## 2024-10-24 - Batching ADB Shell calls for Performance
**Learning:** In the Pox Begonia Kernel Benchmark suite, `adb shell` calls have a significant initialization overhead (~100-300ms each). Having multiple subsequent `adb shell` commands in bash scripts adds up to large delays, especially when polling device states or reading several properties (like `getprop` or `uname`).
**Action:** Always batch multiple device shell commands into a single `adb shell` invocation using inline scripts or multi-line strings, and parse the combined output in Bash instead of making sequential roundtrips.
