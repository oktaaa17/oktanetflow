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
export LC_ALL=C

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

trim_str() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "${s}"
}

dmi_val() {
    local key="$1"
    local default="${2:-Unknown}"
    local val=""
    if command -v dmidecode >/dev/null 2>&1; then
        val=$(dmidecode -s "${key}" 2>/dev/null | awk '!/^#/ && NF { gsub(/^[ \t]+|[ \t]+$/, ""); print; exit }' || true)
    fi
    echo "${val:-${default}}"
}

format_disk_capacity() {
    local bytes="$1"
    awk -v b="${bytes}" 'BEGIN {
        if (b <= 0) { print "0 GB"; exit }
        gb = b / 1000000000
        if (gb >= 100)       si = sprintf("%.0f GB", gb)
        else if (gb >= 10)   si = sprintf("%.1f GB", gb)
        else                 si = sprintf("%.2f GB", gb)

        if (b >= 1099511627776) bin = sprintf("%.2f TiB", b / 1099511627776)
        else                    bin = sprintf("%.1f GiB", b / 1073741824)

        printf "%s (%s)", si, bin
    }'
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

SYS_MANUFACTURER=$(dmi_val "system-manufacturer")
SYS_PRODUCT=$(dmi_val "system-product-name")
SYS_VERSION=$(dmi_val "system-version" "N/A")
SYS_SERIAL=$(dmi_val "system-serial-number")
SYS_UUID=$(dmi_val "system-uuid")
BOARD_NAME=$(dmi_val "baseboard-product-name")
BOARD_SERIAL=$(dmi_val "baseboard-serial-number" "N/A")
BIOS_VERSION=$(dmi_val "bios-version")
BIOS_DATE=$(dmi_val "bios-release-date")

printf "%-24s: ${GREEN}%s${NC}\n" "Brand / Manufacturer" "${SYS_MANUFACTURER}"
printf "%-24s: ${GREEN}%s (Model Version: %s)${NC}\n" "Product / Model" "${SYS_PRODUCT}" "${SYS_VERSION}"
printf "%-24s: ${BOLD}${GREEN}%s${NC}\n" "Serial Number (S/N)" "${SYS_SERIAL}"
printf "%-24s: %s (S/N: %s)\n" "Motherboard Model" "${BOARD_NAME}" "${BOARD_SERIAL}"
printf "%-24s: %s\n" "System UUID" "${SYS_UUID}"
printf "%-24s: %s (Released: %s)\n" "BIOS Version" "${BIOS_VERSION}" "${BIOS_DATE}"

# Check for IPMI / BMC (iDRAC, iLO, BMC IP)
if command -v ipmitool >/dev/null 2>&1; then
    BMC_IP=$( (ipmitool lan print 1 2>/dev/null || ipmitool lan print 2>/dev/null) | awk -F':' '/^IP Address[ \t]*:/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' || true)
    if [[ -n "${BMC_IP}" && "${BMC_IP}" != "0.0.0.0" ]]; then
        printf "%-24s: ${CYAN}%s${NC}\n" "Out-of-Band (BMC/iDRAC)" "${BMC_IP}"
    fi
fi

# ------------------------------------------------------------------------------
# 2. PROXMOX VE ENVIRONMENT
# ------------------------------------------------------------------------------
print_header "2. PROXMOX OS & KERNEL ENVIRONMENT"

if command -v pveversion >/dev/null 2>&1; then
    printf "%-24s: %s\n" "PVE Manager Version" "$(pveversion)"
elif [[ -r /etc/os-release ]]; then
    OS_NAME=$(awk -F'=' '/^PRETTY_NAME=/{gsub(/"/, "", $2); print $2; exit}' /etc/os-release || echo "Linux")
    printf "%-24s: %s\n" "OS Distribution" "${OS_NAME}"
fi
printf "%-24s: %s\n" "Kernel Release" "$(uname -r)"
printf "%-24s: %s\n" "Uptime" "$(uptime -p 2>/dev/null || uptime)"

# ------------------------------------------------------------------------------
# 3. CPU TOPOLOGY & SPECS
# ------------------------------------------------------------------------------
print_header "3. CPU SPECIFICATIONS"

