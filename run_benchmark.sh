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

usage() {
    cat << 'HELP_EOF'
Usage: ./run_benchmark.sh [OPTIONS]

Pox Begonia Kernel Verification & Performance Suite

Options:
  -m, --mode <auto|root|non-root>   Execution mode (default: auto-detect)
  -s, --subsystem <name>            Target subsystem: all, identity, sched, xswapd, power, thermal, ged, storage, security
  -c, --compare <baseline.json>     Compare current run with baseline JSON (e.g. baselines/stock_miui12_baseline.json)
  -o, --output <file.json>          Specify custom path for output JSON
  --report-md <file.md>             Generate detailed Markdown regression report
  -d, --device <serial>             Specify ADB target serial
  -h, --help                        Show this help message

Examples:
  ./run_benchmark.sh
  ./run_benchmark.sh --compare baselines/stock_miui12_baseline.json
  ./run_benchmark.sh --compare baselines/pox_v0.9_sultan_baseline.json --report-md results/pox_1.0_vs_0.9_report.md
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
log_header "POX BEGONIA KERNEL BENCHMARK & VERIFICATION FRAMEWORK"

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

# 2. Setup Device Workspace
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

case "$TARGET_SUBSYSTEM" in
    all)
        run_pox_identity_abi_module
        run_sched_eas_nodelooper_module
        run_pox_xswapd_memory_module
        run_mt6785_power_charging_module
        run_mt6785_thermal_ppm_module
        run_ged_gpu_display_module
        run_storage_crypto_module
        run_root_security_patch_module
        ;;
    identity) run_pox_identity_abi_module ;;
    sched)    run_sched_eas_nodelooper_module ;;
    xswapd)   run_pox_xswapd_memory_module ;;
    power)    run_mt6785_power_charging_module ;;
    thermal)  run_mt6785_thermal_ppm_module ;;
    ged)      run_ged_gpu_display_module ;;
    storage)  run_storage_crypto_module ;;
    security) run_root_security_patch_module ;;
    *)
        log_fail "Unknown subsystem: $TARGET_SUBSYSTEM"
        exit 1
        ;;
esac

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
