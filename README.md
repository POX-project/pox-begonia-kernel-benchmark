# ⚡ Pox Begonia Kernel Benchmark & Verification Framework

A versatile, multi-subsystem Android kernel benchmarking and regression tracking suite built specifically for **Redmi Note 8 Pro** (`begonia` / MediaTek Helio G90T / MT6785) running the **Pox Kernel**.

The suite evaluates all critical kernel facets and mathematically tracks improvements ($\Delta\%$) across builds to ensure development is **progressing up, not down**.

---

## 🎯 Verification Matrix & Kernel Subsystems

| Subsystem | Verified Aspects | Key Metrics Captured | Tier Support |
| :--- | :--- | :--- | :--- |
| **Scheduler & EAS** | Pipe context switch latency, process fork overhead, big.LITTLE core affinity, multi-core throughput | `sched_ctx_switch_us` (µs)<br>`sched_fork_latency_ms` (ms)<br>`sched_cortex_a76_speedup_x` (x)<br>`sched_multithread_throughput_mops` (MOps/s) | Root & Non-Root |
| **Memory & VM** | RAM sequential bandwidth, anonymous page fault latency, ZRAM compression ratio, PSI memory stalls | `mem_bandwidth_mibs` (MiB/s)<br>`mem_page_fault_lat_us` (µs)<br>`mem_zram_ratio` (:1)<br>`mem_psi_stall_pct` (%) | Root & Non-Root |
| **Storage & Block I/O** | Sequential R/W, 4KiB random direct synchronous IOPS, `fsync()` barrier commit latency | `io_seq_write_mbs` (MB/s)<br>`io_seq_read_mbs` (MB/s)<br>`io_4k_sync_iops` (IOPS)<br>`io_fsync_latency_ms` (ms) | Root & Non-Root |
| **IPC & Android System** | Synchronous two-way Binder round-trip latency, Unix domain socket latency, Activity cold launch | `ipc_binder_latency_us` (µs)<br>`ipc_socket_latency_us` (µs)<br>`ipc_cold_launch_ms` (ms) | Root & Non-Root |
| **Graphics & UX** | SurfaceFlinger jank %, missed vsync frames, 90th & 99th percentile frame render time | `gfx_jank_percent` (%)<br>`gfx_p90_frame_time_ms` (ms)<br>`gfx_p99_frame_time_ms` (ms) | Root & Non-Root |
| **Power & Thermal** | PC USB 500mA SDP compliance, active battery current draw, Helio G90T peak thermal zone temps | `pwr_charging_current_ma` (mA)<br>`pwr_idle_current_ma` (mA)<br>`pwr_peak_temp_c` (°C) | Root & Non-Root |
| **ARMv8 Crypto** | Hardware Cryptography Extensions (CE): SHA-256, SHA-512, and AES-256 (Android FBE backend) | `crypto_sha256_mbs` (MB/s)<br>`crypto_sha512_mbs` (MB/s)<br>`crypto_aes256_mbs` (MB/s) | Root & Non-Root |

---

## 🚀 Dual Execution Tiers

### 1. Root Mode (`--mode root`)
* **Unlocked Capabilities**:
  - Automatically locks CPU governors to `performance` during testing to eliminate frequency scaling ramp-up jitter.
  - Flushes kernel page cache via `/proc/sys/vm/drop_caches` before cold runs.
  - Directly queries PMIC charging registers and raw battery currents.
  - Triggers memory compaction to verify zero-stall behavior.

### 2. Non-Root Mode (`--mode non-root`)
* **Unlocked Capabilities**:
  - Requires **zero privileges**; operates in standard `adb shell` user mode.
  - Executes self-contained POSIX/toybox shell benchmarks with nanosecond precision timers.
  - Scrapes platform telemetry from `dumpsys gfxinfo`, `dumpsys battery`, and `/proc/pressure/*`.
  - Runs safely on stock devices, production user builds, or unrooted testing environments.

---

## 📊 Regression Detection & Scoring Engine

Every benchmark run exports a structured JSON artifact to `results/`.

Comparing a run against a baseline (e.g., Stock MIUI 12 or Pox 0.9 Sultan) calculates:

$$\Delta\% = \frac{\text{Current} - \text{Baseline}}{\text{Baseline}} \times 100$$

* 🚀 **`GAINED`**: Performance or efficiency improved by $\ge +5.0\%$
* ⚖️ **`STABLE`**: Performance within $\pm 5.0\%$ parity
* 🔻 **`REGRESSED`**: Performance dropped by $\le -5.0\%$

### Composite Pox Kernel Score (0 to 1000)
A single aggregate figure evaluating:
* **Responsiveness (25%)**: Sched latency, fork time, Binder latency
* **Throughput (20%)**: Memory bandwidth, compute, crypto
* **Storage Speed (20%)**: 4K sync IOPS, fsync latency, sequential R/W
* **UI Fluidity (15%)**: SurfaceFlinger 99th percentile frame latency, jank %
* **Efficiency (10%)**: Idle drain, USB 500mA compliance, thermal throttling
* **Crypto (10%)**: ARMv8 SHA & AES acceleration

---

## 🛠️ Quickstart Guide

### 1. Run Complete Benchmark (Auto Mode)
```bash
./run_benchmark.sh
```

### 2. Run Benchmark & Compare Against Stock MIUI 12 Baseline
```bash
./run_benchmark.sh --compare baselines/stock_miui12_baseline.json
```

### 3. Run Benchmark & Compare Against Pox 0.9 Sultan (with Markdown Report)
```bash
./run_benchmark.sh \
    --compare baselines/pox_v0.9_sultan_baseline.json \
    --report-md results/pox_1.0_vs_0.9_report.md
```

### 4. Benchmark Specific Subsystem (e.g. Scheduler Only)
```bash
./run_benchmark.sh --subsystem sched
```

### 5. Manually Diff Two Saved Runs
```bash
python3 analyze_regression.py \
    --current results/run_20261013_120000.json \
    --baseline baselines/pox_v0.9_sultan_baseline.json \
    --output-md results/comparison.md
```