LSCPU_OUT=$(lscpu 2>/dev/null || true)
CPU_MODEL=$(awk -F':' '/^Model name:/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' <<< "${LSCPU_OUT}")
CPU_SOCKETS=$(awk -F':' '/^Socket\(s\):/{gsub(/[ \t]+/, "", $2); print $2; exit}' <<< "${LSCPU_OUT}")
CPU_CORES_PER_SOCKET=$(awk -F':' '/^Core\(s\) per socket:/{gsub(/[ \t]+/, "", $2); print $2; exit}' <<< "${LSCPU_OUT}")
CPU_THREADS_PER_CORE=$(awk -F':' '/^Thread\(s\) per core:/{gsub(/[ \t]+/, "", $2); print $2; exit}' <<< "${LSCPU_OUT}")
CPU_TOTAL_THREADS=$(awk -F':' '/^CPU\(s\):/{gsub(/[ \t]+/, "", $2); print $2; exit}' <<< "${LSCPU_OUT}")
CPU_VIRT=$(awk -F':' '/^Virtualization:/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' <<< "${LSCPU_OUT}")

printf "%-24s: ${GREEN}%s${NC}\n" "CPU Architecture" "${CPU_MODEL:-Unknown}"
printf "%-24s: %s socket(s) | %s cores/socket | %s threads/core\n" "Physical Sockets" "${CPU_SOCKETS:-N/A}" "${CPU_CORES_PER_SOCKET:-N/A}" "${CPU_THREADS_PER_CORE:-N/A}"
printf "%-24s: %s vCPUs / Logic Threads\n" "Total Processing Units" "${CPU_TOTAL_THREADS:-N/A}"
printf "%-24s: %s\n" "Hardware Virtualization" "${CPU_VIRT:-None}"

print_subheader "Detailed Physical Processors & Serial Numbers (dmidecode Type 4 / PPIN)"

# Collect Hardware CPU PPIN per physical package (Linux 5.18+ Intel Xeon / AMD EPYC)
declare -A PKG_PPIN=()
for cpu_dir in /sys/devices/system/cpu/cpu[0-9]*; do
    [[ -d "${cpu_dir}/topology" ]] || continue
    pkg_id=$(cat "${cpu_dir}/topology/physical_package_id" 2>/dev/null | tr -d '[:space:]' || true)
    pkg_id="${pkg_id:-0}"
    if [[ -z "${PKG_PPIN[$pkg_id]:-}" ]]; then
        ppin_raw=$(cat "${cpu_dir}/topology/ppin" 2>/dev/null | tr -d '[:space:]' || true)
        PKG_PPIN[$pkg_id]="${ppin_raw:-N/A}"
    fi
done

