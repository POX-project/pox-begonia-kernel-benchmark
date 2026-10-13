#!/usr/bin/env bash
#
# harness/device_control.sh - Device governor, cache flushing, and thermal controls
#

set -u

DEVICE_WORK_DIR="/data/local/tmp/pox_bench"

setup_device_environment() {
    log_info "Preparing on-device staging environment at $DEVICE_WORK_DIR..."
    adb_cmd shell "mkdir -p $DEVICE_WORK_DIR/bin $DEVICE_WORK_DIR/tmp"
    if [ -d "$SCRIPT_DIR/bin" ]; then
        log_info "Deploying native ARM64 microbenchmark binaries to device..."
        for bin in "$SCRIPT_DIR"/bin/*; do
            if [ -f "$bin" ] && [ -x "$bin" ] && [[ "$bin" != *.sh ]]; then
                adb_cmd push "$bin" "$DEVICE_WORK_DIR/bin/" >/dev/null 2>&1 || true
            fi
        done
        adb_cmd shell "chmod +x $DEVICE_WORK_DIR/bin/* 2>/dev/null || true"
    fi
}

cleanup_device_environment() {
    log_info "Cleaning up temporary benchmark files on device..."
    adb_cmd shell "rm -rf $DEVICE_WORK_DIR/tmp/* 2>/dev/null || true"
}

lock_cpu_frequencies() {
    if [[ "${IS_ROOTED:-false}" == "true" ]]; then
        log_info "Root enabled: Engaging performance governor to eliminate frequency scaling noise..."
        adb_cmd shell "su -c '
            mkdir -p $DEVICE_WORK_DIR
            for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                if [ -f \"\$gov\" ]; then
                    cat \"\$gov\" >> $DEVICE_WORK_DIR/gov_backup.txt
                    echo performance > \"\$gov\" 2>/dev/null || true
                fi
            done
            # Ensure Pox gaming profile is active for maximum throughput
            if [ -f /proc/perfmgr/gaming_mode ]; then
                echo 1 > /proc/perfmgr/gaming_mode 2>/dev/null || true
            fi
        '"
    else
        log_warn "Non-Root mode: Cannot lock CPU governors. Benchmarks will run under active interactive/schedplus governor."
    fi
}

restore_cpu_frequencies() {
    if [[ "${IS_ROOTED:-false}" == "true" ]]; then
        log_info "Restoring standard CPU governors..."
        adb_cmd shell "su -c '
            for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                if [ -f \"\$gov\" ]; then
                    echo schedplus > \"\$gov\" 2>/dev/null || echo schedutil > \"\$gov\" 2>/dev/null || true
                fi
            done
            rm -f $DEVICE_WORK_DIR/gov_backup.txt 2>/dev/null || true
        '"
    fi
}

flush_caches() {
    if [[ "${IS_ROOTED:-false}" == "true" ]]; then
        adb_cmd shell "su -c 'sync && echo 3 > /proc/sys/vm/drop_caches'"
    else
        # In non-root mode, perform a large sequential user-space read to displace cache
        adb_cmd shell "dd if=/dev/urandom of=/data/local/tmp/pox_bench/tmp/evict.bin bs=1M count=32 2>/dev/null && rm -f /data/local/tmp/pox_bench/tmp/evict.bin 2>/dev/null || true"
    fi
}

get_thermal_snapshot() {
    local max_temp
    max_temp=$(device_exec "
        max=0
        for tz in /sys/class/thermal/thermal_zone*/temp; do
            if [ -f \"\$tz\" ]; then
                t=\$(cat \"\$tz\" 2>/dev/null || echo 0)
                if [ \"\$t\" -gt \"\$max\" ] && [ \"\$t\" -lt 120000 ]; then max=\$t; fi
            fi
        done
        if [ \"\$max\" -gt 1000 ]; then
            awk -v t=\"\$max\" 'BEGIN {printf \"%.1f\", t / 1000}'
        else
            awk -v t=\"\$max\" 'BEGIN {printf \"%.1f\", t}'
        fi
    " 2>/dev/null | tail -n 1 | tr -d '\r\n')
    echo "${max_temp:-38.0}"
}

get_power_snapshot() {
    device_exec "
        cur=\$(cat /sys/class/power_supply/battery/current_now 2>/dev/null || echo 0)
        volt=\$(cat /sys/class/power_supply/battery/voltage_now 2>/dev/null || echo 0)
        ctype=\$(cat /sys/class/power_supply/battery/charge_type 2>/dev/null || cat /sys/class/power_supply/battery/status 2>/dev/null || echo 'Unknown')
        echo \"\$cur \$volt \$ctype\"
    " 2>/dev/null | tail -n 1 | tr -d '\r'
}
