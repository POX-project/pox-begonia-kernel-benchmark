# ⚡ Pox Begonia Kernel Benchmark Regression Report

**Overall Verdict:** ✅ PROGRESSING UP (PASSED)  
**Composite Pox Score:** `763.5 / 1000`  

## 📱 Test Environments

| Attribute | Current Build | Baseline Reference |
| :--- | :--- | :--- |
| **Device** | `Redmi Note 8 Pro (begonia)` | `Redmi Note 8 Pro (begonia)` |
| **Kernel** | `4.14.357-Pox-0.9-Onyx-Sultan` | `4.14.186-stock-user` |
| **Android** | `Android 14 (UP1A.231005.007)` | `Android 10 (QP1A.190711.020)` |
| **Execution Mode** | `root (Root: True)` | `non-root (Root: False)` |

## 📊 Subsystem Verification & Regression Matrix

| Subsystem | Metric Name | Baseline | Current | Δ % | Status |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **IDENTITY** | UTS_RELEASE Character Length | `19.0 chars` | `27.0 chars` | `+0.0%` | ⚖️ STABLE |
| **IDENTITY** | Pox Kernel Signature | `0.0 bool` | `1.0 bool` | `+100.0%` | 🚀 GAINED |
| **IDENTITY** | Early Boot Crash Count | `0.0 panics` | `0.0 panics` | `+0.0%` | ⚖️ STABLE |
| **SCHED** | NodeLooper Sysctl Writable | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **SCHED** | Cortex-A76 vs A55 Speedup | `2.15 x` | `2.38 x` | `+10.7%` | 🚀 GAINED |
| **SCHED** | Pipe Context Switch Latency | `18.4 µs` | `13.1 µs` | `+28.8%` | 🚀 GAINED |
| **SCHED** | Process Fork & Exec Overhead | `2.95 ms` | `1.95 ms` | `+33.9%` | 🚀 GAINED |
| **MEMORY** | Pox xswapd Daemon Active | `0.0 bool` | `1.0 bool` | `+100.0%` | 🚀 GAINED |
| **MEMORY** | xswapd Reclaimed Total | `0.0 MB` | `142.0 MB` | `+100.0%` | 🚀 GAINED |
| **MEMORY** | RAM Sequential Bandwidth | `2450.0 MiB/s` | `3100.0 MiB/s` | `+26.5%` | 🚀 GAINED |
| **MEMORY** | Anonymous Page Fault Latency | `3.85 µs` | `2.25 µs` | `+41.6%` | 🚀 GAINED |
| **MEMORY** | ZRAM Compression Ratio | `2.1 :1` | `2.6 :1` | `+23.8%` | 🚀 GAINED |
| **MEMORY** | Memory PSI Stall Rate (avg10) | `1.8 %` | `0.2 %` | `+88.9%` | 🚀 GAINED |
| **POWER** | USB SDP 500mA Compliant | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **POWER** | Charging Current Draw | `500.0 mA` | `495.0 mA` | `+1.0%` | ⚖️ STABLE |
| **POWER** | Baseline Current Consumption | `280.0 mA` | `215.0 mA` | `+23.2%` | 🚀 GAINED |
| **THERMAL** | Helio G90T CPU Temp | `43.0 °C` | `38.0 °C` | `+11.6%` | 🚀 GAINED |
| **THERMAL** | MT6359 PMIC Temp | `41.0 °C` | `36.0 °C` | `+12.2%` | 🚀 GAINED |
| **THERMAL** | MediaTek PPM Active | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **THERMAL** | Peak Stress Thermal Temp | `46.5 °C` | `39.5 °C` | `+15.1%` | 🚀 GAINED |
| **GRAPHICS** | MediaTek GED Active | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |
| **GRAPHICS** | SurfaceFlinger Jank Ratio | `5.8 %` | `1.6 %` | `+72.4%` | 🚀 GAINED |
| **GRAPHICS** | 99th Percentile Frame Time | `28.5 ms` | `14.8 ms` | `+48.1%` | 🚀 GAINED |
| **STORAGE** | Sequential Write Throughput | `195.0 MB/s` | `275.0 MB/s` | `+41.0%` | 🚀 GAINED |
| **STORAGE** | Sequential Read Throughput | `420.0 MB/s` | `505.0 MB/s` | `+20.2%` | 🚀 GAINED |
| **STORAGE** | 4KiB Sync Write IOPS | `260.0 IOPS` | `410.0 IOPS` | `+57.7%` | 🚀 GAINED |
| **STORAGE** | Fsync Barrier Latency | `4.8 ms` | `2.45 ms` | `+49.0%` | 🚀 GAINED |
| **CRYPTO** | ARMv8 SHA-256 Throughput | `340.0 MB/s` | `445.0 MB/s` | `+30.9%` | 🚀 GAINED |
| **CRYPTO** | ARMv8 SHA-512 Throughput | `290.0 MB/s` | `375.0 MB/s` | `+29.3%` | 🚀 GAINED |
| **SECURITY** | Root Provider Active | `0.0 bool` | `1.0 bool` | `+100.0%` | 🚀 GAINED |
| **SECURITY** | SELinux Enforcing Mode | `1.0 bool` | `1.0 bool` | `+0.0%` | ⚖️ STABLE |

## 📈 Executive Summary

- 🚀 **Gains / Improvements:** `23` metrics
- ⚖️ **Stable Metrics:** `8` metrics
- 🔻 **Regressions Detected:** `0` metrics

> [!TIP]
> Kernel performance, stability, and power efficiency strictly progressed UP with zero regressions across verified subsystems!
