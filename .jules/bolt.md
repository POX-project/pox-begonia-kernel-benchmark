## 2024-03-24 - Batching ADB Shell Commands
**Learning:** The test harness calls `adb_cmd shell` in loops for things like UI swipes, which creates significant performance overhead due to repeated ADB connection initialization (~100-300ms per call).
**Action:** Always batch repeated `adb shell` commands into a single `adb shell` invocation using string interpolation to significantly reduce latency.
