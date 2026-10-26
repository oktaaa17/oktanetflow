#!/usr/bin/env bash
# ==============================================================================
# Script Name   : web-latency-profiler.sh
# Version       : Beta Version
# Author        : Oktaa (Oktanetflow)
# Copyright     : Copyright © 2026 Oktanetflow
# Website       : https://oktanetflow.vercel.app/
# Execution     : bash <(curl -fsSL https://oktanetflow.vercel.app/infra/linux/labs/bash/web-latency-profiler.sh)
# ==============================================================================
set -euo pipefail

# ANSI color codes for terminal rendering
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

BRAND_HEADER="Beta Version | Copyright © 2026 Oktanetflow\nDocs & Lab: https://oktanetflow.vercel.app/"

# Check controlling tty
if [ ! -t 0 ] && [ ! -e /dev/tty ]; then
    echo -e "${RED}[ERROR]${NC} Controlling terminal (/dev/tty) is required for interactive mode." >&2
    exit 1
fi

# Detect TUI Dialog Engine
GUI_TOOL=""
if command -v whiptail >/dev/null 2>&1; then
    GUI_TOOL="whiptail"
elif command -v dialog >/dev/null 2>&1; then
    GUI_TOOL="dialog"
fi

prompt_input() {
    local title="$1"
    local prompt_msg="$2"
    local default_val="$3"
    local output=""

    if [[ -n "$GUI_TOOL" ]]; then
        output=$($GUI_TOOL --title "$title" --backtitle "Oktanetflow Infra Lab Tool" --inputbox "${prompt_msg}\n\n[Oktanetflow Profiler Engine]" 12 70 "$default_val" 3>&1 1>&2 2>&3 < /dev/tty) || exit 0
    else
        echo -e "${CYAN}=== Oktanetflow Web Latency Profiler ===${NC}" >&2
        echo -e "${prompt_msg}" >&2
        read -r -p "[$default_val]: " output < /dev/tty
        output="${output:-$default_val}"
    fi
    echo "$output"
}

show_message() {
    local title="$1"
    local content="$2"
    if [[ -n "$GUI_TOOL" ]]; then
        $GUI_TOOL --title "$title" --backtitle "Oktanetflow Infra Lab Tool" --msgbox "$content" 24 78 < /dev/tty
    else
        echo -e "\n${BOLD}======================================================${NC}"
        echo -e "${CYAN}${BRAND_HEADER}${NC}"
        echo -e "${BOLD}======================================================${NC}"
        echo -e "\n${BOLD}=== $title ===${NC}\n$content\n"
    fi
}

# 1. Interactive Inputs via GUI
DOMAIN=$(prompt_input "Step 1/3: Target Domain" "Enter target domain (without https://):" "")
RESOLVE_IP=$(prompt_input "Step 2/3: Resolve IP" "Enter Direct Server/VPS IPv4 (Bypasses Cloudflare/CDN):" "")
STATIC_URI=$(prompt_input "Step 3/3: Static Test Path" "Enter static file path for baseline comparison:" "")

# Sanitize inputs
DOMAIN="${DOMAIN#https://}"
DOMAIN="${DOMAIN#http://}"
DOMAIN="${DOMAIN%%/*}"
STATIC_URI="/${STATIC_URI#/}"

# 2. Benchmark Engine
measure_endpoint() {
    local path="$1"
    local target_url="https://${DOMAIN}${path}"

    curl -s -k -o /dev/null \
      --resolve "${DOMAIN}:443:${RESOLVE_IP}" \
      -w "%{http_code}|%{time_connect}|%{time_appconnect}|%{time_starttransfer}|%{time_total}" \
      "${target_url}"
}

