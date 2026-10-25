## 2024-05-19 - Batched ADB Shell Executions
**Learning:** Performing multiple independent `adb shell` calls carries significant overhead (~100-300ms per invocation) due to connection and process creation.
**Action:** Always batch related properties and commands within a single `adb shell "cmd1; cmd2; ..."` string. Then parse the newline-separated output locally in Bash using tools like `sed` or `awk` to extract the individual results, minimizing latency.
