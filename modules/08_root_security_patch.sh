#!/usr/bin/env bash
#
# modules/08_root_security_patch.sh - FolkPatch / APatch / KSU-Next & Branch Isolation
#

run_root_security_patch_module() {
    log_header "MODULE 8: ROOT HOOK INTEGRITY & STRICT BRANCH ISOLATION"

    local uname_r
    uname_r=$(adb_cmd shell "uname -r" 2>/dev/null | tr -d '\r\n')

    # 1. Detect Branch Edition
    local is_apatch_branch=0
    local is_ksu_branch=0
    local is_sultan_branch=0

    if [[ "$uname_r" == *"APatch"* || "$uname_r" == *"apatch"* ]]; then
        is_apatch_branch=1
        log_info "Active Edition: APatch Edition (FolkPatch integrated)"
    elif [[ "$uname_r" == *"KSU"* || "$uname_r" == *"ksu"* ]]; then
        is_ksu_branch=1
        log_info "Active Edition: KernelSU-Next Edition"
    else
        log_info "Active Edition: Standard / Clean Unrooted Edition"
    fi

    if [[ "$uname_r" == *"Sultan"* || "$uname_r" == *"sultan"* ]]; then
        is_sultan_branch=1
        log_info "Active Edition: Sultan Debloat Edition"
    fi

    # 2. Check Root Hook State
    local root_detected=0
    if [[ "${IS_ROOTED:-false}" == "true" ]]; then
        root_detected=1
        log_pass "Superuser (uid=0) confirmed via active root provider"
    else
        log_info "System is running unrooted or SU is ungranted"
    fi
    record_metric "security" "sec_root_active" "Root Provider Active" "$root_detected" "bool" true

    # 3. Check SELinux Enforcing Status
    local selinux_mode
    selinux_mode=$(adb_cmd shell "getenforce 2>/dev/null || echo 'Unknown'" | tr -d '\r\n')
    log_info "SELinux Operating Mode: $selinux_mode"
    local selinux_enforcing=0
    if [[ "$selinux_mode" == "Enforcing" ]]; then
        selinux_enforcing=1
        log_pass "SELinux is in Enforcing mode (Full Android security policies enabled)"
    fi
    record_metric "security" "sec_selinux_enforcing" "SELinux Enforcing Mode" "$selinux_enforcing" "bool" true
}
