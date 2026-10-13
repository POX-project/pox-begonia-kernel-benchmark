#!/usr/bin/env python3
"""
analyze_regression.py - Pox Begonia Kernel Regression Analysis & Scoring Engine

Compares current benchmark results against a golden baseline, computes subsystem
deltas (Δ%), identifies regressions/gains, and calculates the Composite Pox Score.
Tailored specifically for Pox Kernel Begonia (Redmi Note 8 Pro / MT6785).
"""

import sys
import os
import json
import argparse
from typing import Dict, Any, List, Tuple

# ANSI Terminal Colors
CLR_RESET = "\033[0m"
CLR_BOLD = "\033[1m"
CLR_RED = "\033[1;31m"
CLR_GREEN = "\033[1;32m"
CLR_YELLOW = "\033[1;33m"
CLR_CYAN = "\033[1;36m"
CLR_BLUE = "\033[1;34m"
CLR_GRAY = "\033[0;90m"

def load_json(filepath: str) -> Dict[str, Any]:
    if not os.path.isfile(filepath):
        print(f"{CLR_RED}[-] File not found: {filepath}{CLR_RESET}")
        sys.exit(1)
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def calculate_metric_delta(key: str, cur_val: float, base_val: float, unit: str, higher_is_better: bool) -> Tuple[float, str, str]:
    # Special handling for UTS_RELEASE length (Linux 64-character hard limit)
    if key == "kernel_uts_release_len":
        if cur_val <= 64:
            return 0.0, "⚖️ STABLE", CLR_GREEN
        else:
            return -100.0, "🔻 REGRESSED (>64)", CLR_RED

    # Special handling for Boolean metrics
    if unit == "bool":
        if cur_val == base_val:
            return 0.0, "⚖️ STABLE", CLR_YELLOW
        elif cur_val > base_val:
            return 100.0, "🚀 GAINED", CLR_GREEN
        else:
            return -100.0, "🔻 REGRESSED", CLR_RED

    if base_val == 0:
        if cur_val > 0:
            return 100.0, "🚀 GAINED", CLR_GREEN
        return 0.0, "⚖️ STABLE", CLR_GRAY

    # Raw mathematical change
    raw_delta_pct = ((cur_val - base_val) / base_val) * 100.0

    # Effective performance improvement percentage
    perf_delta_pct = raw_delta_pct if higher_is_better else -raw_delta_pct

    if perf_delta_pct >= 5.0:
        return perf_delta_pct, "🚀 GAINED", CLR_GREEN
    elif perf_delta_pct <= -5.0:
        return perf_delta_pct, "🔻 REGRESSED", CLR_RED
    else:
        return perf_delta_pct, "⚖️ STABLE", CLR_YELLOW

def compute_composite_pox_score(metrics_diff: List[Dict[str, Any]]) -> float:
    """
    Computes Composite Pox Score (0 - 1000) normalized against baseline (500 pts = baseline parity)
    """
    weights = {
        "identity": 0.05,
        "sched": 0.25,
        "memory": 0.20,
        "storage": 0.15,
        "power": 0.10,
        "thermal": 0.10,
        "graphics": 0.10,
        "crypto": 0.03,
        "security": 0.02
    }

    category_deltas: Dict[str, List[float]] = {}
    for item in metrics_diff:
        cat = item["category"]
        category_deltas.setdefault(cat, []).append(item["perf_delta_pct"])

    total_weighted_gain = 0.0
    total_weight = 0.0

    for cat, weight in weights.items():
        if cat in category_deltas:
            avg_gain = sum(category_deltas[cat]) / len(category_deltas[cat])
            total_weighted_gain += avg_gain * weight
            total_weight += weight

    if total_weight > 0:
        composite_gain_pct = total_weighted_gain / total_weight
    else:
        composite_gain_pct = 0.0

    # 500 = baseline (parity), each +1% improvement = +5 pts, clamped to [0, 1000]
    score = 500.0 + (composite_gain_pct * 8.0)
    return max(0.0, min(1000.0, score))

