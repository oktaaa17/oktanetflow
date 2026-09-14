#!/usr/bin/env bash

# --- KONFIGURASI MULTI TARGET ---
# Format: "HOST:PORT:NODE:STORAGE:TOKEN"
TARGETS=(
  "<ip>:8006:<node>:backup:root@pam!BackupAudit=<API-TOKEN-SECRET>"
)

# Threshold SLA Critical (7 hari dalam detik)
CRIT_THRESHOLD=$(( 7 * 24 * 3600 ))

# Kode Warna Terminal ANSI
COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_RESET="\e[0m"

CURRENT_TS=$(date +%s)
CRITICAL_FOUND=0
ALERT_ROWS=""

for TARGET in "${TARGETS[@]}"; do
    IFS=":" read -r PVE_HOST PVE_PORT NODE STORAGE TOKEN <<< "$TARGET"

    RAW_JSON=$(curl -k -s -X GET "https://${PVE_HOST}:${PVE_PORT}/api2/json/nodes/${NODE}/storage/${STORAGE}/content" \
      -H "Authorization: PVEAPIToken=${TOKEN}" \
      -H "Accept: application/json")

    # Array asosiatif per node untuk menyimpan HANYA ctime dan file terbaru per VMID
    declare -A LATEST_CTIME
    declare -A LATEST_FILE

    # Parsing kompatibel PVE baru & lama
    while IFS= read -r item; do
        [ -z "$item" ] && continue

        VOLID=$(echo "$item" | grep -o '"volid":"[^"]*"' | sed 's/"volid":"//;s/"//')
        [[ "$VOLID" != *"vzdump"* ]] && continue

        VMID=$(echo "$item" | grep -o '"vmid":[0-9]*' | sed 's/"vmid"://')
        if [ -z "$VMID" ]; then
            VMID=$(echo "$VOLID" | grep -oE 'vzdump-(qemu|lxc)-[0-9]+' | grep -oE '[0-9]+')
        fi
        [ -z "$VMID" ] && continue

        CTIME=$(echo "$item" | grep -o '"ctime":[0-9]*' | sed 's/"ctime"://')
        if [ -z "$CTIME" ] || [ "$CTIME" -eq 0 ]; then
            DATE_STR=$(echo "$VOLID" | grep -oE '[0-9]{4}_[0-9]{2}_[0-9]{2}-[0-9]{2}_[0-9]{2}_[0-9]{2}')
            if [ -n "$DATE_STR" ]; then
                FORMATTED_DATE=$(echo "$DATE_STR" | sed 's/_/-/g; s/-/:/3; s/-/:/3')
                CTIME=$(date -d "$FORMATTED_DATE" +%s 2>/dev/null || date -j -f "%Y-%m-%d-%H:%M:%S" "$DATE_STR" +%s 2>/dev/null)
            fi
        fi

        # VALIDASI TAHUN: Abaikan file jika bukan tahun 2026
        YEAR_CHECK=$(date -d "@${CTIME}" "+%Y" 2>/dev/null || date -r "${CTIME}" "+%Y" 2>/dev/null)
        if [ "$YEAR_CHECK" != "2026" ]; then
            continue
        fi

        # Filter retention: Simpan hanya CTIME terbesar (terbaru) untuk VMID ini
        CURR_MAX="${LATEST_CTIME[$VMID]:-0}"
        if [ "$CTIME" -gt "$CURR_MAX" ]; then
            LATEST_CTIME[$VMID]="$CTIME"
            LATEST_FILE[$VMID]="$VOLID"
        fi
    done < <(echo "$RAW_JSON" | grep -o '{[^}]*}' | grep -E 'vzdump|"content":"(backup|vzdump)"')

    # Evaluasi SLA hanya terhadap backup terakhir tiap VMID
    for VMID in "${!LATEST_CTIME[@]}"; do
        CTIME="${LATEST_CTIME[$VMID]}"
        DIFF_SEC=$(( CURRENT_TS - CTIME ))

        if [ "$DIFF_SEC" -ge "$CRIT_THRESHOLD" ]; then
            CRITICAL_FOUND=$(( CRITICAL_FOUND + 1 ))
            LAST_BACKUP=$(date -d "@${CTIME}" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -r "${CTIME}" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
            AGE="$(( DIFF_SEC / 86400 ))d ago"
            FILENAME=$(basename "${LATEST_FILE[$VMID]}")
            SHORT_NAME="${FILENAME:0:22}..."
            STATUS="${COLOR_RED}CRITICAL${COLOR_RESET}"

            ALERT_ROWS+=$(printf "%-6s %-24s %-12s %-20s %-10s %-14s %-10b\n" \
              "$VMID" "$SHORT_NAME" "$NODE" "$LAST_BACKUP" "$AGE" "$STORAGE" "$STATUS")
            ALERT_ROWS+=$'\n'
        fi
    done

    unset LATEST_CTIME
    unset LATEST_FILE
done

# Output hasil evaluasi
if [ "$CRITICAL_FOUND" -gt 0 ]; then
    echo -e "${COLOR_RED}[!] SLA BREACH DETECTED: Total ${CRITICAL_FOUND} VM memiliki backup terakhir >= 7 hari!${COLOR_RESET}\n"
    printf "%-6s %-24s %-12s %-20s %-10s %-14s %-10s\n" "VMID" "NAME" "NODE" "LAST BACKUP" "AGE" "SOURCE" "STATUS"
    printf "%s\n" "------------------------------------------------------------------------------------------------------"
    echo -ne "$ALERT_ROWS"
    exit 2
else
    echo -e "${COLOR_GREEN}[OK] All nodes & storages compliant. Backup terakhir setiap VM masih dalam batas SLA (< 7 hari).${COLOR_RESET}"
    exit 0
fi
