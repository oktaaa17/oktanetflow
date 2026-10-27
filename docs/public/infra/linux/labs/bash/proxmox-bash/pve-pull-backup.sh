#!/usr/bin/env bash
# ==============================================================================
# Script Name   : pull_backup.sh
# Version       : Beta Version
# Author        : Dimas Oktavian Ramadhan (Oktanetflow)
# Copyright     : Copyright © 2026 Oktanetflow
# Website       : https://oktanetflow.vercel.app/
# Execution     : bash <(curl -fsSL https://oktanetflow.vercel.app/infra/linux/labs/bash/pull_backup.sh)
# ==============================================================================
set -euo pipefail

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

BRAND_HEADER="Beta Version | Copyright © 2026 Oktanetflow\nDocs & Lab: https://oktanetflow.vercel.app/"

# Ensure terminal interaction exists for curl execution
if [ ! -t 0 ] && [ ! -e /dev/tty ]; then
    echo -e "${RED}[ERROR]${NC} Controlling terminal (/dev/tty) is required for interactive mode." >&2
    exit 1
fi

# Detect TUI Dialog Engine (whiptail or dialog)
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
        output=$($GUI_TOOL --title "$title" --backtitle "Oktanetflow Infra Lab Tool" --inputbox "${prompt_msg}\n\n[Oktanetflow Proxmox Backup Engine]" 13 72 "$default_val" 3>&1 1>&2 2>&3 < /dev/tty) || exit 0
    else
        echo -e "${CYAN}=== Oktanetflow Backup Pull Tool ===${NC}" >&2
        echo -e "${prompt_msg}" >&2
        read -r -p "[$default_val]: " output < /dev/tty
        output="${output:-$default_val}"
    fi
    echo "$output"
}

prompt_yesno() {
    local title="$1"
    local prompt_msg="$2"

    if [[ -n "$GUI_TOOL" ]]; then
        if $GUI_TOOL --title "$title" --backtitle "Oktanetflow Infra Lab Tool" --yesno "${prompt_msg}" 12 72 < /dev/tty; then
            return 0
        else
            return 1
        fi
    else
        echo -e "${YELLOW}${prompt_msg} [y/N]:${NC}" >&2
        local ans=""
        read -r ans < /dev/tty
        [[ "${ans,,}" =~ ^(y|yes)$ ]] && return 0 || return 1
    fi
}

show_message() {
    local title="$1"
    local content="$2"
    if [[ -n "$GUI_TOOL" ]]; then
        $GUI_TOOL --title "$title" --backtitle "Oktanetflow Infra Lab Tool" --msgbox "$content" 22 76 < /dev/tty
    else
        echo -e "\n${BOLD}======================================================${NC}"
        echo -e "${CYAN}${BRAND_HEADER}${NC}"
        echo -e "${BOLD}======================================================${NC}"
        echo -e "\n${BOLD}=== $title ===${NC}\n$content\n"
    fi
}

# ------------------------------------------------------------------------------
# 1. Interactive Inputs via TUI / Terminal
# ------------------------------------------------------------------------------
REMOTE_HOST=$(prompt_input "Step 1/6: Remote Source Host" \
    "Enter Remote Proxmox / Tachibana Hostname or IPv4:" \
    "103.187.106.11")

REMOTE_USER=$(prompt_input "Step 2/6: Remote SSH User" \
    "Enter SSH user on the remote server:" \
    "root")

REMOTE_DIR=$(prompt_input "Step 3/6: Source Directory" \
    "Enter remote backup storage directory path:" \
    "/var/lib/vz/dump")

LOCAL_DIR=$(prompt_input "Step 4/6: Destination Directory" \
    "Enter local storage path where backups will be saved:" \
    "/var/lib/vz/dump")

TODAY_EXAMPLE=$(date '+%Y_%m_%d')
TARGET_DATE=$(prompt_input "Step 5/6: Target Date Filter" \
    "Filter by date format (e.g., ${TODAY_EXAMPLE} or 2026-10-24).\nLeave blank or '*' to pull ALL dates:" \
    "${TODAY_EXAMPLE}")

SPESIFIC_VMID=$(prompt_input "Step 6/6: VM / CT ID Filter" \
    "Specify VMID filter:\n- Single ID: 100\n- Comma-separated: 100,102,105\n- Range: 100-105\n- Mixed: 100,102-105,200\nLeave blank or '*' for ALL IDs:" \
    "")

