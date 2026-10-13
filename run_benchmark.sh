#!/usr/bin/env bash
#
# run_benchmark.sh - Pox Begonia Kernel Benchmark & Verification Suite
# Tailored specifically for Redmi Note 8 Pro (begonia / MT6785 / Helio G90T)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Source harness libraries
source "$SCRIPT_DIR/harness/common.sh"
source "$SCRIPT_DIR/harness/device_control.sh"

# Default configuration
RUN_MODE="auto"
TARGET_SUBSYSTEM="all"
COMPARE_BASELINE=""
OUTPUT_JSON=""
OUTPUT_MD=""
ADB_SERIAL=""
SUITE_DURATION=300 # Default to 5 minutes (300 seconds) sustained run

usage() {
    cat << 'HELP_EOF'
Usage: ./run_benchmark.sh [OPTIONS]

Pox Begonia Kernel Verification & Performance Suite

Options:
  -m, --mode <auto|root|non-root>   Execution mode (default: auto-detect)
  -s, --subsystem <name>            Target subsystem: all, identity, sched, xswapd, power, thermal, ged, storage, security
  -t, --duration <seconds>          Sustained benchmark run duration (default: 300s / 5 minutes)
  -c, --compare <baseline.json>     Compare current run with baseline JSON (e.g. baselines/stock_miui12_baseline.json)
  -o, --output <file.json>          Specify custom path for output JSON
  --report-md <file.md>             Generate detailed Markdown regression report
  -d, --device <serial>             Specify ADB target serial
  -h, --help                        Show this help message

Examples:
  ./run_benchmark.sh --duration 300
  ./run_benchmark.sh --duration 300 --compare baselines/pox_v0.9_sultan_baseline.json --report-md results/pox_1.0_vs_0.9_report.md
HELP_EOF
    exit 0
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--mode)
            RUN_MODE="$2"
            shift 2
            ;;
        -s|--subsystem)
            TARGET_SUBSYSTEM="$2"
            shift 2
            ;;
        -t|--duration)
            SUITE_DURATION="$2"
            shift 2
            ;;
        -c|--compare)
            COMPARE_BASELINE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_JSON="$2"
            shift 2
            ;;
        --report-md)
            OUTPUT_MD="$2"
            shift 2
            ;;
        -d|--device)
            ADB_SERIAL="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_fail "Unknown parameter: $1"
            usage
            ;;
    esac
done

# Initialize
log_header "POX BEGONIA KERNEL SUSTAINED BENCHMARK & VERIFICATION (5-MIN RUN)"

# 1. Device Connection & Privilege Verification
check_device_connection

# Force Non-Root if requested
if [[ "$RUN_MODE" == "non-root" ]]; then
    IS_ROOTED=false
    log_info "Operating in Non-Root mode by user request."
elif [[ "$RUN_MODE" == "root" && "$IS_ROOTED" != "true" ]]; then
    log_fail "Root mode was requested, but device does NOT have root (SU) access!"
    exit 1
fi

# 2. Setup Device Workspace & Deploy Native Binaries
setup_device_environment

# Trap for guaranteed cleanup on exit/interruption
trap 'restore_cpu_frequencies; cleanup_device_environment' EXIT INT TERM

# 3. Frequency & Thermal Staging
lock_cpu_frequencies

# 4. Source Kernel-Specific Modules
source "$SCRIPT_DIR/modules/01_pox_identity_abi.sh"
source "$SCRIPT_DIR/modules/02_sched_eas_nodelooper.sh"
source "$SCRIPT_DIR/modules/03_pox_xswapd_memory.sh"
source "$SCRIPT_DIR/modules/04_mt6785_power_charging.sh"
source "$SCRIPT_DIR/modules/05_mt6785_thermal_ppm.sh"
source "$SCRIPT_DIR/modules/06_ged_gpu_display.sh"
source "$SCRIPT_DIR/modules/07_storage_crypto.sh"
source "$SCRIPT_DIR/modules/08_root_security_patch.sh"

SUITE_START_TIME=$(date +%s)
PASS_COUNT=0

log_info "Target Sustained Test Duration: ${SUITE_DURATION} seconds ($(( SUITE_DURATION / 60 )) minutes)"

