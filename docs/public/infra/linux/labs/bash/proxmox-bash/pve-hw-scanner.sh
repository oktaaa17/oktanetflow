#!/usr/bin/env bash
# ==============================================================================
# Script Name   : pve-hw-scanner.sh
# Version       : Beta Version
# Author        : Dimas Oktavian Ramadhan (Oktanetflow)
# Copyright     : Copyright © 2026 Oktanetflow
# Website       : https://oktanetflow.vercel.app/
# Execution     : bash <(curl -fsSL https://oktanetflow.vercel.app/infra/linux/labs/bash/pve-hw-scanner.sh)
# ==============================================================================
set -euo pipefail

# ANSI color codes for terminal rendering
BOLD='\033[1m'
NC='\033[0m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'

BRAND_HEADER="Beta Version | Copyright © 2026 Oktanetflow\nDocs & Lab: https://oktanetflow.vercel.app/"

# Check root privilege
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] This inventory scanner must be executed as root.${NC}" >&2
    exit 1
fi

print_header() {
    local title="$1"
    echo -e "\n${BOLD}${BLUE}======================================================================${NC}"
    echo -e "${BOLD}${CYAN}  ${title}${NC}"
    echo -e "${BOLD}${BLUE}======================================================================${NC}"
}

print_subheader() {
    local subtitle="$1"
    echo -e "\n${BOLD}${YELLOW}--> ${subtitle}${NC}"
}

# Initial Brand Banner
echo -e "${BOLD}${BLUE}======================================================================${NC}"
echo -e "${CYAN}        OKTANETFLOW PROXMOX HARDWARE & INVENTORY PROFILER             ${NC}"
echo -e "${CYAN}${BRAND_HEADER}${NC}"
echo -e "${BOLD}${BLUE}======================================================================${NC}"
echo -e "Audit Timestamp : $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo -e "Scanned Node    : $(hostname -f 2>/dev/null || hostname)"

# ------------------------------------------------------------------------------
# 1. HOST & CHASSIS IDENTIFICATION
# ------------------------------------------------------------------------------
print_header "1. SYSTEM & CHASSIS INFORMATION"

SYS_MANUFACTURER=$(dmidecode -s system-manufacturer 2>/dev/null || echo "Unknown")
SYS_PRODUCT=$(dmidecode -s system-product-name 2>/dev/null || echo "Unknown")
SYS_VERSION=$(dmidecode -s system-version 2>/dev/null || echo "N/A")
SYS_SERIAL=$(dmidecode -s system-serial-number 2>/dev/null || echo "Unknown")
SYS_UUID=$(dmidecode -s system-uuid 2>/dev/null || echo "Unknown")
BOARD_NAME=$(dmidecode -s baseboard-product-name 2>/dev/null || echo "Unknown")
BIOS_VERSION=$(dmidecode -s bios-version 2>/dev/null || echo "Unknown")
BIOS_DATE=$(dmidecode -s bios-release-date 2>/dev/null || echo "Unknown")

printf "%-24s: ${GREEN}%s${NC}\n" "Brand / Manufacturer" "${SYS_MANUFACTURER}"
printf "%-24s: ${GREEN}%s (Model Version: %s)${NC}\n" "Product / Model" "${SYS_PRODUCT}" "${SYS_VERSION}"
printf "%-24s: ${BOLD}${GREEN}%s${NC}\n" "Serial Number (S/N)" "${SYS_SERIAL}"
printf "%-24s: %s\n" "Motherboard Model" "${BOARD_NAME}"
printf "%-24s: %s\n" "System UUID" "${SYS_UUID}"
printf "%-24s: %s (Released: %s)\n" "BIOS Version" "${BIOS_VERSION}" "${BIOS_DATE}"

# Check for IPMI / BMC (iDRAC, iLO, BMC IP)
if command -v ipmitool >/dev/null 2>&1; then
    BMC_IP=$(ipmitool lan print 1 2>/dev/null | awk -F': ' '/IP Address[ \t]*:/{print $2}' | xargs || true)
    [[ -n "${BMC_IP}" ]] && printf "%-24s: ${CYAN}%s${NC}\n" "Out-of-Band (BMC/iDRAC)" "${BMC_IP}"
fi

# ------------------------------------------------------------------------------
# 2. PROXMOX VE ENVIRONMENT
# ------------------------------------------------------------------------------
print_header "2. PROXMOX OS & KERNEL ENVIRONMENT"

if command -v pveversion >/dev/null 2>&1; then
    printf "%-24s: %s\n" "PVE Manager Version" "$(pveversion)"
fi
printf "%-24s: %s\n" "Kernel Release" "$(uname -r)"
printf "%-24s: %s\n" "Uptime" "$(uptime -p)"