calculate_delta() {
    local raw_metrics="$1"
    IFS="|" read -r HTTP_CODE T_CONN T_APP T_START T_TOT <<< "$raw_metrics"

    awk -v code="$HTTP_CODE" \
        -v t_conn="$T_CONN" \
        -v t_app="$T_APP" \
        -v t_start="$T_START" \
        -v t_tot="$T_TOT" '
    BEGIN {
        tcp_latency = t_conn;
        tls_handshake = (t_app > t_conn) ? (t_app - t_conn) : 0;
        app_processing = (t_start > t_app) ? (t_start - t_app) : 0;
        transfer_time = (t_tot > t_start) ? (t_tot - t_start) : 0;

        printf "%s|%.4f|%.4f|%.4f|%.4f|%.4f", code, tcp_latency, tls_handshake, app_processing, transfer_time, t_tot;
    }'
}

# Run diagnostics
RAW_DYNAMIC=$(measure_endpoint "/")
IFS="|" read -r D_HTTP D_TCP D_TLS D_PROC D_TRANS D_TOT <<< "$(calculate_delta "$RAW_DYNAMIC")"

RAW_STATIC=$(measure_endpoint "$STATIC_URI")
IFS="|" read -r S_HTTP S_TCP S_TLS S_PROC S_TRANS S_TOT <<< "$(calculate_delta "$RAW_STATIC")"

# 3. Decision Matrix
ANALYSIS=""
IS_CODEBASE_ISSUE=$(awk -v d_proc="$D_PROC" -v s_proc="$S_PROC" 'BEGIN {print ((d_proc > 1.0) && (s_proc < 0.2)) ? 1 : 0}')
IS_NETWORK_ISSUE=$(awk -v tcp="$D_TCP" 'BEGIN {print (tcp > 0.3) ? 1 : 0}')
IS_CPU_OR_SSL_ISSUE=$(awk -v tls="$D_TLS" 'BEGIN {print (tls > 0.5) ? 1 : 0}')

if [[ "$IS_CODEBASE_ISSUE" -eq 1 ]]; then
    ANALYSIS="[VONIS]: BOTTLENECK CODEBASE / DATABASE
-> Dynamic Processing: ${D_PROC}s vs Static Processing: ${S_PROC}s.
-> Web server & network normal. Aplikasi PHP/MySQL membutuhkan optimasi (slow query, opcache, atau queue)."
elif [[ "$IS_NETWORK_ISSUE" -eq 1 ]]; then
    ANALYSIS="[VONIS]: BOTTLENECK NETWORK / ISP / ROUTING
-> TCP Connect Time tinggi (${D_TCP}s).
-> Masalah ada pada rute transit BGP, uplink VPS, atau mitigasi DDoS jaringan."
elif [[ "$IS_CPU_OR_SSL_ISSUE" -eq 1 ]]; then
    ANALYSIS="[VONIS]: BOTTLENECK CPU VPS / WEB SERVER HANDSHAKE
-> TLS Handshake (${D_TLS}s) tinggi.
-> Periksa CPU steal, load average VPS, atau worker connection limit di Nginx/Apache."
else
    ANALYSIS="[VONIS]: INFRASTRUKTUR & CODEBASE SEHAT
-> Semua metrik latency berada di bawah ambang batas kritis."
fi

# 4. Formatted Report with Creator Watermark
REPORT=$(cat <<EOF
Target: https://${DOMAIN} -> (${RESOLVE_IP})

--- DYNAMIC ROUTE [/] (Status: ${D_HTTP}) ---
  - TCP Connect (Network)     : ${D_TCP}s
  - TLS Handshake (SSL/CPU)   : ${D_TLS}s
  - App Engine / TTFB (Code)  : ${D_PROC}s
  - Data Transfer Time        : ${D_TRANS}s
  - Total Request Time        : ${D_TOT}s

--- STATIC ROUTE [${STATIC_URI}] (Status: ${S_HTTP}) ---
  - App Engine / TTFB         : ${S_PROC}s
  - Total Request Time        : ${S_TOT}s

-------------------------------------------------------------
DIAGNOSTIC CONCLUSION:
${ANALYSIS}

-------------------------------------------------------------
Beta Version | Copyright © 2026 Oktanetflow
Docs & Lab   : https://oktanetflow.vercel.app/
EOF
)

# Output rendering
show_message "Oktanetflow Latency Profiler" "$REPORT"
