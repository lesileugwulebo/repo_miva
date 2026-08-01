#!/usr/bin/env bash
set -euo pipefail

echo "==========================================================="
echo "   AWS-Azure Multi-Cloud Performance Test Suite"
echo "==========================================================="

RESULTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/results"
mkdir -p "$RESULTS_DIR"

echo "timestamp,direction,run,packets_sent,packets_received,loss_pct,min_rtt_ms,avg_rtt_ms,max_rtt_ms" > "${RESULTS_DIR}/ping-results.csv"

echo "[+] CSV Results directory prepared at: ${RESULTS_DIR}"
echo "[+] Execute ping and iperf3 commands from test nodes and append output to CSV."
