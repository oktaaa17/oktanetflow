#!/usr/bin/env bash

# Sesuaikan IP, Port, Node, Storage, dan Token masing-masing
TARGETS=(
  "<ip>:8006:<node>:backup:root@pam!BackupAudit=<API-TOKEN-SECRET>"
)

printf "%-14s %-21s %-8s %-12s %-25s\n" "NODE" "HOST:PORT" "HTTP" "ITEMS" "DIAGNOSIS"
printf "%s\n" "-------------------------------------------------------------------------------------"

for TARGET in "${TARGETS[@]}"; do
    IFS=":" read -r PVE_HOST PVE_PORT NODE STORAGE TOKEN <<< "$TARGET"

    # curl dengan batas timeout 4 detik
    RESP=$(curl -k -s --connect-timeout 4 --max-time 6 \
      -w "\nHTTP_STATUS:%{http_code}" \
      -X GET "https://${PVE_HOST}:${PVE_PORT}/api2/json/nodes/${NODE}/storage/${STORAGE}/content" \
      -H "Authorization: PVEAPIToken=${TOKEN}" \
      -H "Accept: application/json" 2>&1)

    HTTP_CODE=$(echo "$RESP" | grep "HTTP_STATUS:" | cut -d':' -f2)
    BODY=$(echo "$RESP" | sed '/HTTP_STATUS:/d')

    # Hitung jumlah item backup
    COUNT=$(echo "$BODY" | grep -oE '"volid":"[^"]*vzdump[^"]*"' | wc -l)

    # Analisis status respon
    if [ "$HTTP_CODE" == "000" ] || [ -z "$HTTP_CODE" ]; then
        STATUS="\e[31mConnection Refused / Timeout\e[0m ${HTTP_CODE:-ERR}"
    elif [ "$HTTP_CODE" == "401" ]; then
        STATUS="\e[31mInvalid Token / Secret\e[0m ${HTTP_CODE}"
    elif [ "$HTTP_CODE" == "403" ]; then
        STATUS="\e[31m403 Forbidden (Missing Node Audit)\e[0m ${HTTP_CODE}"
    elif [ "$HTTP_CODE" == "500" ]; then
        STATUS="\e[31m500 Error (Storage name salah?)\e[0m ${HTTP_CODE}"
    elif [ "$COUNT" -eq 0 ]; then
        STATUS="\e[33mData Kosong (Izin VM/Storage kurang)\e[0m ${HTTP_CODE}"
    else
        STATUS="\e[32mOK ($COUNT backups)\e[0m"
    fi

    printf "%-14s %-21s %-8s %-12s %-25b\n" "$NODE" "${PVE_HOST}:${PVE_PORT}" "${HTTP_CODE:-ERR}" "$COUNT" "$STATUS"
done