# ------------------------------------------------------------------------------
# 3. CPU TOPOLOGY & SPECS
# ------------------------------------------------------------------------------
print_header "3. CPU SPECIFICATIONS"

CPU_MODEL=$(lscpu | grep "Model name:" | sed 's/Model name:[ \t]*//' | head -n 1)
CPU_SOCKETS=$(lscpu | grep "Socket(s):" | awk '{print $2}')
CPU_CORES_PER_SOCKET=$(lscpu | grep "Core(s) per socket:" | awk '{print $4}')
CPU_THREADS_PER_CORE=$(lscpu | grep "Thread(s) per core:" | awk '{print $4}')
CPU_TOTAL_THREADS=$(lscpu | grep "CPU(s):" | head -n 1 | awk '{print $2}')
CPU_VIRT=$(lscpu | grep "Virtualization:" | awk '{print $2}' || echo "None")

printf "%-24s: ${GREEN}%s${NC}\n" "CPU Architecture" "${CPU_MODEL}"
printf "%-24s: %s socket(s) | %s cores/socket | %s threads/core\n" "Physical Sockets" "${CPU_SOCKETS}" "${CPU_CORES_PER_SOCKET}" "${CPU_THREADS_PER_CORE}"
printf "%-24s: %s vCPUs / Logic Threads\n" "Total Processing Units" "${CPU_TOTAL_THREADS}"
printf "%-24s: %s\n" "Hardware Virtualization" "${CPU_VIRT}"

# ------------------------------------------------------------------------------
# 4. RAM ARCHITECTURE & DIMM BREAKDOWN
# ------------------------------------------------------------------------------
print_header "4. MEMORY TOPOLOGY (RAM)"

RAM_TOTAL=$(free -h --si | awk '/Mem:/ {print $2}')
RAM_MAX_CAPACITY=$(dmidecode -t 16 2>/dev/null | awk -F': ' '/Maximum Capacity:/{print $2}' | head -n 1 | xargs)
RAM_SLOT_COUNT=$(dmidecode -t 16 2>/dev/null | awk -F': ' '/Number Of Devices:/{print $2}' | head -n 1 | xargs)
RAM_POPULATED=$(dmidecode -t 17 2>/dev/null | grep -E "^\s*Size:" | grep -iv "No Module Installed" | wc -l)

printf "%-24s: ${BOLD}${GREEN}%s${NC} (System Total Usable: %s)\n" "Populated DIMM Slots" "${RAM_POPULATED} / ${RAM_SLOT_COUNT} slots" "${RAM_TOTAL}"
printf "%-24s: %s\n" "Motherboard Max Cap" "${RAM_MAX_CAPACITY}"

print_subheader "Detailed Physical Memory Devices (dmidecode Type 17)"
printf "%-18s | %-12s | %-10s | %-16s | %-20s | %-12s | %-14s\n" \
    "Slot Locator" "Size" "Form" "Manufacturer" "Part Number" "Rated Speed" "Config Speed"
echo "-------------------|--------------|------------|------------------|----------------------|--------------|---------------"

dmidecode -t 17 2>/dev/null | awk '
BEGIN {
    locator="N/A"; size="N/A"; type="N/A"; mfg="N/A"; part="N/A"; speed="N/A"; cfg_speed="N/A";
}
/^\s*Locator:/ { locator=$2 }
/^\s*Size:/ { $1=""; size=$0; gsub(/^[ \t]+/, "", size) }
/^\s*Type:/ && !/Type Detail:/ { type=$2 }
/^\s*Manufacturer:/ { $1=""; mfg=$0; gsub(/^[ \t]+/, "", mfg) }
/^\s*Part Number:/ { $1=""; part=$0; gsub(/^[ \t]+/, "", part) }
/^\s*Speed:/ && !/Configured/ { $1=""; speed=$0; gsub(/^[ \t]+/, "", speed) }
/^\s*Configured Memory Speed:/ { $1=""; $2=""; $3=""; cfg_speed=$0; gsub(/^[ \t]+/, "", cfg_speed) }
/^Handle/ && locator != "N/A" {
    if (size !~ /No Module/ && size != "N/A" && size != "") {
        printf "%-18s | %-12s | %-10s | %-16s | %-20s | %-12s | %-14s\n", locator, size, type, substr(mfg,1,16), substr(part,1,20), speed, cfg_speed;
    } else if (size ~ /No Module/) {
        printf "%-18s | %-12s | %-10s | %-16s | %-20s | %-12s | %-14s\n", locator, "[Empty Slot]", "-", "-", "-", "-", "-";
    }
    locator="N/A"; size="N/A"; type="N/A"; mfg="N/A"; part="N/A"; speed="N/A"; cfg_speed="N/A";
}
END {
    if (size !~ /No Module/ && size != "N/A" && size != "") {
        printf "%-18s | %-12s | %-10s | %-16s | %-20s | %-12s | %-14s\n", locator, size, type, substr(mfg,1,16), substr(part,1,20), speed, cfg_speed;
    } else if (size ~ /No Module/) {
        printf "%-18s | %-12s | %-10s | %-16s | %-20s | %-12s | %-14s\n", locator, "[Empty Slot]", "-", "-", "-", "-", "-";
    }
}'

