#!/usr/bin/env bash
# ==============================================================================
# Script Name   : hw-scanner-rhel-v2.sh
# Version       : V2 (RHEL / Fedora / CentOS / Rocky / Alma - Bare-Metal & VM)
# Author        : Dimas Oktavian Ramadhan (Oktanetflow)
# Copyright     : Copyright © 2026 Oktanetflow
# Website       : https://oktanetflow.vercel.app/
# Execution     : bash <(curl -fsSL https://oktanetflow.vercel.app/infra/linux/labs/bash/hw-scanner-rhel-v2.sh)
# ==============================================================================
set -euo pipefail
export LC_ALL=C
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

# ANSI color codes for terminal rendering
BOLD='\033[1m'
NC='\033[0m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'

BRAND_HEADER="V2 (RHEL/Fedora/CentOS) | Copyright © 2026 Oktanetflow\nDocs & Lab: https://oktanetflow.vercel.app/"

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
    # Fallback to sysfs DMI (works on minimal RHEL/Fedora/CentOS VMs without dmidecode)
    if [[ -z "${val}" ]]; then
        local sys_file=""
        case "${key}" in
            system-manufacturer)     sys_file="sys_vendor" ;;
            system-product-name)     sys_file="product_name" ;;
            system-version)          sys_file="product_version" ;;
            system-serial-number)    sys_file="product_serial" ;;
            system-uuid)             sys_file="product_uuid" ;;
            baseboard-product-name)  sys_file="board_name" ;;
            baseboard-serial-number) sys_file="board_serial" ;;
            bios-version)            sys_file="bios_version" ;;
            bios-release-date)       sys_file="bios_date" ;;
        esac
        if [[ -n "${sys_file}" && -r "/sys/class/dmi/id/${sys_file}" ]]; then
            val=$(trim_str "$(cat "/sys/class/dmi/id/${sys_file}" 2>/dev/null || true)")
        fi
    fi
    echo "${val:-${default}}"
}

detect_virt_env() {
    local virt=""
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        virt=$(systemd-detect-virt 2>/dev/null || true)
    fi
    if [[ -z "${virt}" || "${virt}" == "none" ]]; then
        local hv=""
        hv=$(lscpu 2>/dev/null | awk -F':' '/^Hypervisor vendor:/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' || true)
        if [[ -n "${hv}" ]]; then
            echo "Virtual Machine (${hv})"
        elif [[ -f /.dockerenv || -f /run/.containerenv ]]; then
            echo "Container (podman/docker)"
        elif [[ -r /run/systemd/container ]]; then
            echo "Container ($(cat /run/systemd/container 2>/dev/null || echo 'unknown'))"
        else
            echo "Bare-Metal (Physical)"
        fi
    else
        case "${virt}" in
            lxc|lxc-libvirt|docker|podman|openvz|systemd-nspawn|wsl)
                echo "Container (${virt})" ;;
            *)
                echo "Virtual Machine (${virt})" ;;
        esac
    fi
}

run_smartctl() {
    if command -v timeout >/dev/null 2>&1; then
        timeout 3 smartctl "$@" 2>/dev/null || true
    else
        smartctl "$@" 2>/dev/null || true
    fi
}

extract_sata_speed() {
    local smart_info="$1"
    local sata_line=""
    sata_line=$(awk -F':' '/^SATA Version is:/{sub(/^[ \t]+/, "", $2); print $2; exit}' <<< "${smart_info}")
    if [[ -n "${sata_line}" ]]; then
        awk '{
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
        }' <<< "${sata_line}"
    fi
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