def generate_markdown_report(current_data: Dict[str, Any], baseline_data: Dict[str, Any],
                             diff_results: List[Dict[str, Any]], score: float, outfile: str):
    dev_cur = current_data.get("device", {})
    dev_base = baseline_data.get("device", {})

    regressed_count = sum(1 for d in diff_results if "REGRESSED" in d["status"])
    gained_count = sum(1 for d in diff_results if "GAINED" in d["status"])
    stable_count = sum(1 for d in diff_results if "STABLE" in d["status"])

    overall_status = "✅ PROGRESSING UP (PASSED)" if regressed_count == 0 and score >= 500 else "⚠️ REGRESSIONS DETECTED"

    with open(outfile, 'w', encoding='utf-8') as f:
        f.write("# ⚡ Pox Begonia Kernel Benchmark Regression Report\n\n")
        f.write(f"**Overall Verdict:** {overall_status}  \n")
        f.write(f"**Composite Pox Score:** `{score:.1f} / 1000`  \n\n")

        f.write("## 📱 Test Environments\n\n")
        f.write("| Attribute | Current Build | Baseline Reference |\n")
        f.write("| :--- | :--- | :--- |\n")
        f.write(f"| **Device** | `{dev_cur.get('model', 'Unknown')} ({dev_cur.get('codename', 'begonia')})` | `{dev_base.get('model', 'Unknown')} ({dev_base.get('codename', 'begonia')})` |\n")
        f.write(f"| **Kernel** | `{dev_cur.get('kernel', 'Unknown')}` | `{dev_base.get('kernel', 'Unknown')}` |\n")
        f.write(f"| **Android** | `Android {dev_cur.get('android_version', 'Unknown')} ({dev_cur.get('build_id', '')})` | `Android {dev_base.get('android_version', 'Unknown')} ({dev_base.get('build_id', '')})` |\n")
        f.write(f"| **Execution Mode** | `{dev_cur.get('run_mode', 'auto')} (Root: {dev_cur.get('is_rooted', False)})` | `{dev_base.get('run_mode', 'auto')} (Root: {dev_base.get('is_rooted', False)})` |\n\n")

        f.write("## 📊 Subsystem Verification & Regression Matrix\n\n")
        f.write("| Subsystem | Metric Name | Baseline | Current | Δ % | Status |\n")
        f.write("| :--- | :--- | :---: | :---: | :---: | :---: |\n")

        for item in diff_results:
            cat = item["category"].upper()
            status_badge = item["status"]
            sign = "+" if item["perf_delta_pct"] >= 0 else ""
            delta_str = f"`{sign}{item['perf_delta_pct']:.1f}%`"

            f.write(f"| **{cat}** | {item['name']} | `{item['base_val']} {item['unit']}` | `{item['cur_val']} {item['unit']}` | {delta_str} | {status_badge} |\n")

        f.write("\n## 📈 Executive Summary\n\n")
        f.write(f"- 🚀 **Gains / Improvements:** `{gained_count}` metrics\n")
        f.write(f"- ⚖️ **Stable Metrics:** `{stable_count}` metrics\n")
        f.write(f"- 🔻 **Regressions Detected:** `{regressed_count}` metrics\n\n")

        if regressed_count > 0:
            f.write("> [!WARNING]\n")
            f.write("> The build failed verification quality gates due to detected subsystem regressions. Review commits before releasing.\n")
        else:
            f.write("> [!TIP]\n")
            f.write("> Kernel performance, stability, and power efficiency strictly progressed UP with zero regressions across verified subsystems!\n")