PPIN_LIST=""
if [[ ${#PKG_PPIN[@]} -gt 0 ]]; then
    while IFS= read -r pkg_id; do
        [[ -z "${pkg_id}" ]] && continue
        if [[ -n "${PPIN_LIST}" ]]; then
            PPIN_LIST="${PPIN_LIST}|${PKG_PPIN[$pkg_id]}"
        else
            PPIN_LIST="${PKG_PPIN[$pkg_id]}"
        fi
    done < <(printf '%s\n' "${!PKG_PPIN[@]}" | sort -n)
fi

printf "%-14s | %-18s | %-23s | %-22s | %-20s\n" \
    "Socket" "Status" "Processor ID (CPUID)" "Serial Number (S/N)" "Hardware PPIN"
echo "---------------|--------------------|-------------------------|------------------------|---------------------"

DMI_CPU_OUT=""
if command -v dmidecode >/dev/null 2>&1; then
    DMI_CPU_OUT=$(dmidecode -t 4 2>/dev/null || true)
fi

if grep -q "DMI type 4," <<< "${DMI_CPU_OUT}"; then
    awk -v ppin_list="${PPIN_LIST}" '
    BEGIN {
        n_ppin = split(ppin_list, ppins, "|")
        pop_idx = 0
        in_block = 0
    }
    function trim(s) {
        sub(/^[^:]*:[ \t]*/, "", s)
        sub(/[ \t]+$/, "", s)
        return (s == "" ? "N/A" : s)
    }
    function flush_cpu() {
        if (!in_block) return
        if (status ~ /[Uu]npopulated/) {
            printf "%-14s | %-18s | %-23s | %-22s | %-20s\n", \
                substr(sock,1,14), "[Empty Socket]", "-", "-", "-"
        } else {
            pop_idx++
            ppin = (pop_idx <= n_ppin && ppins[pop_idx] != "") ? ppins[pop_idx] : "N/A"
            printf "%-14s | %-18s | %-23s | %-22s | %-20s\n", \
                substr(sock,1,14), substr(status,1,18), substr(cpuid,1,23), substr(sn,1,22), substr(ppin,1,20)
        }
    }
    /^Handle .*DMI type 4,/ {
        flush_cpu()
        in_block = 1
        sock="N/A"; status="Unknown"; cpuid="N/A"; sn="N/A"
        next
    }
    in_block && /^[ \t]*Socket Designation:/ { sock = trim($0); next }
    in_block && /^[ \t]*Status:/             { status = trim($0); next }
    in_block && /^[ \t]*ID:/                 { cpuid = trim($0); next }
    in_block && /^[ \t]*Serial Number:/      { sn = trim($0); next }
    END { flush_cpu() }
    ' <<< "${DMI_CPU_OUT}"
else
    CPUINFO_SN=$(awk -F':' '/^Serial[ \t]*:/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' /proc/cpuinfo 2>/dev/null || true)
    FIRST_PPIN=$(awk -F'|' '{print $1}' <<< "${PPIN_LIST}")
    printf "%-14s | %-18s | %-23s | %-22s | %-20s\n" \
        "CPU0" "Populated" "N/A (No SMBIOS T4)" "${CPUINFO_SN:-Not Available}" "${FIRST_PPIN:-N/A}"
fi

# ------------------------------------------------------------------------------
# 4. RAM ARCHITECTURE & DIMM BREAKDOWN
# ------------------------------------------------------------------------------
print_header "4. MEMORY TOPOLOGY (RAM)"

RAM_TOTAL=$(free -h --si | awk '/^Mem:/ {print $2}')

DMI_MEM_ARRAY=""
DMI_MEM_DEV=""
if command -v dmidecode >/dev/null 2>&1; then
    DMI_MEM_ARRAY=$(dmidecode -t 16 2>/dev/null || true)
    DMI_MEM_DEV=$(dmidecode -t 17 2>/dev/null || true)
fi

RAM_MAX_CAPACITY=$(awk -F':' '
    /^[ \t]*Maximum Capacity:/ {
        val = $2; gsub(/^[ \t]+|[ \t]+$/, "", val)
        if (val != "" && val != "Unknown") {
            count++
            split(val, p, /[ \t]+/)
            if (count == 1) { unit = p[2]; sum = p[1] + 0; first = val }
            else if (p[2] == unit) { sum += p[1] + 0 }
            else { mixed = 1 }
        }
    }
    END {
        if (count == 0) print "Unknown"
        else if (count == 1) print first
        else if (!mixed && unit != "") printf "%g %s (%d arrays)\n", sum, unit, count
        else printf "%s (%d arrays)\n", first, count
    }
' <<< "${DMI_MEM_ARRAY}")

RAM_ECC=$(awk -F':' '/^[ \t]*Error Correction Type:/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' <<< "${DMI_MEM_ARRAY}")
RAM_SLOT_COUNT=$(awk -F':' '/^[ \t]*Number Of Devices:/{sum += ($2 + 0)} END {print sum + 0}' <<< "${DMI_MEM_ARRAY}")
if [[ "${RAM_SLOT_COUNT}" -eq 0 ]]; then
    RAM_SLOT_COUNT=$(awk '/^Handle .*DMI type 17,/{c++} END {print c + 0}' <<< "${DMI_MEM_DEV}")
fi

RAM_POPULATED=$(awk '
    /^[ \t]*Size:/ {
        val = $0; sub(/^[^:]*:[ \t]*/, "", val); sub(/[ \t]+$/, "", val)
        if (val != "" && val !~ /[Nn]o [Mm]odule/ && val != "Unknown" && val !~ /^0[ \t]/) c++
    }
    END { print c + 0 }
' <<< "${DMI_MEM_DEV}")

printf "%-24s: ${BOLD}${GREEN}%s${NC} (System Total Usable: %s)\n" "Populated DIMM Slots" "${RAM_POPULATED} / ${RAM_SLOT_COUNT} slots" "${RAM_TOTAL:-Unknown}"
printf "%-24s: %s\n" "Motherboard Max Cap" "${RAM_MAX_CAPACITY:-Unknown}"
printf "%-24s: %s\n" "Error Correction (ECC)" "${RAM_ECC:-Unknown}"

print_subheader "Detailed Physical Memory Devices & Serial Numbers (dmidecode Type 17)"
printf "%-15s | %-12s | %-6s | %-14s | %-20s | %-18s | %-11s | %-12s\n" \
    "Slot Locator" "Size" "Type" "Manufacturer" "Part Number" "Serial Number" "Rated Speed" "Config Speed"
echo "----------------|--------------|--------|----------------|----------------------|--------------------|-------------|-------------"

if grep -q "DMI type 17," <<< "${DMI_MEM_DEV}"; then
    awk '
    BEGIN { in_block = 0 }
    function trim(s) {
        sub(/^[^:]*:[ \t]*/, "", s)
        sub(/[ \t]+$/, "", s)
        return (s == "" ? "N/A" : s)
    }
    function flush_dimm() {
        if (!in_block) return
        if (size !~ /[Nn]o [Mm]odule/ && size != "N/A" && size != "Unknown" && size != "") {
            if (size ~ /^[0-9]+[ \t]+MB$/) {
                mb = size + 0
                if (mb >= 1024 && mb % 1024 == 0) size = (mb / 1024) " GB"
            }
            printf "%-15s | %-12s | %-6s | %-14s | %-20s | %-18s | %-11s | %-12s\n", \
                substr(locator,1,15), substr(size,1,12), substr(type,1,6), \
                substr(mfg,1,14), substr(part,1,20), substr(sn,1,18), \
                substr(speed,1,11), substr(cfg_speed,1,12)
        } else {
            printf "%-15s | %-12s | %-6s | %-14s | %-20s | %-18s | %-11s | %-12s\n", \
                substr(locator,1,15), "[Empty Slot]", "-", "-", "-", "-", "-", "-"
        }
    }
    /^Handle .*DMI type 17,/ {
        flush_dimm()
        in_block = 1
        locator="N/A"; size="N/A"; type="N/A"; mfg="N/A"; part="N/A"; sn="N/A"; speed="N/A"; cfg_speed="N/A"
        next
    }
    in_block && /^[ \t]*Locator:/                         { locator = trim($0); next }
    in_block && /^[ \t]*Size:/                            { size = trim($0); next }
    in_block && /^[ \t]*Type:/ && !/Type Detail:/         { type = trim($0); next }
    in_block && /^[ \t]*Manufacturer:/                    { mfg = trim($0); next }
    in_block && /^[ \t]*Part Number:/                     { part = trim($0); next }
    in_block && /^[ \t]*Serial Number:/                   { sn = trim($0); next }
    in_block && /^[ \t]*Speed:/                           { speed = trim($0); next }
    in_block && /^[ \t]*Configured (Memory|Clock) Speed:/ { cfg_speed = trim($0); next }
    END { flush_dimm() }
    ' <<< "${DMI_MEM_DEV}"
else
    echo "  No SMBIOS Type 17 memory device entries available."
fi

# ------------------------------------------------------------------------------
# 5. STORAGE CONTROLLER & PHYSICAL DRIVES
# ------------------------------------------------------------------------------
print_header "5. STORAGE SUBSYSTEM & DISK INVENTORY"

print_subheader "Storage & RAID Controllers (PCIe / Onboard)"
if command -v lspci >/dev/null 2>&1; then
    STORAGE_CTRLS=$(lspci -nn 2>/dev/null | grep -iE 'raid|storage|nvme|sata|sas|scsi|ahci|ide' || true)
    if [[ -n "${STORAGE_CTRLS}" ]]; then
        while IFS= read -r line; do
            echo "  - ${line}"
        done <<< "${STORAGE_CTRLS}"
    else
        echo "  - None detected"
    fi
else
    echo "  - lspci not installed (pciutils)"
fi

# Enterprise Hardware RAID CLI Utility Check (Dell PERC / LSI MegaRAID)
RAID_TOOL=$(command -v perccli64 || command -v perccli || command -v storcli64 || command -v storcli || true)
if [[ -n "${RAID_TOOL}" ]]; then
    print_subheader "Hardware RAID Controller Virtual Drives (${RAID_TOOL})"
    "${RAID_TOOL}" /call /vall show 2>/dev/null | grep -E "^[0-9]+/[0-9]+|^DG/VD" || echo "  No virtual drives reported."

    print_subheader "Hardware RAID Physical Drives & Serial Numbers (${RAID_TOOL})"
    printf "%-12s | %-7s | %-6s | %-5s | %-12s | %-24s | %-22s\n" \
        "Slot" "State" "Intf" "Media" "Capacity" "Model" "Serial Number (S/N)"
    echo "-------------|---------|--------|-------|--------------|--------------------------|-----------------------"

    "${RAID_TOOL}" /call /eall /sall show all 2>/dev/null | awk '
        BEGIN { in_drv = 0 }
        function trim(s) {
            sub(/^[^=]*=[ \t]*/, "", s)
            sub(/[ \t]+$/, "", s)
            return (s == "" ? "N/A" : s)
        }
        function flush_drv() {
            if (!in_drv) return
            cap = (raw_size != "" ? raw_size : size)
            printf "%-12s | %-7s | %-6s | %-5s | %-12s | %-24s | %s\n", \
                substr(slot,1,12), substr(state,1,7), substr(intf,1,6), substr(med,1,5), \
                substr(cap,1,12), substr(model,1,24), sn
        }
        /^Drive \/c[0-9]+(\/e[0-9]+)?\/s[0-9]+ :$/ {
            flush_drv()
            in_drv = 1
            slot = $2; state = "N/A"; intf = "N/A"; med = "N/A"; size = "N/A"; raw_size = ""; model = "N/A"; sn = "N/A"
            next
        }
        in_drv && /^[ \t]*[0-9]*:[0-9]+[ \t]+/ {
            state = $3
            size = $5 " " $6
            intf = $7
            med = $8
            next
        }
        in_drv && /^[ \t]*SN[ \t]*=/           { sn = trim($0); next }
        in_drv && /^[ \t]*Model Number[ \t]*=/ { model = trim($0); next }
        in_drv && /^[ \t]*Raw size[ \t]*=/ {
            raw_size = trim($0)
            sub(/[ \t]*\[.*$/, "", raw_size)
            next
        }
        END { flush_drv() }
    ' || true
fi

# Enterprise Hardware RAID CLI Utility Check (HPE Smart Array)
HPE_TOOL=$(command -v ssacli || command -v hpssacli || true)
if [[ -n "${HPE_TOOL}" ]]; then
    print_subheader "HPE Smart Array Physical Drives & Serial Numbers (${HPE_TOOL})"
    printf "%-14s | %-10s | %-12s | %-12s | %-22s | %-22s\n" \
        "Bay/Slot" "Status" "Interface" "Capacity" "Model" "Serial Number (S/N)"
    echo "---------------|------------|--------------|--------------|------------------------|-----------------------"

    "${HPE_TOOL}" ctrl all pd all show detail 2>/dev/null | awk '
        BEGIN { in_pd = 0 }
        function trim(s) {
            sub(/^[^:]*:[ \t]*/, "", s)
            sub(/[ \t]+$/, "", s)
            return (s == "" ? "N/A" : s)
        }
        function flush_pd() {
            if (!in_pd) return
            printf "%-14s | %-10s | %-12s | %-12s | %-22s | %s\n", \
                substr(slot,1,14), substr(status,1,10), substr(intf,1,12), \
                substr(size,1,12), substr(model,1,22), sn
        }
        /^[ \t]*physicaldrive / {
            flush_pd()
            in_pd = 1
            slot = $2; status = "N/A"; intf = "N/A"; size = "N/A"; model = "N/A"; sn = "N/A"
            next
        }
        in_pd && /^[ \t]*Status:/         { status = trim($0); next }
        in_pd && /^[ \t]*Interface Type:/ { intf = trim($0); next }
        in_pd && /^[ \t]*Size:/           { size = trim($0); next }
        in_pd && /^[ \t]*Model:/          { model = trim($0); next }
        in_pd && /^[ \t]*Serial Number:/  { sn = trim($0); next }
        END { flush_pd() }
    ' || true
fi

print_subheader "Block Devices, Interface, Capacity (GB) & Serial Numbers"
printf "%-13s | %-15s | %-9s | %-20s | %-26s | %-24s\n" \
    "DEVICE" "INTERFACE" "MEDIA" "CAPACITY (GB / GiB)" "MODEL" "SERIAL NUMBER (S/N)"
echo "--------------|-----------------|-----------|----------------------|----------------------------|-------------------------"

TOTAL_DISK_COUNT=0
TOTAL_DISK_BYTES=0
HAS_SMARTCTL=0
if command -v smartctl >/dev/null 2>&1; then
    HAS_SMARTCTL=1
fi

while read -r dev dtype _; do
    [[ -z "${dev}" || "${dtype}" != "disk" ]] && continue

    DEV_PATH="/dev/${dev}"
    BYTES=$(lsblk -dn -b -o SIZE "${DEV_PATH}" 2>/dev/null | tr -d '[:space:]' || true)
    if [[ ! "${BYTES}" =~ ^[0-9]+$ ]]; then
        BYTES=0
    fi

    TOTAL_DISK_COUNT=$(( TOTAL_DISK_COUNT + 1 ))
    TOTAL_DISK_BYTES=$(( TOTAL_DISK_BYTES + BYTES ))
    CAPACITY=$(format_disk_capacity "${BYTES}")

    # Collect udev & smartctl metadata once per disk
    UDEV_INFO=$(udevadm info --query=property --name="${DEV_PATH}" 2>/dev/null || true)
    SMART_INFO=""
    if [[ "${HAS_SMARTCTL}" -eq 1 ]]; then
        SMART_INFO=$(smartctl -i "${DEV_PATH}" 2>/dev/null || true)
    fi

    # 1. Interface / Transport (SATA, SAS, NVMe, USB, VirtIO, SCSI)
    TRAN_RAW=$(trim_str "$(lsblk -dn -o TRAN "${DEV_PATH}" 2>/dev/null || true)")
    if [[ -z "${TRAN_RAW}" ]]; then
        if [[ "${dev}" == nvme* ]]; then
            TRAN_RAW="nvme"
        elif [[ "${dev}" == vd* ]]; then
            TRAN_RAW="virtio"
        else
            TRAN_RAW=$(awk -F'=' '/^ID_BUS=/{print $2; exit}' <<< "${UDEV_INFO}")
        fi
    fi

    case "${TRAN_RAW,,}" in
        sata|ata) INTERFACE="SATA" ;;
        nvme)     INTERFACE="NVMe" ;;
        sas)      INTERFACE="SAS" ;;
        usb)      INTERFACE="USB" ;;
        iscsi)    INTERFACE="iSCSI" ;;
        fc)       INTERFACE="FC" ;;
        virtio)   INTERFACE="VirtIO" ;;
        scsi)     INTERFACE="SCSI" ;;
        mmc|sd)   INTERFACE="MMC/SD" ;;
        "")       INTERFACE="Internal" ;;
        *)        INTERFACE="${TRAN_RAW^^}" ;;
    esac

    # Enrich Interface with SATA link speed or SAS protocol via smartctl
    if [[ -n "${SMART_INFO}" ]]; then
        SATA_LINE=$(awk -F':' '/^SATA Version is:/{sub(/^[ \t]+/, "", $2); print $2; exit}' <<< "${SMART_INFO}")
        if [[ -n "${SATA_LINE}" ]]; then
            SATA_SPEED=$(awk '{
                if (match($0, /current:[ \t]*[0-9.]+[ \t]*Gb\/s/)) {
                    s = substr($0, RSTART, RLENGTH)
                    sub(/current:[ \t]*/, "", s)
                    gsub(/[ \t]+/, "", s)
                    print s
                } else if (match($0, /[0-9.]+[ \t]*Gb\/s/)) {
                    s = substr($0, RSTART, RLENGTH)
                    gsub(/[ \t]+/, "", s)
                    print s
                }
            }' <<< "${SATA_LINE}")
            if [[ -n "${SATA_SPEED}" ]]; then
                INTERFACE="SATA (${SATA_SPEED})"
            else
                INTERFACE="SATA"
            fi
        elif grep -qi "Transport protocol:.*SAS" <<< "${SMART_INFO}"; then
            INTERFACE="SAS"
        fi
    fi

    # 2. Media Type (SSD / NVMe SSD / HDD)
    ROTA=$(lsblk -dn -o ROTA "${DEV_PATH}" 2>/dev/null | tr -d '[:space:]' || true)
    if [[ "${INTERFACE}" == NVMe* ]]; then
        MEDIA="NVMe SSD"
    elif [[ "${ROTA}" == "0" ]]; then
        MEDIA="SSD"
    elif [[ "${ROTA}" == "1" ]]; then
        MEDIA="HDD"
    elif grep -qi "Solid State Device" <<< "${SMART_INFO}"; then
        MEDIA="SSD"
    elif grep -qi "rpm" <<< "${SMART_INFO}"; then
        MEDIA="HDD"
    else
        MEDIA="Unknown"
    fi

    # 3. Vendor & Model
    VENDOR=$(trim_str "$(lsblk -dn -o VENDOR "${DEV_PATH}" 2>/dev/null || true)")
    MODEL=$(trim_str "$(lsblk -dn -o MODEL "${DEV_PATH}" 2>/dev/null || true)")
    if [[ -z "${MODEL}" && -n "${SMART_INFO}" ]]; then
        MODEL=$(awk -F':' '/^(Device Model|Model Number|Product):/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' <<< "${SMART_INFO}")
    fi
    if [[ -n "${VENDOR}" && "${VENDOR^^}" != "ATA" && "${VENDOR^^}" != "NVME" ]]; then
        if [[ -z "${MODEL}" ]]; then
            MODEL="${VENDOR}"
        elif [[ "${MODEL,,}" != "${VENDOR,,}"* ]]; then
            MODEL="${VENDOR} ${MODEL}"
        fi
    fi
    MODEL="${MODEL:-Unknown}"

    # 4. Serial Number (Fallback chain: lsblk -> udevadm -> smartctl -> sysfs -> hdparm)
    SERIAL=$(trim_str "$(lsblk -dn -o SERIAL "${DEV_PATH}" 2>/dev/null || true)")
    if [[ -z "${SERIAL}" && -n "${UDEV_INFO}" ]]; then
        SERIAL=$(awk -F'=' '/^ID_SERIAL_SHORT=/{print $2; exit}' <<< "${UDEV_INFO}")
    fi
    if [[ -z "${SERIAL}" && -n "${SMART_INFO}" ]]; then
        SERIAL=$(awk -F':' '/^[ \t]*Serial [Nn]umber:/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' <<< "${SMART_INFO}")
    fi
    if [[ -z "${SERIAL}" && -r "/sys/block/${dev}/device/serial" ]]; then
        SERIAL=$(tr -d '[:space:]' < "/sys/block/${dev}/device/serial" 2>/dev/null || true)
    fi
    if [[ -z "${SERIAL}" && "${dev}" != nvme* ]] && command -v hdparm >/dev/null 2>&1; then
        SERIAL=$(hdparm -I "${DEV_PATH}" 2>/dev/null | awk -F':' '/Serial Number:/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' || true)
    fi
    SERIAL="${SERIAL:-N/A}"

    printf "%-13s | %-15s | %-9s | %-20s | %-26s | %s\n" \
        "${DEV_PATH}" "${INTERFACE:0:15}" "${MEDIA:0:9}" "${CAPACITY:0:20}" "${MODEL:0:26}" "${SERIAL}"