print_smart_status_line() {
    local label="$1"
    shift
    local smart_h health temp temp_str=""

    smart_h=$(run_smartctl -H "$@")
    health=$(awk -F':' '
        /test result:|SMART Health Status:/ {
            sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit
        }
    ' <<< "${smart_h}")

    temp=$(run_smartctl -A "$@" | awk '
        /Temperature_Celsius|Airflow_Temperature_Cel/ && $10 ~ /^[0-9]+$/ { print $10 "°C"; exit }
        /^Temperature:[ \t]+[0-9]+/                   && $2 ~ /^[0-9]+$/  { print $2 "°C"; exit }
        /^Current Drive Temperature:/                 && $4 ~ /^[0-9]+$/  { print $4 "°C"; exit }
    ' || true)
    if [[ -n "${temp}" ]]; then
        temp_str=" (Temp: ${temp})"
    fi

    if [[ -z "${health}" ]]; then
        echo -e "  - ${label}: ${YELLOW}SMART Unsupported or RAID pass-through required${NC}"
    elif [[ "${health^^}" == *"PASSED"* || "${health^^}" == *"OK"* ]]; then
        echo -e "  - ${label}: ${GREEN}${health}${NC}${temp_str}"
    else
        echo -e "  - ${label}: ${RED}${health}${NC}${temp_str}"
    fi
}

# Soft OS family verification
if [[ ! -f /etc/redhat-release && ! -f /etc/fedora-release ]]; then
    if [[ ! -r /etc/os-release ]] || ! grep -qiE 'rhel|fedora|centos|rocky|alma|ol' /etc/os-release; then
        echo -e "${YELLOW}[WARN] Non-RHEL OS detected. Continuing scan (use hw-scanner-deb-v2.sh for Debian/Ubuntu/PVE).${NC}" >&2
    fi
fi

# Initial Brand Banner
echo -e "${BOLD}${BLUE}======================================================================${NC}"
echo -e "${CYAN}         OKTANETFLOW LINUX HARDWARE & INVENTORY PROFILER V2           ${NC}"
echo -e "${CYAN}${BRAND_HEADER}${NC}"
echo -e "${BOLD}${BLUE}======================================================================${NC}"
echo -e "Audit Timestamp : $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo -e "Scanned Node    : $(hostname -f 2>/dev/null || hostname 2>/dev/null || uname -n)"

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
# 2. OS, VIRTUALIZATION & KERNEL ENVIRONMENT
# ------------------------------------------------------------------------------
print_header "2. OS, VIRTUALIZATION & KERNEL ENVIRONMENT"

OS_NAME="RHEL-based Linux"
if [[ -r /etc/redhat-release ]]; then
    OS_NAME=$(trim_str "$(cat /etc/redhat-release 2>/dev/null || true)")
elif [[ -r /etc/os-release ]]; then
    OS_NAME=$(awk -F'=' '/^PRETTY_NAME=/{gsub(/"/, "", $2); print $2; exit}' /etc/os-release || echo "RHEL-based Linux")
fi
VIRT_ENV=$(detect_virt_env)
SELINUX_STATE="N/A"
if command -v getenforce >/dev/null 2>&1; then
    SELINUX_STATE=$(getenforce 2>/dev/null || echo "Unknown")
fi

printf "%-24s: ${GREEN}%s${NC}\n" "OS Distribution" "${OS_NAME}"
printf "%-24s: ${CYAN}%s${NC}\n" "Runtime Environment" "${VIRT_ENV}"
printf "%-24s: %s\n" "SELinux Mode" "${SELINUX_STATE}"
printf "%-24s: %s (%s)\n" "Kernel Release" "$(uname -r)" "$(uname -m)"
printf "%-24s: %s\n" "Uptime" "$(uptime -p 2>/dev/null || uptime)"

# ------------------------------------------------------------------------------
# 3. CPU TOPOLOGY & SPECS
# ------------------------------------------------------------------------------
print_header "3. CPU SPECIFICATIONS"

LSCPU_OUT=$(lscpu 2>/dev/null || true)
CPU_MODEL=$(awk -F':' '/^Model name:/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' <<< "${LSCPU_OUT}")
if [[ -z "${CPU_MODEL}" ]]; then
    CPU_MODEL=$(awk -F':' '/^BIOS Model name:/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' <<< "${LSCPU_OUT}")
fi
if [[ -z "${CPU_MODEL}" && -r /proc/cpuinfo ]]; then
    CPU_MODEL=$(awk -F':' '/^(model name|Hardware|Processor)[ \t]*:/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' /proc/cpuinfo || true)
fi
CPU_SOCKETS=$(awk -F':' '/^Socket\(s\):/{gsub(/[ \t]+/, "", $2); print $2; exit}' <<< "${LSCPU_OUT}")
CPU_CORES_PER_SOCKET=$(awk -F':' '/^Core\(s\) per socket:/{gsub(/[ \t]+/, "", $2); print $2; exit}' <<< "${LSCPU_OUT}")
CPU_THREADS_PER_CORE=$(awk -F':' '/^Thread\(s\) per core:/{gsub(/[ \t]+/, "", $2); print $2; exit}' <<< "${LSCPU_OUT}")
CPU_TOTAL_THREADS=$(awk -F':' '/^CPU\(s\):/{gsub(/[ \t]+/, "", $2); print $2; exit}' <<< "${LSCPU_OUT}")
if [[ -z "${CPU_TOTAL_THREADS}" ]]; then
    CPU_TOTAL_THREADS=$(nproc 2>/dev/null || echo "N/A")
fi
CPU_VIRT=$(awk -F':' '/^Virtualization:/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' <<< "${LSCPU_OUT}")
CPU_HV=$(awk -F':' '/^Hypervisor vendor:/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' <<< "${LSCPU_OUT}")
if [[ -z "${CPU_VIRT}" && -n "${CPU_HV}" ]]; then
    CPU_VIRT="None (Guest on ${CPU_HV})"
fi

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
        "CPU0" "Populated" "N/A (VM/No DMI T4)" "${CPUINFO_SN:-Not Available}" "${FIRST_PPIN:-N/A}"
fi

# ------------------------------------------------------------------------------
# 4. RAM ARCHITECTURE & DIMM BREAKDOWN
# ------------------------------------------------------------------------------
print_header "4. MEMORY TOPOLOGY (RAM)"

RAM_TOTAL=$( (free -h --si 2>/dev/null || free -h 2>/dev/null) | awk '/^Mem:/ {print $2}' || true)

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
    echo "  No SMBIOS Type 17 memory device entries available (VM or dmidecode not installed)."
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
    echo "  - lspci not installed (install pciutils)"
fi

# Enterprise Hardware RAID CLI Utility Check (Dell PERC / LSI MegaRAID)
RAID_CLI_FOUND=0
RAID_TOOL=$(command -v perccli64 || command -v perccli || command -v storcli64 || command -v storcli || true)
if [[ -n "${RAID_TOOL}" ]]; then
    print_subheader "Hardware RAID Controller Virtual Drives (${RAID_TOOL})"
    "${RAID_TOOL}" /call /vall show 2>/dev/null | grep -E "^[0-9]+/[0-9]+|^DG/VD" || echo "  No virtual drives reported."

    RAID_PD_OUT=$("${RAID_TOOL}" /call /eall /sall show all 2>/dev/null | awk '
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
    ' || true)

    if [[ -n "${RAID_PD_OUT}" ]]; then
        RAID_CLI_FOUND=1
        print_subheader "Hardware RAID Physical Drives & Serial Numbers (${RAID_TOOL})"
        printf "%-12s | %-7s | %-6s | %-5s | %-12s | %-24s | %-22s\n" \
            "Slot" "State" "Intf" "Media" "Capacity" "Model" "Serial Number (S/N)"
        echo "-------------|---------|--------|-------|--------------|--------------------------|-----------------------"
        echo "${RAID_PD_OUT}"
    fi
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

declare -A MEGARAID_PROBE_HOSTS=()
declare -A RAID_VD_DEVS=()
declare -a MEGARAID_SMART_TARGETS=()

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

    # Collect SCSI host driver, udev & smartctl metadata once per disk
    DEV_REALPATH=$(readlink -f "/sys/block/${dev}/device" 2>/dev/null || true)
    SCSI_HOST=$(awk '{ if (match($0, /host[0-9]+/)) print substr($0, RSTART, RLENGTH) }' <<< "${DEV_REALPATH}")
    HOST_DRIVER=""
    if [[ -n "${SCSI_HOST}" && -r "/sys/class/scsi_host/${SCSI_HOST}/proc_name" ]]; then
        HOST_DRIVER=$(trim_str "$(cat "/sys/class/scsi_host/${SCSI_HOST}/proc_name" 2>/dev/null || true)")
    fi

    UDEV_INFO=$(udevadm info --query=property --name="${DEV_PATH}" 2>/dev/null || true)
    SMART_INFO=""
    if [[ "${HAS_SMARTCTL}" -eq 1 ]]; then
        SMART_INFO=$(run_smartctl -i "${DEV_PATH}")
    fi

    # 1. Interface / Transport (SATA, SAS, NVMe, USB, VirtIO, Xen, SCSI)
    TRAN_RAW=$(trim_str "$(lsblk -dn -o TRAN "${DEV_PATH}" 2>/dev/null || true)")
    if [[ -z "${TRAN_RAW}" ]]; then
        if [[ "${dev}" == nvme* ]]; then
            TRAN_RAW="nvme"
        elif [[ "${dev}" == vd* ]]; then
            TRAN_RAW="virtio"
        elif [[ "${dev}" == xvd* ]]; then
            TRAN_RAW="xen"
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
        xen)      INTERFACE="Xen" ;;
        scsi)     INTERFACE="SCSI" ;;
        mmc|sd)   INTERFACE="MMC/SD" ;;
        "")       INTERFACE="Internal" ;;
        *)        INTERFACE="${TRAN_RAW^^}" ;;
    esac

    # Enrich Interface with SATA link speed or SAS protocol via smartctl
    if [[ -n "${SMART_INFO}" ]]; then
        if grep -q "^SATA Version is:" <<< "${SMART_INFO}"; then
            SATA_SPEED=$(extract_sata_speed "${SMART_INFO}")
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

    # 5. Detect Hardware RAID Virtual Disk (excluding VM virtual disks)
    IS_VM_DISK=0
    if grep -qiE 'QEMU|VMware|VBOX|VirtualBox|Msft|Hyper-V|Xen|VirtIO|Google|Amazon|AWS|EBS|Red Hat' <<< "${MODEL}"; then
        IS_VM_DISK=1
    fi

    IS_RAID_VD=0
    if [[ "${IS_VM_DISK}" -eq 0 ]]; then
        if grep -qiE 'PERC|MegaRAID|MR[0-9]|AVAGO|LSI|LOGICAL VOLUME|Smart Array|ServeRAID|Adaptec|ASR[0-9]' <<< "${MODEL}"; then
            IS_RAID_VD=1
        elif [[ "${HOST_DRIVER}" == "megaraid_sas" && "${SERIAL}" =~ ^[0-9a-fA-F]{32}$ ]]; then
            IS_RAID_VD=1
        fi
    fi

    if [[ "${IS_RAID_VD}" -eq 1 ]]; then
        INTERFACE="RAID (VD)"
        MEDIA="Virtual"
        RAID_VD_DEVS["${DEV_PATH}"]=1
        if [[ "${HOST_DRIVER}" == "megaraid_sas" ]] || grep -qiE 'PERC|MegaRAID|MR[0-9]|AVAGO|LSI' <<< "${MODEL}"; then
            host_key="${SCSI_HOST:-${DEV_PATH}}"
            if [[ -z "${MEGARAID_PROBE_HOSTS[$host_key]:-}" ]]; then
                MEGARAID_PROBE_HOSTS["${host_key}"]="${DEV_PATH}"
            fi
        fi
    fi

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