# ------------------------------------------------------------------------------
# 2. Parse & Expand VMIDs
# ------------------------------------------------------------------------------
expand_vmids() {
    local raw="$1"
    raw="${raw// /}" # strip spaces

    if [[ -z "$raw" || "$raw" == "*" || "${raw,,}" == "all" ]]; then
        echo "ALL"
        return
    fi

    local -a parsed_ids=()
    IFS=',' read -ra SEGMENTS <<< "$raw"
    for item in "${SEGMENTS[@]}"; do
        if [[ "$item" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            local start="${BASH_REMATCH[1]}"
            local end="${BASH_REMATCH[2]}"
            if (( start <= end )); then
                for (( id=start; id<=end; id++ )); do parsed_ids+=("$id"); done
            else
                for (( id=start; id>=end; id-- )); do parsed_ids+=("$id"); done
            fi
        elif [[ "$item" =~ ^[0-9]+$ ]]; then
            parsed_ids+=("$item")
        fi
    done

    # Remove duplicates
    if [[ ${#parsed_ids[@]} -gt 0 ]]; then
        echo "${parsed_ids[@]}" | tr ' ' '\n' | sort -n -u | tr '\n' ' ' | xargs
    else
        echo "ALL"
    fi
}

RESOLVED_VMIDS=$(expand_vmids "$SPESIFIC_VMID")

# Sanitize Date input
DATE_TOKEN="${TARGET_DATE// /}"
[[ "$DATE_TOKEN" == "*" || "${DATE_TOKEN,,}" == "all" ]] && DATE_TOKEN=""

# ------------------------------------------------------------------------------
# 3. Build Rsync Filter Rules
# ------------------------------------------------------------------------------
RSYNC_FILTERS=()

DATE_SUBPATTERN=""
if [[ -n "$DATE_TOKEN" ]]; then
    DATE_SUBPATTERN="*${DATE_TOKEN}*"
else
    DATE_SUBPATTERN="*"
fi

if [[ "$RESOLVED_VMIDS" == "ALL" ]]; then
    RSYNC_FILTERS+=(--include="vzdump-*-${DATE_SUBPATTERN}")
else
    for vmid in $RESOLVED_VMIDS; do
        RSYNC_FILTERS+=(--include="vzdump-*-${vmid}-${DATE_SUBPATTERN}")
    done
fi

# Exclude any other file outside the criteria
RSYNC_FILTERS+=(--exclude="*")

# ------------------------------------------------------------------------------
# 4. Confirmation & Execution Plan
# ------------------------------------------------------------------------------
SUMMARY_MSG=$(cat <<EOF
Source      : ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/
Destination : ${LOCAL_DIR}/
Date Filter : ${DATE_TOKEN:-"(ALL DATES)"}
VMID Target : ${RESOLVED_VMIDS}

Do you want to start the rsync transfer now?
EOF
)

if ! prompt_yesno "Confirm Backup Pull Operation" "$SUMMARY_MSG"; then
    echo -e "${YELLOW}[*] Backup transfer cancelled by user.${NC}"
    exit 0
fi

# Ensure destination exists
mkdir -p "${LOCAL_DIR}"

clear
echo -e "${BOLD}${BLUE}======================================================================${NC}"
echo -e "${BOLD}${CYAN}  Oktanetflow Backup Engine | [$(date '+%Y-%m-%d %H:%M:%S')]${NC}"
echo -e "${BOLD}${BLUE}======================================================================${NC}"
echo -e "Pulling from : ${GREEN}${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/${NC}"
echo -e "Destination  : ${GREEN}${LOCAL_DIR}/${NC}"
echo -e "Date Filter  : ${YELLOW}${DATE_TOKEN:-"ALL"}${NC}"
echo -e "VMID Filter  : ${YELLOW}${RESOLVED_VMIDS}${NC}"
echo -e "${BOLD}${BLUE}----------------------------------------------------------------------${NC}"

# Execute Rsync
rsync -avhP \
    "${RSYNC_FILTERS[@]}" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" \
    "${LOCAL_DIR}/"

echo -e "\n${BOLD}${BLUE}======================================================================${NC}"
echo -e "${GREEN}[+] Backup pull process completed successfully.${NC}"
echo -e "${BOLD}${BLUE}======================================================================${NC}"

FINAL_REPORT=$(cat <<EOF
Transfer completed successfully at: $(date '+%Y-%m-%d %H:%M:%S')

Destination Directory:
$(ls -lh "${LOCAL_DIR}" | grep -E "vma|tar|log|notes" | tail -n 8 || true)

-------------------------------------------------------------
Beta Version | Copyright © 2026 Oktanetflow
Docs & Lab   : https://oktanetflow.vercel.app/
EOF
)

show_message "Transfer Complete" "$FINAL_REPORT"