def main():
    parser = argparse.ArgumentParser(description="Pox Begonia Kernel Benchmark Regression Analyzer")
    parser.add_argument("--current", "-c", required=True, help="Path to current run JSON")
    parser.add_argument("--baseline", "-b", required=True, help="Path to baseline reference JSON")
    parser.add_argument("--output-md", "-o", default="", help="Path to output markdown report")
    args = parser.parse_args()

    cur_data = load_json(args.current)
    base_data = load_json(args.baseline)

    base_map = {m["key"]: m for m in base_data.get("metrics", [])}
    diff_results: List[Dict[str, Any]] = []

    print(f"\n{CLR_CYAN}{CLR_BOLD}═══════════════════════════════════════════════════════════════════════════════════{CLR_RESET}")
    print(f"{CLR_CYAN}{CLR_BOLD}   POX BEGONIA KERNEL REGRESSION ANALYSIS & VERIFICATION REPORT{CLR_RESET}")
    print(f"{CLR_CYAN}{CLR_BOLD}═══════════════════════════════════════════════════════════════════════════════════{CLR_RESET}\n")

    print(f"Current:  {CLR_BOLD}{cur_data.get('device',{}).get('kernel','Unknown')}{CLR_RESET}")
    print(f"Baseline: {CLR_GRAY}{base_data.get('device',{}).get('kernel','Unknown')}{CLR_RESET}\n")

    header_fmt = "  {:<10} {:<32} {:>12} {:>12} {:>10}   {:<12}"
    print(header_fmt.format("CATEGORY", "METRIC", "BASELINE", "CURRENT", "DELTA %", "STATUS"))
    print("  " + "─" * 85)

    row_fmt = "  {:<10} {:<32} {:>12} {:>12} {:>10}   {}"

    for m in cur_data.get("metrics", []):
        key = m["key"]
        cat = m.get("category", "gen")
        name = m.get("name", key)
        cur_val = float(m.get("value", 0.0))
        unit = m.get("unit", "")
        higher_is_better = m.get("higher_is_better", True)

        if key in base_map:
            base_val = float(base_map[key].get("value", 0.0))
        else:
            base_val = cur_val

        perf_delta_pct, status_str, color = calculate_metric_delta(key, cur_val, base_val, unit, higher_is_better)

        diff_results.append({
            "key": key,
            "category": cat,
            "name": name,
            "cur_val": cur_val,
            "base_val": base_val,
            "unit": unit,
            "perf_delta_pct": perf_delta_pct,
            "status": status_str,
            "higher_is_better": higher_is_better
        })

        sign = "+" if perf_delta_pct >= 0 else ""
        delta_display = f"{sign}{perf_delta_pct:.1f}%"
        cur_display = f"{cur_val} {unit}"
        base_display = f"{base_val} {unit}"

        colored_status = f"{color}{status_str}{CLR_RESET}"
        print(row_fmt.format(cat.upper(), name[:32], base_display, cur_display, delta_display, colored_status))

    score = compute_composite_pox_score(diff_results)
    regressed_count = sum(1 for d in diff_results if "REGRESSED" in d["status"])
    gained_count = sum(1 for d in diff_results if "GAINED" in d["status"])

    print("  " + "─" * 85)
    print(f"\n  {CLR_BOLD}Composite Pox Kernel Score:{CLR_RESET} {CLR_CYAN}{CLR_BOLD}{score:.1f} / 1000{CLR_RESET}")
    print(f"  {CLR_GREEN}Gains: {gained_count}{CLR_RESET} | {CLR_RED}Regressions: {regressed_count}{CLR_RESET}")

    if regressed_count == 0 and score >= 500:
        print(f"\n  {CLR_GREEN}{CLR_BOLD}VERDICT: PASSED [PROGRESSING UP - ZERO REGRESSIONS]{CLR_RESET}\n")
    else:
        print(f"\n  {CLR_RED}{CLR_BOLD}VERDICT: ATTENTION REQUIRED [REGRESSIONS DETECTED]{CLR_RESET}\n")

    if args.output_md:
        generate_markdown_report(cur_data, base_data, diff_results, score, args.output_md)
        print(f"{CLR_BLUE}[*]{CLR_RESET} Markdown report generated at: {args.output_md}")

if __name__ == "__main__":
    main()