# Try/Catch Fallback: Auto-probe real physical drives behind PERC/MegaRAID via smartctl (without perccli)
if [[ "${RAID_CLI_FOUND}" -eq 0 && ${#MEGARAID_PROBE_HOSTS[@]} -gt 0 ]]; then
    print_subheader "Physical Drives Behind Hardware RAID (smartctl Pass-Through)"
    printf "%-13s | %-15s | %-9s | %-20s | %-26s | %-24s\n" \
        "DEVICE" "INTERFACE" "MEDIA" "CAPACITY (GB / GiB)" "MODEL" "SERIAL NUMBER (S/N)"
    echo "--------------|-----------------|-----------|----------------------|----------------------------|-------------------------"

    if [[ "${HAS_SMARTCTL}" -eq 1 ]]; then
        RAID_PHYS_COUNT=0
        RAID_PHYS_BYTES=0
        declare -A SEEN_RAID_SN=()

        for host_key in $(printf '%s\n' "${!MEGARAID_PROBE_HOSTS[@]}" | sort); do
            probe_dev="${MEGARAID_PROBE_HOSTS[$host_key]}"

            for (( did=0; did<64; did++ )); do
                P_INFO=""
                P_DRV_ARG=""

                # Try 1: Base MegaRAID pass-through (fast-skips empty slots & handles SAS natively)
                BASE_OUT=$(run_smartctl -i -d "megaraid,${did}" "${probe_dev}")
                if grep -qiE "No such device|INQUIRY failed" <<< "${BASE_OUT}"; then
                    continue
                fi

                if grep -qiE "^(Device Model|Model Number|Product):" <<< "${BASE_OUT}"; then
                    P_INFO="${BASE_OUT}"
                    P_DRV_ARG="megaraid,${did}"
                    # Try 2: Upgrade SATA drives to sat+megaraid for full SATA speed, SSD/HDD & S/N
                    if ! grep -qi "Transport protocol:.*SAS" <<< "${BASE_OUT}"; then
                        SAT_OUT=$(run_smartctl -i -d "sat+megaraid,${did}" "${probe_dev}")
                        if grep -qiE "^(Device Model|Model Number):" <<< "${SAT_OUT}"; then
                            P_INFO="${SAT_OUT}"
                            P_DRV_ARG="sat+megaraid,${did}"
                        fi
                    fi
                else
                    # Catch: Some firmwares respond only to sat+megaraid
                    SAT_OUT=$(run_smartctl -i -d "sat+megaraid,${did}" "${probe_dev}")
                    if grep -qiE "^(Device Model|Model Number):" <<< "${SAT_OUT}"; then
                        P_INFO="${SAT_OUT}"
                        P_DRV_ARG="sat+megaraid,${did}"
                    fi
                fi

                [[ -z "${P_INFO}" ]] && continue

                # Skip non-disk devices (e.g., Dell/LSI backplane enclosure services)
                if grep -qiE "^Device type:[ \t]*(enclosure|processor|cd|dvd|tape|medium changer)" <<< "${P_INFO}"; then
                    continue
                fi

                # Extract Serial Number & deduplicate across controllers
                P_SERIAL=$(awk -F':' '/^[ \t]*Serial [Nn]umber:/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' <<< "${P_INFO}")
                P_SERIAL="${P_SERIAL:-N/A}"
                if [[ "${P_SERIAL}" != "N/A" ]]; then
                    if [[ -n "${SEEN_RAID_SN[$P_SERIAL]:-}" ]]; then
                        continue
                    fi
                    SEEN_RAID_SN["${P_SERIAL}"]=1
                fi

                # Extract Capacity (bytes -> GB / GiB)
                P_BYTES=$(awk '
                    /^(User Capacity|Total NVM Capacity|Namespace 1 Size\/Capacity):/ {
                        val = $0
                        sub(/^[^:]*:[ \t]*/, "", val)
                        sub(/[ \t]*bytes.*$/, "", val)
                        gsub(/[^0-9]/, "", val)
                        print val
                        exit
                    }
                ' <<< "${P_INFO}")
                if [[ ! "${P_BYTES}" =~ ^[0-9]+$ ]]; then
                    P_BYTES=0
                fi

                RAID_PHYS_COUNT=$(( RAID_PHYS_COUNT + 1 ))
                RAID_PHYS_BYTES=$(( RAID_PHYS_BYTES + P_BYTES ))
                P_CAP=$(format_disk_capacity "${P_BYTES}")

                # Extract Interface (SATA + speed / SAS / NVMe)
                if grep -q "^SATA Version is:" <<< "${P_INFO}"; then
                    P_SATA_SPD=$(extract_sata_speed "${P_INFO}")
                    if [[ -n "${P_SATA_SPD}" ]]; then
                        P_INTF="SATA (${P_SATA_SPD})"
                    else
                        P_INTF="SATA"
                    fi
                elif grep -qi "Transport protocol:.*SAS" <<< "${P_INFO}"; then
                    P_INTF="SAS"
                elif grep -qi "^NVMe Version:" <<< "${P_INFO}"; then
                    P_INTF="NVMe"
                elif [[ "${P_DRV_ARG}" == sat+* ]] || grep -q "^ATA Version is:" <<< "${P_INFO}"; then
                    P_INTF="SATA"
                else
                    P_INTF="SAS/SCSI"
                fi

                # Extract Vendor & Model
                P_VENDOR=$(awk -F':' '/^Vendor:/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' <<< "${P_INFO}")
                P_MODEL=$(awk -F':' '/^(Device Model|Model Number|Product):/{sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2); print $2; exit}' <<< "${P_INFO}")
                if [[ -n "${P_VENDOR}" && "${P_VENDOR^^}" != "ATA" && "${P_VENDOR^^}" != "NVME" ]]; then
                    if [[ -z "${P_MODEL}" ]]; then
                        P_MODEL="${P_VENDOR}"
                    elif [[ "${P_MODEL,,}" != "${P_VENDOR,,}"* ]]; then
                        P_MODEL="${P_VENDOR} ${P_MODEL}"
                    fi
                fi
                P_MODEL="${P_MODEL:-Unknown}"

                # Extract Media Type (SSD / NVMe SSD / HDD)
                if [[ "${P_INTF}" == NVMe* ]]; then
                    P_MEDIA="NVMe SSD"
                elif grep -qi "Solid State Device" <<< "${P_INFO}"; then
                    P_MEDIA="SSD"
                elif grep -qiE "Rotation Rate:.*[0-9]+[ \t]*rpm" <<< "${P_INFO}"; then
                    P_MEDIA="HDD"
                elif grep -qi "SSD" <<< "${P_MODEL}"; then
                    P_MEDIA="SSD"
                else
                    P_MEDIA="Unknown"
                fi

                DID_LABEL="megaraid,${did}"
                MEGARAID_SMART_TARGETS+=("${probe_dev}|${P_DRV_ARG}|${DID_LABEL}")

                printf "%-13s | %-15s | %-9s | %-20s | %-26s | %s\n" \
                    "${DID_LABEL}" "${P_INTF:0:15}" "${P_MEDIA:0:9}" "${P_CAP:0:20}" "${P_MODEL:0:26}" "${P_SERIAL}"
            done
        done

        if [[ "${RAID_PHYS_COUNT}" -gt 0 ]]; then
            RAID_CAP_FMT=$(format_disk_capacity "${RAID_PHYS_BYTES}")
            echo "--------------------------------------------------------------------------------------------------------------------------"
            printf "  Total Physical Disks: ${BOLD}${GREEN}%d${NC} | Total Raw Capacity: ${BOLD}${GREEN}%s${NC}\n" \
                "${RAID_PHYS_COUNT}" "${RAID_CAP_FMT}"
        else
            echo -e "  ${YELLOW}[WARN] RAID Virtual Disk detected, but smartctl pass-through returned no physical drives.${NC}"
        fi
    else
        echo -e "  ${YELLOW}[WARN] RAID Virtual Disk detected, but smartctl (smartmontools) is not installed for pass-through.${NC}"
    fi
fi

# Check SMART Health if smartctl exists
if [[ "${HAS_SMARTCTL}" -eq 1 ]]; then
    print_subheader "SMART Health Status"
    while read -r dev dtype _; do
        [[ -z "${dev}" || "${dtype}" != "disk" ]] && continue
        DEV_PATH="/dev/${dev}"
        if [[ -n "${RAID_VD_DEVS[$DEV_PATH]:-}" && ${#MEGARAID_SMART_TARGETS[@]} -gt 0 ]]; then
            continue
        fi
        print_smart_status_line "${DEV_PATH}" "${DEV_PATH}"
    done < <(lsblk -dn -o NAME,TYPE -e 7,11 2>/dev/null || true)

    if [[ ${#MEGARAID_SMART_TARGETS[@]} -gt 0 ]]; then
        for entry in "${MEGARAID_SMART_TARGETS[@]}"; do
            IFS='|' read -r m_dev m_arg m_label <<< "${entry}"
            print_smart_status_line "${m_dev} [${m_label}]" -d "${m_arg}" "${m_dev}"
        done
    fi
fi

# ------------------------------------------------------------------------------
# 6. GPU & GRAPHICS ACCELERATORS
# ------------------------------------------------------------------------------
print_header "6. GPU & GRAPHICS ACCELERATORS"

print_subheader "PCIe / Virtual Graphics Controllers"
GPU_FOUND=0
NVIDIA_PCI_DETECTED=0
NVIDIA_VFIO_BOUND=0

if command -v lspci >/dev/null 2>&1; then
    GPU_PCI_OUT=$(lspci -Dnn 2>/dev/null | grep -iE 'vga compatible controller|3d controller|display controller' || true)
    if [[ -n "${GPU_PCI_OUT}" ]]; then
        printf "%-14s | %-15s | %-14s | %-15s | %s\n" \
            "PCI SLOT" "TYPE" "DRIVER" "PCIE LINK" "CONTROLLER MODEL"
        echo "---------------|-----------------|----------------|-----------------|----------------------------------------------"

        while IFS= read -r gpu_line; do
            [[ -z "${gpu_line}" ]] && continue
            GPU_FOUND=1
            pci_slot="${gpu_line%% *}"
            rest="${gpu_line#"${pci_slot} "}"
            raw_class="${rest%%: *}"
            gpu_model="${rest#*: }"

            if grep -qiE 'ASPEED|Matrox|BMC|iDRAC|iLO' <<< "${gpu_model}"; then
                gpu_type="BMC / Onboard"
            elif grep -qiE 'Virtio|VMware|QXL|Bochs|QEMU|Hyper-V|VirtualBox|InnoTek|Cirrus|Technical Corp\. Device 1111' <<< "${gpu_model}"; then
                gpu_type="Virtual GPU"
            elif grep -qi '3d controller' <<< "${raw_class}"; then
                gpu_type="3D / Compute"
            elif grep -qi 'display controller' <<< "${raw_class}"; then
                gpu_type="Display / GPU"
            else
                gpu_type="VGA / GPU"
            fi

            drv_link=$(readlink "/sys/bus/pci/devices/${pci_slot}/driver" 2>/dev/null || true)
            if [[ -n "${drv_link}" ]]; then
                gpu_driver=$(basename "${drv_link}")
            else
                gpu_driver="None/Unbound"
            fi

            if grep -qi 'NVIDIA' <<< "${gpu_model}"; then
                NVIDIA_PCI_DETECTED=1
                if [[ "${gpu_driver}" == "vfio-pci" ]]; then
                    NVIDIA_VFIO_BOUND=1
                fi
            fi

            link_spd=$(trim_str "$(cat "/sys/bus/pci/devices/${pci_slot}/current_link_speed" 2>/dev/null || true)")
            link_wid=$(trim_str "$(cat "/sys/bus/pci/devices/${pci_slot}/current_link_width" 2>/dev/null || true)")
            link_spd="${link_spd% PCIe}"
            if [[ -n "${link_spd}" && "${link_spd}" != "Unknown" && "${link_wid}" =~ ^[0-9]+$ && "${link_wid}" -gt 0 ]]; then
                pcie_link="${link_spd} x${link_wid}"
            else
                pcie_link="Virtual/N/A"
            fi

            printf "%-14s | %-15s | %-14s | %-15s | %s\n" \
                "${pci_slot:0:14}" "${gpu_type:0:15}" "${gpu_driver:0:14}" "${pcie_link:0:15}" "${gpu_model}"
        done <<< "${GPU_PCI_OUT}"
    fi
else
    # Fallback via sysfs PCI class 0x03xxxx (works on minimal VMs without lspci)
    for pci_dir in /sys/bus/pci/devices/*; do
        [[ -r "${pci_dir}/class" ]] || continue
        p_class=$(trim_str "$(cat "${pci_dir}/class" 2>/dev/null || true)")
        [[ "${p_class}" == 0x03* ]] || continue

        if [[ "${GPU_FOUND}" -eq 0 ]]; then
            printf "%-14s | %-15s | %-14s | %-15s | %s\n" \
                "PCI SLOT" "TYPE" "DRIVER" "PCIE LINK" "CONTROLLER MODEL"
            echo "---------------|-----------------|----------------|-----------------|----------------------------------------------"
        fi
        GPU_FOUND=1

        pci_slot=$(basename "${pci_dir}")
        p_ven=$(trim_str "$(cat "${pci_dir}/vendor" 2>/dev/null || echo '0x0000')")
        p_dev=$(trim_str "$(cat "${pci_dir}/device" 2>/dev/null || echo '0x0000')")

        case "${p_ven,,}" in
            0x10de) ven_name="NVIDIA Corporation"; NVIDIA_PCI_DETECTED=1 ;;
            0x1002) ven_name="AMD / ATI" ;;
            0x8086) ven_name="Intel Corporation" ;;
            0x1a03) ven_name="ASPEED (BMC VGA)" ;;
            0x102b) ven_name="Matrox (BMC VGA)" ;;
            0x1af4) ven_name="Red Hat / VirtIO GPU" ;;
            0x15ad) ven_name="VMware SVGA" ;;
            0x1234) ven_name="QEMU / Bochs VGA" ;;
            0x1b36) ven_name="Red Hat QXL" ;;
            0x1414) ven_name="Microsoft Hyper-V Video" ;;
            *)      ven_name="PCI Vendor ${p_ven}" ;;
        esac

        case "${p_class,,}" in
            0x0302*) gpu_type="3D / Compute" ;;
            0x0380*) gpu_type="Display / GPU" ;;
            *)       gpu_type="VGA / GPU" ;;
        esac
        if [[ "${p_ven,,}" == "0x1a03" || "${p_ven,,}" == "0x102b" ]]; then
            gpu_type="BMC / Onboard"
        elif [[ "${p_ven,,}" == "0x1af4" || "${p_ven,,}" == "0x15ad" || "${p_ven,,}" == "0x1234" || "${p_ven,,}" == "0x1b36" || "${p_ven,,}" == "0x1414" ]]; then
            gpu_type="Virtual GPU"
        fi

        drv_link=$(readlink "${pci_dir}/driver" 2>/dev/null || true)
        if [[ -n "${drv_link}" ]]; then
            gpu_driver=$(basename "${drv_link}")
        else
            gpu_driver="None/Unbound"
        fi
        if [[ "${p_ven,,}" == "0x10de" && "${gpu_driver}" == "vfio-pci" ]]; then
            NVIDIA_VFIO_BOUND=1
        fi

        link_spd=$(trim_str "$(cat "${pci_dir}/current_link_speed" 2>/dev/null || true)")
        link_wid=$(trim_str "$(cat "${pci_dir}/current_link_width" 2>/dev/null || true)")
        link_spd="${link_spd% PCIe}"
        if [[ -n "${link_spd}" && "${link_spd}" != "Unknown" && "${link_wid}" =~ ^[0-9]+$ && "${link_wid}" -gt 0 ]]; then
            pcie_link="${link_spd} x${link_wid}"
        else
            pcie_link="Virtual/N/A"
        fi

        printf "%-14s | %-15s | %-14s | %-15s | %s\n" \
            "${pci_slot:0:14}" "${gpu_type:0:15}" "${gpu_driver:0:14}" "${pcie_link:0:15}" "${ven_name} [${p_ven#0x}:${p_dev#0x}]"
    done
fi

if [[ "${GPU_FOUND}" -eq 0 ]]; then
    echo "  No PCIe or virtual GPU devices detected."
fi

# Try/Catch: NVIDIA GPU Detailed Inventory (VRAM, Driver, Temp, S/N, UUID)
if command -v nvidia-smi >/dev/null 2>&1; then
    NVIDIA_OUT=$(nvidia-smi --query-gpu=index,name,memory.total,driver_version,temperature.gpu,serial,uuid --format=csv,noheader,nounits 2>/dev/null || true)
    if [[ -n "${NVIDIA_OUT}" ]] && ! grep -qiE "failed|error|no devices were found" <<< "${NVIDIA_OUT}"; then
        print_subheader "NVIDIA GPU Inventory, VRAM & Serial Numbers (nvidia-smi)"
        printf "%-5s | %-28s | %-11s | %-11s | %-6s | %-20s | %s\n" \
            "GPU" "MODEL" "VRAM" "DRIVER" "TEMP" "SERIAL NUMBER (S/N)" "UUID"
        echo "------|------------------------------|-------------|-------------|--------|----------------------|----------------------------------------"

        while IFS=',' read -r nv_idx nv_name nv_vram nv_drv nv_temp nv_sn nv_uuid; do
            nv_idx=$(trim_str "${nv_idx:-}")
            [[ ! "${nv_idx}" =~ ^[0-9]+$ ]] && continue
            nv_name=$(trim_str "${nv_name:-Unknown}")
            nv_vram=$(trim_str "${nv_vram:-}")
            nv_drv=$(trim_str "${nv_drv:-N/A}")
            nv_temp=$(trim_str "${nv_temp:-}")
            nv_sn=$(trim_str "${nv_sn:-}")
            nv_uuid=$(trim_str "${nv_uuid:-N/A}")

            if [[ "${nv_vram}" =~ ^[0-9]+$ ]]; then
                if (( nv_vram >= 1024 )); then
                    nv_vram_fmt=$(awk -v m="${nv_vram}" 'BEGIN { printf "%.1f GiB", m / 1024 }')
                else
                    nv_vram_fmt="${nv_vram} MiB"
                fi
            else
                nv_vram_fmt="N/A"
            fi

            if [[ "${nv_temp}" =~ ^[0-9]+$ ]]; then
                nv_temp_fmt="${nv_temp}°C"
            else
                nv_temp_fmt="N/A"
            fi

            if [[ -z "${nv_sn}" || "${nv_sn}" == "[N/A]" || "${nv_sn}" == "[Not Supported]" ]]; then
                nv_sn="N/A"
            fi

            printf "%-5s | %-28s | %-11s | %-11s | %-6s | %-20s | %s\n" \
                "GPU ${nv_idx}" "${nv_name:0:28}" "${nv_vram_fmt:0:11}" "${nv_drv:0:11}" "${nv_temp_fmt:0:6}" "${nv_sn:0:20}" "${nv_uuid}"
        done <<< "${NVIDIA_OUT}"
    elif [[ "${NVIDIA_PCI_DETECTED}" -eq 1 ]]; then
        if [[ "${NVIDIA_VFIO_BOUND}" -eq 1 ]]; then
            echo -e "  ${CYAN}[INFO] NVIDIA GPU is bound to vfio-pci (PCIe Passthrough); nvidia-smi telemetry unavailable on host.${NC}"
        else
            echo -e "  ${YELLOW}[WARN] NVIDIA GPU detected, but nvidia-smi could not communicate with the driver.${NC}"
        fi
    fi
elif [[ "${NVIDIA_PCI_DETECTED}" -eq 1 ]]; then
    if [[ "${NVIDIA_VFIO_BOUND}" -eq 1 ]]; then
        echo -e "  ${CYAN}[INFO] NVIDIA GPU is bound to vfio-pci (PCIe Passthrough).${NC}"
    else
        echo -e "  ${YELLOW}[WARN] NVIDIA GPU detected, but nvidia-smi is not installed (install NVIDIA driver for VRAM/S/N details).${NC}"
    fi
fi

# Try/Catch: AMD / Discrete DRM GPU Detailed Inventory via sysfs (no extra CLI required)
DRM_GPU_ROWS=""
for drm_card in /sys/class/drm/card[0-9]*; do
    card_name=$(basename "${drm_card}")
    [[ "${card_name}" =~ ^card[0-9]+$ ]] || continue
    [[ -r "${drm_card}/device/mem_info_vram_total" ]] || continue

    drm_vram_bytes=$(trim_str "$(cat "${drm_card}/device/mem_info_vram_total" 2>/dev/null || echo 0)")
    if [[ "${drm_vram_bytes}" =~ ^[0-9]+$ && "${drm_vram_bytes}" -gt 0 ]]; then
        drm_vram_fmt=$(awk -v b="${drm_vram_bytes}" 'BEGIN { printf "%.1f GiB", b / 1073741824 }')
    else
        drm_vram_fmt="N/A"
    fi

    drm_slot=$(basename "$(readlink -f "${drm_card}/device" 2>/dev/null || echo 'N/A')")
    drm_model=$(trim_str "$(cat "${drm_card}/device/product_name" 2>/dev/null || true)")
    if [[ -z "${drm_model}" ]] && command -v lspci >/dev/null 2>&1; then
        drm_model=$(lspci -s "${drm_slot}" 2>/dev/null | sed 's/^[^:]*:[^:]*: //' || true)
    fi
    drm_model="${drm_model:-AMD/DRM GPU}"

    drm_sn=$(trim_str "$(cat "${drm_card}/device/serial_number" 2>/dev/null || true)")
    if [[ -z "${drm_sn}" ]]; then
        drm_sn=$(trim_str "$(cat "${drm_card}/device/unique_id" 2>/dev/null || true)")
    fi
    drm_sn="${drm_sn:-N/A}"

    drm_temp="N/A"
    for hwmon_t in "${drm_card}"/device/hwmon/hwmon*/temp1_input; do
        if [[ -r "${hwmon_t}" ]]; then
            t_raw=$(trim_str "$(cat "${hwmon_t}" 2>/dev/null || true)")
            if [[ "${t_raw}" =~ ^[0-9]+$ && "${t_raw}" -gt 0 ]]; then
                drm_temp="$(( t_raw / 1000 ))°C"
                break
            fi
        fi
    done

    DRM_GPU_ROWS+=$(printf "%-8s | %-14s | %-30s | %-11s | %-7s | %s\n" \
        "${card_name}" "${drm_slot:0:14}" "${drm_model:0:30}" "${drm_vram_fmt:0:11}" "${drm_temp:0:7}" "${drm_sn}")$'\n'
done

if [[ -n "${DRM_GPU_ROWS}" ]]; then
    print_subheader "AMD / Discrete DRM GPU Inventory, VRAM & Serial Numbers (sysfs)"
    printf "%-8s | %-14s | %-30s | %-11s | %-7s | %s\n" \
        "CARD" "PCI SLOT" "MODEL" "VRAM" "TEMP" "SERIAL / UNIQUE ID"
    echo "---------|----------------|--------------------------------|-------------|---------|-------------------------"
    printf "%s" "${DRM_GPU_ROWS}"
fi

# ------------------------------------------------------------------------------
# 7. NETWORK INTERFACES & PCI CONTROLLERS
# ------------------------------------------------------------------------------
print_header "7. NETWORK INTERFACES & MAC ADDRESSES"

printf "%-14s | %-18s | %-10s | %-12s | %-24s\n" "Interface" "MAC Address" "State" "Speed" "Driver"
echo "---------------|--------------------|------------|--------------|-------------------------"

for net_path in /sys/class/net/*; do
    [[ -e "${net_path}" ]] || continue
    iface=$(basename "${net_path}")
    [[ "${iface}" =~ ^(lo|veth|fwpr|fwbr|fwln|qbr|qvb|qvo|tap|docker|podman|cni-|br-|virbr|vnet) ]] && continue

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
    elif [[ -r "${net_path}/uevent" ]] && grep -q "DEVTYPE=team" "${net_path}/uevent" 2>/dev/null; then
        DRIVER="team"
    else
        DRIVER="N/A"
    fi

    printf "%-14s | %-18s | %-10s | %-12s | %-24s\n" \
        "${iface:0:14}" "${MAC}" "${OPERSTATE}" "${SPEED}" "${DRIVER:0:24}"
done

# Optional missing-tool advisory for minimal RHEL/Fedora/CentOS VMs
PKG_MGR="dnf"
if ! command -v dnf >/dev/null 2>&1 && command -v yum >/dev/null 2>&1; then
    PKG_MGR="yum"
fi
MISSING_RHEL_PKGS=()
command -v dmidecode >/dev/null 2>&1 || MISSING_RHEL_PKGS+=("dmidecode")
command -v lspci     >/dev/null 2>&1 || MISSING_RHEL_PKGS+=("pciutils")
command -v smartctl  >/dev/null 2>&1 || MISSING_RHEL_PKGS+=("smartmontools")
if [[ ${#MISSING_RHEL_PKGS[@]} -gt 0 ]]; then
    echo -e "\n${YELLOW}[TIP] For deeper hardware/SMART/PCIe details, install: ${PKG_MGR} install -y ${MISSING_RHEL_PKGS[*]}${NC}"
fi

# ------------------------------------------------------------------------------
# FOOTER & OKTANETFLOW WATERMARK
# ------------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${BLUE}======================================================================${NC}"
echo -e "${GREEN}Scan completed successfully.${NC}"
echo -e "${BOLD}${BLUE}----------------------------------------------------------------------${NC}"
echo -e "${CYAN}${BRAND_HEADER}${NC}"
echo -e "${BOLD}${BLUE}======================================================================${NC}"