# ------------------------------------------------------------------------------
# 5. STORAGE CONTROLLER & PHYSICAL DRIVES
# ------------------------------------------------------------------------------
print_header "5. STORAGE SUBSYSTEM & DISK INVENTORY"

print_subheader "Storage & RAID Controllers (PCIe / Onboard)"
lspci -nn | grep -iE 'raid|storage|nvme|sata|sas|scsi' | while read -r line; do
    echo "  - ${line}"
done

# Enterprise Hardware RAID CLI Utility Check (Dell PERC / MegaRAID)
if command -v perccli64 >/dev/null 2>&1 || command -v perccli >/dev/null 2>&1 || command -v storcli >/dev/null 2>&1; then
    RAID_TOOL=$(command -v perccli64 || command -v perccli || command -v storcli)
    print_subheader "Hardware RAID Controller Virtual Drives (${RAID_TOOL})"
    ${RAID_TOOL} /c0 /vcall show 2>/dev/null | grep -E "^[0-9]+/[0-9]+|^VD" || true
fi

print_subheader "Block Devices, Media Type, Capacity & Serial Numbers"
printf "%-10s %-8s %-10s %-20s %-22s %-10s %-12s\n" \
    "NAME" "TYPE" "SIZE" "VENDOR/MODEL" "SERIAL" "ROTA (SSD/HDD)" "TRAN"
echo "--------------------------------------------------------------------------------------------------------"

lsblk -d -o NAME,TYPE,SIZE,MODEL,SERIAL,ROTA,TRAN -e 7,11 --noheadings | while read -r name type size model serial rota tran; do
    local_rota="HDD"
    [[ "${rota}" == "0" ]] && local_rota="SSD/NVMe"

    printf "%-10s %-8s %-10s %-20s %-22s %-10s %-12s\n" \
        "/dev/${name}" "${type}" "${size}" "${model:-Unknown}" "${serial:-N/A}" "${local_rota}" "${tran:-Internal}"
done

# Check SMART Health if smartctl exists
if command -v smartctl >/dev/null 2>&1; then
    print_subheader "SMART Health Status"
    for dev in $(lsblk -d -n -o NAME -e 7,11); do
        DEV_PATH="/dev/${dev}"
        HEALTH=$(smartctl -H "${DEV_PATH}" 2>/dev/null | grep -i "test result" | awk -F': ' '{print $2}' || echo "SMART Unsupported or RAID pass-through required")
        echo -e "  - ${DEV_PATH}: ${GREEN}${HEALTH}${NC}"
    done
fi

# ------------------------------------------------------------------------------
# 6. NETWORK INTERFACES & PCI CONTROLLERS
# ------------------------------------------------------------------------------
print_header "6. NETWORK INTERFACES & MAC ADDRESSES"

printf "%-14s | %-18s | %-10s | %-12s | %-24s\n" "Interface" "MAC Address" "State" "Speed" "Driver"
echo "---------------|--------------------|------------|--------------|-------------------------"

for iface in $(ls /sys/class/net | grep -vE 'lo|veth|fwpr|fwbr|qbr|qvb|qvo|tap'); do
    MAC=$(cat /sys/class/net/"${iface}"/address 2>/dev/null || echo "N/A")
    OPERSTATE=$(cat /sys/class/net/"${iface}"/operstate 2>/dev/null || echo "Unknown")
    SPEED="N/A"
    [[ -f /sys/class/net/"${iface}"/speed ]] && SPEED="$(cat /sys/class/net/"${iface}"/speed 2>/dev/null) Mbps" || true
    DRIVER=$(basename "$(readlink /sys/class/net/"${iface}"/device/driver 2>/dev/null || echo 'N/A')")

    printf "%-14s | %-18s | %-10s | %-12s | %-24s\n" \
        "${iface}" "${MAC}" "${OPERSTATE}" "${SPEED}" "${DRIVER}"
done

# ------------------------------------------------------------------------------
# FOOTER & OKTANETFLOW WATERMARK
# ------------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${BLUE}======================================================================${NC}"
echo -e "${GREEN}Scan completed successfully.${NC}"
echo -e "${BOLD}${BLUE}----------------------------------------------------------------------${NC}"
echo -e "${CYAN}${BRAND_HEADER}${NC}"
echo -e "${BOLD}${BLUE}======================================================================${NC}"
