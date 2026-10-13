# ⚡ Pox Begonia Kernel Benchmark Regression Report

**Overall Verdict:** ⚠️ REGRESSIONS DETECTED  
**Composite Pox Score:** `1000.0 / 1000`  

## 📱 Test Environments

| Attribute | Current Build | Baseline Reference |
| :--- | :--- | :--- |
| **Device** | `Redmi Note 8 Pro (begonia)` | `Redmi Note 8 Pro (begonia)` |
| **Kernel** | `4.14.357-Pox-1.0.0-Beta-Onyx-Sultan-APatch-50086db` | `4.14.357-Pox-0.9-Onyx-Sultan` |
| **Android** | `Android 16 (BP4A.251205.006)` | `Android 14 (UP1A.231005.007)` |
| **Execution Mode** | `auto (Root: True)` | `root (Root: True)` |

## 📊 Subsystem Verification & Regression Matrix

| Subsystem | Metric Name | Baseline | Current | Δ % | Status |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **IDENTITY** | UTS_RELEASE Character Length | `27.0 chars` | `50.0 chars` | `+0.0%` | ⚖️ STABLE |
| **IDENTITY** | Pox Kernel Signature | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **IDENTITY** | Early Boot Crash Count | `0.0 panics` | `0.0 panics` | `+0.0%` | ⚖️ STABLE |
| **SCHED** | NodeLooper Sysctl Writable | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **SCHED** | Cortex-A76 vs A55 Speedup | `2.38 x` | `1.82 x` | `-23.5%` | 🔻 REGRESSED |
| **SCHED** | Pipe Context Switch Latency | `13.1 µs` | `10.28 µs` | `+21.5%` | 🚀 GAINED |
| **SCHED** | Process Fork & Exec Overhead | `1.95 ms` | `0.11 ms` | `+94.4%` | 🚀 GAINED |
| **MEMORY** | Pox xswapd Daemon Active | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **MEMORY** | xswapd Reclaimed Total | `142.0 MB` | `1677.0 MB` | `+1081.0%` | 🚀 GAINED |
| **MEMORY** | RAM Sequential Bandwidth | `3100.0 MiB/s` | `6100.0 MiB/s` | `+96.8%` | 🚀 GAINED |
| **MEMORY** | Anonymous Page Fault Latency | `2.25 µs` | `2.0 µs` | `+11.1%` | 🚀 GAINED |
| **MEMORY** | ZRAM Compression Ratio | `2.6 :1` | `2.5 :1` | `-3.8%` | ⚖️ STABLE |
| **MEMORY** | Memory PSI Stall Rate (avg10) | `0.2 %` | `0.0 %` | `+100.0%` | 🚀 GAINED |
| **POWER** | USB SDP 500mA Compliant | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **POWER** | Charging Current Draw | `495.0 mA` | `85.4 mA` | `+82.7%` | 🚀 GAINED |
| **POWER** | Baseline Current Consumption | `215.0 mA` | `28.0 mA` | `+87.0%` | 🚀 GAINED |
| **THERMAL** | Helio G90T CPU Temp | `38.0 °C` | `49.0 °C` | `-28.9%` | 🔻 REGRESSED |
| **THERMAL** | MT6359 PMIC Temp | `36.0 °C` | `46.0 °C` | `-27.8%` | 🔻 REGRESSED |
| **THERMAL** | MediaTek PPM Active | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **THERMAL** | Peak Stress Thermal Temp | `39.5 °C` | `38.0 °C` | `+3.8%` | ⚖️ STABLE |
| **GRAPHICS** | MediaTek GED Active | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **GRAPHICS** | SurfaceFlinger Jank Ratio | `1.6 %` | `2.24 %` | `-40.0%` | 🔻 REGRESSED |
| **GRAPHICS** | 99th Percentile Frame Time | `14.8 ms` | `32.0 ms` | `-116.2%` | 🔻 REGRESSED |
| **STORAGE** | Sequential Write Throughput | `275.0 MB/s` | `3950.6 MB/s` | `+1336.6%` | 🚀 GAINED |
| **STORAGE** | Sequential Read Throughput | `505.0 MB/s` | `2587.2 MB/s` | `+412.3%` | 🚀 GAINED |
| **STORAGE** | 4KiB Sync Write IOPS | `410.0 IOPS` | `313797.0 IOPS` | `+76435.9%` | 🚀 GAINED |
| **STORAGE** | Fsync Barrier Latency | `2.45 ms` | `0.45 ms` | `+81.6%` | 🚀 GAINED |
| **CRYPTO** | ARMv8 SHA-256 Throughput | `445.0 MB/s` | `663.6 MB/s` | `+49.1%` | 🚀 GAINED |
| **CRYPTO** | ARMv8 SHA-512 Throughput | `375.0 MB/s` | `259.9 MB/s` | `-30.7%` | 🔻 REGRESSED |
| **SECURITY** | Root Provider Active | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **SECURITY** | SELinux Enforcing Mode | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **THERMAL** | Sustained Suite Duration | `308.0 s` | `308.0 s` | `+0.0%` | ⚖️ STABLE |
| **THERMAL** | Sustained Passes Completed | `23.0 passes` | `23.0 passes` | `+0.0%` | ⚖️ STABLE |

## 📈 Executive Summary

- 🚀 **Gains / Improvements:** `13` metrics
- ⚖️ **Stable Metrics:** `14` metrics
- 🔻 **Regressions Detected:** `6` metrics

> [!WARNING]
> The build failed verification quality gates due to detected subsystem regressions. Review commits before releasing.
