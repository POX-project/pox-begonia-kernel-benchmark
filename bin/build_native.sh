#!/usr/bin/env bash
#
# bin/build_native.sh - Builds native AArch64 C nostdlib microbenchmarks
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
OUT_DIR="$SCRIPT_DIR"

CLANG_BIN="/mnt/9f4d8733-a954-435d-b92f-f33c068c3b1e/begoker/kerdevdep/clang/bin/clang"

if [[ -x "$CLANG_BIN" ]]; then
    CC_CMD="$CLANG_BIN -target aarch64-linux-gnu -fuse-ld=lld -nostdlib -static -O3"
elif command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
    CC_CMD="aarch64-linux-gnu-gcc -nostdlib -static -O3"
else
    echo "[!] No AArch64 cross-compiler found on host."
    exit 1
fi

echo "[*] Compiling AArch64 native microbenchmarks with: $CC_CMD"
$CC_CMD "$SRC_DIR/ctx_switch_arm64.c" -o "$OUT_DIR/ctx_switch"
$CC_CMD "$SRC_DIR/mem_bw_arm64.c"     -o "$OUT_DIR/mem_bw"
$CC_CMD "$SRC_DIR/page_fault_arm64.c" -o "$OUT_DIR/page_fault"
$CC_CMD "$SRC_DIR/io_sync_arm64.c"    -o "$OUT_DIR/io_sync"
$CC_CMD "$SRC_DIR/fork_bench_arm64.c" -o "$OUT_DIR/fork_bench"

chmod +x "$OUT_DIR"/ctx_switch "$OUT_DIR"/mem_bw "$OUT_DIR"/page_fault "$OUT_DIR"/io_sync "$OUT_DIR"/fork_bench
echo "[+] All native microbenchmarks compiled successfully in $OUT_DIR"
