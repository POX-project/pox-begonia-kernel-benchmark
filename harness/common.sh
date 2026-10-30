#!/usr/bin/env bash
#
# harness/common.sh - Common utilities for Pox Begonia Kernel Benchmark
#

set -u

# ANSI Color Codes
CLR_RESET="\033[0m"
CLR_BOLD="\033[1m"
CLR_RED="\033[1;31m"
CLR_GREEN="\033[1;32m"
CLR_YELLOW="\033[1;33m"
CLR_BLUE="\033[1;34m"
CLR_CYAN="\033[1;36m"
CLR_GRAY="\033[0;90m"

log_info()   { printf "${CLR_BLUE}[*]${CLR_RESET} %s\n" "$*"; }
log_pass()   { printf "${CLR_GREEN}[+] PASS:${CLR_RESET} %s\n" "$*"; }
log_warn()   { printf "${CLR_YELLOW}[!] WARN:${CLR_RESET} %s\n" "$*"; }
log_fail()   { printf "${CLR_RED}[-] FAIL:${CLR_RESET} %s\n" "$*"; }
log_header() {
    printf "\n${CLR_CYAN}${CLR_BOLD}═══════════════════════════════════════════════════════════════════════════${CLR_RESET}\n"
    printf "${CLR_CYAN}${CLR_BOLD}  %s${CLR_RESET}\n" "$*"
    printf "${CLR_CYAN}${CLR_BOLD}═══════════════════════════════════════════════════════════════════════════${CLR_RESET}\n\n"
}

log_metric() {
    local name="$1"
    local val="$2"
    local unit="$3"
    printf "  ${CLR_GRAY}▸${CLR_RESET} %-36s ${CLR_BOLD}%10s${CLR_RESET} %s\n" "$name" "$val" "$unit"
}

# Metric Storage Structure (Key-Deduplicated)
declare -A METRIC_MAP=()
declare -a METRIC_KEYS=()

record_metric() {
    local category="$1"
    local key="$2"
    local name="$3"
    local raw_val="$4"
    local unit="$5"
    local higher_is_better="${6:-true}"

    # Sanitize numeric value to guarantee strict JSON validity (e.g. no "00", trailing newlines, or text)
    local clean_val
    clean_val=$(awk -v v="$raw_val" 'BEGIN {
        gsub(/[^0-9.-]/, "", v);
        if (v == "" || v == "-") v = "0";
        num = v + 0;
        print num;
    }')

    log_metric "$name" "$clean_val" "$unit"

    local entry
    entry=$(cat <<METRIC_EOF
    {
      "category": "$category",
      "key": "$key",
      "name": "$name",
      "value": $clean_val,
      "unit": "$unit",
      "higher_is_better": $higher_is_better
    }
METRIC_EOF
)
    if [[ -z "${METRIC_MAP[$key]:-}" ]]; then
        METRIC_KEYS+=("$key")
    fi
    METRIC_MAP["$key"]="$entry"
}

# ADB Command Runner
adb_cmd() {
    if [[ -n "${ADB_SERIAL:-}" ]]; then
        adb -s "$ADB_SERIAL" "$@"
    else
        adb "$@"
    fi
}

# Run command on device (supports root vs non-root)
device_exec() {
    local cmd="$1"
    if [[ "${RUN_MODE:-auto}" == "root" || "${IS_ROOTED:-false}" == "true" ]]; then
        adb_cmd shell "su -c '$cmd'"
    else
        adb_cmd shell "$cmd"
    fi
}

# Read file from device
device_read() {
    local path="$1"
    device_exec "cat $path 2>/dev/null" || true
}

# Check if ADB device is connected and authorized
check_device_connection() {
    log_info "Probing for connected ADB devices..."
    local devices
    devices=$(adb devices | grep -v "List of devices" | grep "device$" || true)

    if [[ -z "$devices" ]]; then
        log_fail "No authorized Android device detected via ADB!"
        log_info "Please connect device, enable USB Debugging, and authorize PC."
        return 1
    fi

    if [[ -z "${ADB_SERIAL:-}" ]]; then
        for dev in $(echo "$devices" | awk '{print $1}'); do
            local codename=$(adb -s "$dev" shell "getprop ro.product.device" 2>/dev/null | tr -d '
')
            if [[ "$codename" == *"begonia"* ]]; then
                ADB_SERIAL="$dev"
                break
            fi
        done
        if [[ -z "${ADB_SERIAL:-}" ]]; then
            ADB_SERIAL=$(echo "$devices" | head -n 1 | awk '{print $1}')
        fi
    fi
    log_pass "Connected to device: $ADB_SERIAL"

    # Detect Root status
    log_info "Detecting root privilege on device..."
    local root_id
    root_id=$(adb -s "$ADB_SERIAL" shell "su -c id" 2>/dev/null || true)
    if [[ "$root_id" == *"uid=0(root)"* ]]; then
        IS_ROOTED=true
        log_pass "Root access verified: KernelPatch / APatch / Magisk active (uid=0)"
    else
        IS_ROOTED=false
        log_warn "Device is NOT rooted or SU was denied. Operating in Non-Root mode."
    fi

    # Read system metadata efficiently by batching into a single adb shell invocation
    # This prevents the ~100-300ms overhead of multiple ADB calls
    local sys_info
    sys_info=$(adb -s "$ADB_SERIAL" shell "echo \"\$(getprop ro.product.model)\"; echo \"\$(getprop ro.product.device)\"; echo \"\$(uname -r)\"; echo \"\$(getprop ro.build.version.release)\"; echo \"\$(getprop ro.build.id)\"" 2>/dev/null | tr -d '\r')

    DEVICE_MODEL=$(echo "$sys_info" | sed -n '1p')
    DEVICE_NAME=$(echo "$sys_info" | sed -n '2p')
    KERNEL_RELEASE=$(echo "$sys_info" | sed -n '3p')
    ANDROID_VERSION=$(echo "$sys_info" | sed -n '4p')
    BUILD_ID=$(echo "$sys_info" | sed -n '5p')

    log_info "Target Model:   $DEVICE_MODEL ($DEVICE_NAME)"
    log_info "Kernel Release: $KERNEL_RELEASE"
    log_info "Android OS:     $ANDROID_VERSION (Build $BUILD_ID)"
    return 0
}

# Export collected metrics to a comprehensive JSON file
export_results_json() {
    local outfile="$1"
    mkdir -p "$(dirname "$outfile")"

    local entries=()
    for k in "${METRIC_KEYS[@]}"; do
        entries+=("${METRIC_MAP[$k]}")
    done

    local metrics_body
    metrics_body=$(IFS=,; echo "${entries[*]}")

    cat <<JSON_EOF > "$outfile"
{
  "benchmark_suite": "pox-begonia-kernel-benchmark",
  "version": "1.0.0",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "device": {
    "serial": "${ADB_SERIAL:-unknown}",
    "model": "${DEVICE_MODEL:-unknown}",
    "codename": "${DEVICE_NAME:-begonia}",
    "kernel": "${KERNEL_RELEASE:-unknown}",
    "android_version": "${ANDROID_VERSION:-unknown}",
    "build_id": "${BUILD_ID:-unknown}",
    "is_rooted": ${IS_ROOTED:-false},
    "run_mode": "${RUN_MODE:-auto}"
  },
  "metrics": [
$metrics_body
  ]
}
JSON_EOF
    log_pass "Results successfully saved to: $outfile"
}