# Phase A: Identity & Vendor ABI check
run_pox_identity_abi_module

# Phase B: Sustained Workload Evaluation Loop across the 5-minute duration
while true; do
    PASS_COUNT=$(( PASS_COUNT + 1 ))
    NOW=$(date +%s)
    ELAPSED=$(( NOW - SUITE_START_TIME ))
    REMAINING=$(( SUITE_DURATION - ELAPSED ))
    PCT=$(( (ELAPSED * 100) / SUITE_DURATION ))
    if [ "$PCT" -gt 100 ]; then PCT=100; fi

    printf "\n${CLR_CYAN}${CLR_BOLD}═══════════════════════════════════════════════════════════════════════════${CLR_RESET}\n"
    printf "${CLR_CYAN}${CLR_BOLD}  SUSTAINED LOAD PASS #%d | %ds / %ds elapsed (%d%%) | %ds remaining${CLR_RESET}\n" "$PASS_COUNT" "$ELAPSED" "$SUITE_DURATION" "$PCT" "$REMAINING"
    printf "${CLR_CYAN}${CLR_BOLD}═══════════════════════════════════════════════════════════════════════════${CLR_RESET}\n"

    case "$TARGET_SUBSYSTEM" in
        all)
            run_sched_eas_nodelooper_module
            run_pox_xswapd_memory_module
            run_mt6785_power_charging_module
            run_mt6785_thermal_ppm_module
            run_ged_gpu_display_module
            run_storage_crypto_module
            ;;
        sched)    run_sched_eas_nodelooper_module ;;
        xswapd)   run_pox_xswapd_memory_module ;;
        power)    run_mt6785_power_charging_module ;;
        thermal)  run_mt6785_thermal_ppm_module ;;
        ged)      run_ged_gpu_display_module ;;
        storage)  run_storage_crypto_module ;;
        *)
            log_fail "Unknown subsystem: $TARGET_SUBSYSTEM"
            exit 1
            ;;
    esac

    NOW=$(date +%s)
    ELAPSED=$(( NOW - SUITE_START_TIME ))
    if [ "$ELAPSED" -ge "$SUITE_DURATION" ]; then
        log_pass "Sustained test duration of ${ELAPSED}s (>= ${SUITE_DURATION}s) completed successfully across $PASS_COUNT passes!"
        break
    fi

    # Brief 3-second pacing settle between intense stress cycles
    log_info "Settling hardware queues (3s) before next sustained pass..."
    sleep 3
done

# Phase C: Security & SELinux health check post-stress
run_root_security_patch_module

TOTAL_ELAPSED=$(( $(date +%s) - SUITE_START_TIME ))
record_metric "thermal" "suite_total_duration_s" "Sustained Suite Duration" "$TOTAL_ELAPSED" "s" true
record_metric "thermal" "suite_total_passes" "Sustained Passes Completed" "$PASS_COUNT" "passes" true

# 5. Teardown
restore_cpu_frequencies
cleanup_device_environment

# 6. Save JSON Results
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
if [[ -z "$OUTPUT_JSON" ]]; then
    OUTPUT_JSON="$SCRIPT_DIR/results/run_${TIMESTAMP}.json"
fi

export_results_json "$OUTPUT_JSON"

# 7. Automated Regression Analysis & Insights
if [[ -n "$COMPARE_BASELINE" ]]; then
    log_header "ANALYZING REGRESSIONS AGAINST BASELINE"
    PYTHON_CMD="python3 $SCRIPT_DIR/analyze_regression.py --current $OUTPUT_JSON --baseline $COMPARE_BASELINE"
    if [[ -n "$OUTPUT_MD" ]]; then
        PYTHON_CMD="$PYTHON_CMD --output-md $OUTPUT_MD"
    fi
    eval "$PYTHON_CMD"
elif [[ -f "$SCRIPT_DIR/baselines/pox_v0.9_sultan_baseline.json" ]]; then
    log_info "Tip: Run with --compare baselines/pox_v0.9_sultan_baseline.json to track regression deltas!"
fi

log_pass "Benchmark cycle complete! Results archived at: $OUTPUT_JSON"
