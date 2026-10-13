# ⚡ Pox Begonia Kernel Benchmark Regression Report

**Overall Verdict:** ⚠️ REGRESSIONS DETECTED  
**Composite Pox Score:** `355.3 / 1000`  

## 📱 Test Environments

| Attribute | Current Build | Baseline Reference |
| :--- | :--- | :--- |
| **Device** | `Redmi Note 8 Pro (begonia)` | `Redmi Note 8 Pro (begonia)` |
| **Kernel** | `4.14.357-Pox-1.0.0-Beta-Onyx-Sultan-APatch-95c80f5` | `4.14.357-Pox-1.0.0-Beta-Onyx-Sultan-APatch-50086db` |
| **Android** | `Android 16 (BP4A.251205.006)` | `Android 16 (BP4A.251205.006)` |
| **Execution Mode** | `auto (Root: True)` | `auto (Root: True)` |

## 📊 Subsystem Verification & Regression Matrix

| Subsystem | Metric Name | Baseline | Current | Δ % | Status |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **IDENTITY** | UTS_RELEASE Character Length | `50.0 chars` | `50.0 chars` | `+0.0%` | ⚖️ STABLE |
| **IDENTITY** | Pox Kernel Signature | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **IDENTITY** | Early Boot Crash Count | `0.0 panics` | `0.0 panics` | `+0.0%` | ⚖️ STABLE |
| **SCHED** | NodeLooper Sysctl Writable | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **SCHED** | Cortex-A76 vs A55 Speedup | `1.82 x` | `1.82 x` | `+0.0%` | ⚖️ STABLE |
| **SCHED** | Pipe Context Switch Latency | `10.28 µs` | `8.86 µs` | `+13.8%` | 🚀 GAINED |
| **SCHED** | Process Fork & Exec Overhead | `0.11 ms` | `0.1 ms` | `+9.1%` | 🚀 GAINED |
| **MEMORY** | Pox xswapd Daemon Active | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **MEMORY** | xswapd Reclaimed Total | `1677.0 MB` | `1416.0 MB` | `-15.6%` | 🔻 REGRESSED |
| **MEMORY** | RAM Sequential Bandwidth | `6100.0 MiB/s` | `6323.0 MiB/s` | `+3.7%` | ⚖️ STABLE |
| **MEMORY** | Anonymous Page Fault Latency | `2.0 µs` | `1.81 µs` | `+9.5%` | 🚀 GAINED |
| **MEMORY** | ZRAM Compression Ratio | `2.5 :1` | `2.5 :1` | `+0.0%` | ⚖️ STABLE |
| **MEMORY** | Memory PSI Stall Rate (avg10) | `0.0 %` | `0.0 %` | `+0.0%` | ⚖️ STABLE |
| **POWER** | USB SDP 500mA Compliant | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **POWER** | Charging Current Draw | `85.4 mA` | `222.1 mA` | `-160.1%` | 🔻 REGRESSED |
| **POWER** | Baseline Current Consumption | `28.0 mA` | `115.9 mA` | `-313.9%` | 🔻 REGRESSED |
| **THERMAL** | Helio G90T CPU Temp | `49.0 °C` | `47.0 °C` | `+4.1%` | ⚖️ STABLE |
| **THERMAL** | MT6359 PMIC Temp | `46.0 °C` | `44.0 °C` | `+4.3%` | ⚖️ STABLE |
| **THERMAL** | MediaTek PPM Active | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **THERMAL** | Peak Stress Thermal Temp | `38.0 °C` | `38.0 °C` | `+-0.0%` | ⚖️ STABLE |
| **GRAPHICS** | MediaTek GED Active | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **GRAPHICS** | SurfaceFlinger Jank Ratio | `2.24 %` | `2.34 %` | `-4.5%` | ⚖️ STABLE |
| **GRAPHICS** | 99th Percentile Frame Time | `32.0 ms` | `61.0 ms` | `-90.6%` | 🔻 REGRESSED |
| **STORAGE** | Sequential Write Throughput | `3950.6 MB/s` | `3795.9 MB/s` | `-3.9%` | ⚖️ STABLE |
| **STORAGE** | Sequential Read Throughput | `2587.2 MB/s` | `3862.4 MB/s` | `+49.3%` | 🚀 GAINED |
| **STORAGE** | 4KiB Sync Write IOPS | `313797.0 IOPS` | `124278.0 IOPS` | `-60.4%` | 🔻 REGRESSED |
| **STORAGE** | Fsync Barrier Latency | `0.45 ms` | `0.45 ms` | `+-0.0%` | ⚖️ STABLE |
| **CRYPTO** | ARMv8 SHA-256 Throughput | `663.6 MB/s` | `646.1 MB/s` | `-2.6%` | ⚖️ STABLE |
| **CRYPTO** | ARMv8 SHA-512 Throughput | `259.9 MB/s` | `256.3 MB/s` | `-1.4%` | ⚖️ STABLE |
| **SECURITY** | Root Provider Active | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **SECURITY** | SELinux Enforcing Mode | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **THERMAL** | Sustained Suite Duration | `308.0 s` | `311.0 s` | `+1.0%` | ⚖️ STABLE |
| **THERMAL** | Sustained Passes Completed | `23.0 passes` | `23.0 passes` | `+0.0%` | ⚖️ STABLE |

## 📈 Executive Summary

- 🚀 **Gains / Improvements:** `4` metrics
- ⚖️ **Stable Metrics:** `24` metrics
- 🔻 **Regressions Detected:** `5` metrics

> [!WARNING]
> The build failed verification quality gates due to detected subsystem regressions. Review commits before releasing.