done < <(lsblk -dn -o NAME,TYPE -e 7,11 2>/dev/null || true)

if [[ "${TOTAL_DISK_COUNT}" -gt 0 ]]; then
    TOTAL_CAP_FMT=$(format_disk_capacity "${TOTAL_DISK_BYTES}")
    echo "--------------------------------------------------------------------------------------------------------------------------"
    printf "  Total Physical Disks: ${BOLD}${GREEN}%d${NC} | Total Raw Capacity: ${BOLD}${GREEN}%s${NC}\n" \
        "${TOTAL_DISK_COUNT}" "${TOTAL_CAP_FMT}"
else
    echo "  No block disk devices detected."
fi

# Check SMART Health if smartctl exists
if [[ "${HAS_SMARTCTL}" -eq 1 ]]; then
    print_subheader "SMART Health Status"
    while read -r dev dtype _; do
        [[ -z "${dev}" || "${dtype}" != "disk" ]] && continue
        DEV_PATH="/dev/${dev}"
        SMART_H=$(smartctl -H "${DEV_PATH}" 2>/dev/null || true)
        HEALTH=$(awk -F':' '
            /test result:|SMART Health Status:/ {
                sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit
            }
        ' <<< "${SMART_H}")

        TEMP=$(smartctl -A "${DEV_PATH}" 2>/dev/null | awk '
            /Temperature_Celsius|Airflow_Temperature_Cel/ && $10 ~ /^[0-9]+$/ { print $10 "°C"; exit }
            /^Temperature:[ \t]+[0-9]+/                   && $2 ~ /^[0-9]+$/  { print $2 "°C"; exit }
            /^Current Drive Temperature:/                 && $4 ~ /^[0-9]+$/  { print $4 "°C"; exit }
        ' || true)
        TEMP_STR=""
        if [[ -n "${TEMP}" ]]; then
            TEMP_STR=" (Temp: ${TEMP})"
        fi

        if [[ -z "${HEALTH}" ]]; then
            echo -e "  - ${DEV_PATH}: ${YELLOW}SMART Unsupported or RAID pass-through required${NC}"
        elif [[ "${HEALTH^^}" == *"PASSED"* || "${HEALTH^^}" == *"OK"* ]]; then
            echo -e "  - ${DEV_PATH}: ${GREEN}${HEALTH}${NC}${TEMP_STR}"
        else
            echo -e "  - ${DEV_PATH}: ${RED}${HEALTH}${NC}${TEMP_STR}"
        fi
    done < <(lsblk -dn -o NAME,TYPE -e 7,11 2>/dev/null || true)
fi

# ------------------------------------------------------------------------------
# 6. NETWORK INTERFACES & PCI CONTROLLERS
# ------------------------------------------------------------------------------
print_header "6. NETWORK INTERFACES & MAC ADDRESSES"

printf "%-14s | %-18s | %-10s | %-12s | %-24s\n" "Interface" "MAC Address" "State" "Speed" "Driver"
echo "---------------|--------------------|------------|--------------|-------------------------"

for net_path in /sys/class/net/*; do
    [[ -e "${net_path}" ]] || continue
    iface=$(basename "${net_path}")
    [[ "${iface}" =~ ^(lo|veth|fwpr|fwbr|fwln|qbr|qvb|qvo|tap|docker|br-) ]] && continue

    MAC=$(cat "${net_path}/address" 2>/dev/null || echo "N/A")
    OPERSTATE=$(cat "${net_path}/operstate" 2>/dev/null || echo "Unknown")

    RAW_SPEED=$(cat "${net_path}/speed" 2>/dev/null || true)
    if [[ "${RAW_SPEED}" =~ ^[0-9]+$ ]] && (( RAW_SPEED > 0 )); then
        SPEED=$(awk -v s="${RAW_SPEED}" 'BEGIN {
            if (s >= 1000 && s % 1000 == 0) printf "%d Gbps", s / 1000
            else if (s >= 1000)             printf "%.1f Gbps", s / 1000
            else                            printf "%d Mbps", s
        }')
    else
        SPEED="N/A"
    fi

    DRIVER_PATH=$(readlink "${net_path}/device/driver" 2>/dev/null || true)
    if [[ -n "${DRIVER_PATH}" ]]; then
        DRIVER=$(basename "${DRIVER_PATH}")
    elif [[ -d "${net_path}/bridge" ]]; then
        DRIVER="bridge"
    elif [[ -d "${net_path}/bonding" ]]; then
        DRIVER="bonding"
    else
        DRIVER="N/A"
    fi

    printf "%-14s | %-18s | %-10s | %-12s | %-24s\n" \
        "${iface:0:14}" "${MAC}" "${OPERSTATE}" "${SPEED}" "${DRIVER:0:24}"
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
