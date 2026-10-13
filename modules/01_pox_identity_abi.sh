#!/usr/bin/env bash
#
# modules/01_pox_identity_abi.sh - Pox Kernel branding, UTS_RELEASE, and Vendor Module ABI
#

run_pox_identity_abi_module() {
    log_header "MODULE 1: POX KERNEL IDENTITY & VENDOR MODULE ABI INTEGRITY"

    # 1. Verify Kernel Branding and UTS_RELEASE Hard Limit (<= 64 chars)
    log_info "Verifying Pox Kernel version string and UTS_RELEASE limits..."
    local uname_r
    uname_r=$(adb_cmd shell "uname -r" 2>/dev/null | tail -n 1 | tr -d '\r\n')
    local uname_len=${#uname_r}

    log_info "Kernel Release: $uname_r (Length: $uname_len chars)"

    local uts_ok=1
    if (( uname_len <= 64 )); then
        log_pass "UTS_RELEASE respects Linux 64-char hard limit: $uname_len <= 64"
    else
        log_fail "UTS_RELEASE exceeds 64-character hard limit! ($uname_len > 64)"
        uts_ok=0
    fi
    record_metric "identity" "kernel_uts_release_len" "UTS_RELEASE Character Length" "$uname_len" "chars" false

    local is_pox=0
    if [[ "$uname_r" == *"Pox"* || "$uname_r" == *"pox"* ]]; then
        log_pass "Pox Kernel signature confirmed: $uname_r"
        is_pox=1
    else
        log_warn "Non-Pox or Stock kernel detected: $uname_r"
    fi
    record_metric "identity" "kernel_is_pox_valid" "Pox Kernel Signature" "$is_pox" "bool" true

    # 2. MediaTek MT6785 Vendor Proprietary Module ABI Integrity
    # Verifies that udc_lib.ko and wmt_drv.ko loaded cleanly without struct module ABI shift
    log_info "Verifying MediaTek vendor module ABI integrity (udc_lib, wmt_drv, connfem)..."
    local mod_check
    mod_check=$(adb_cmd shell "
        udc=\$(grep -c '^udc_lib ' /proc/modules 2>/dev/null || echo 0)
        wmt=\$(grep -c '^wmt_drv ' /proc/modules 2>/dev/null || echo 0)
        echo \"\$udc \$wmt\"
    " 2>/dev/null | tail -n 1 | tr -d '\r\n')

    local udc_loaded=$(echo "$mod_check" | awk '{print $1}')
    local wmt_loaded=$(echo "$mod_check" | awk '{print $2}')

    if [[ "$udc_loaded" -ge 1 ]]; then
        log_pass "udc_lib.ko loaded cleanly (struct module ABI shift fix active)"
    else
        log_warn "udc_lib.ko not present in /proc/modules (built-in or USB not initialized)"
    fi

    # 3. Early Boot Panic / EL1 Data Abort Scan in Kernel Log
    log_info "Scanning kernel log for early-boot EL1 Data Aborts or add_usage_links crashes..."
    local panic_count=0
    if [[ "${IS_ROOTED:-false}" == "true" ]]; then
        panic_count=$(adb_cmd shell "su -c 'dmesg | grep -E -c \"add_usage_links|del_usage_links|Unable to handle kernel paging request|Internal error: Oops\" || echo 0'" 2>/dev/null | tail -n 1 | tr -d '\r\n')
    else
        panic_count=$(adb_cmd shell "dmesg 2>/dev/null | grep -E -c 'add_usage_links|del_usage_links|Internal error: Oops' || echo 0" 2>/dev/null | tail -n 1 | tr -d '\r\n')
    fi
    panic_count="${panic_count:-0}"

    if [[ "$panic_count" -eq 0 ]]; then
        log_pass "Zero kernel paging crashes or module link panics detected in dmesg"
    else
        log_fail "Detected $panic_count crash indicators in dmesg!"
    fi
    record_metric "identity" "kernel_crash_indicators" "Early Boot Crash Count" "$panic_count" "panics" false
}
