#!/bin/bash
cat >> 'EOF'


          _____                    _____            _____                    _____                   _____                    _____                    _____                    _____          
         /\    \                  /\    \          /\    \                  /\    \                 /\    \                  /\    \                  /\    \                  /\    \         
        /::\____\                /::\    \        /::\    \                /::\    \               /::\____\                /::\    \                /::\    \                /::\    \        
       /::::|   |               /::::\    \       \:::\    \              /::::\    \             /:::/    /               /::::\    \              /::::\    \              /::::\    \       
      /:::::|   |              /::::::\    \       \:::\    \            /::::::\    \           /:::/   _/___            /::::::\    \            /::::::\    \            /::::::\    \      
     /::::::|   |             /:::/\:::\    \       \:::\    \          /:::/\:::\    \         /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \          /:::/\:::\    \     
    /:::/|::|   |            /:::/__\:::\    \       \:::\    \        /:::/__\:::\    \       /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
   /:::/ |::|   |           /::::\   \:::\    \      /::::\    \       \:::\   \:::\    \     /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \      /::::\   \:::\    \   
  /:::/  |::|   | _____    /::::::\   \:::\    \    /::::::\    \    ___\:::\   \:::\    \   /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \    /::::::\   \:::\    \  
 /:::/   |::|   |/\    \  /:::/\:::\   \:::\    \  /:::/\:::\    \  /\   \:::\   \:::\    \ /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\ 
/:: /    |::|   /::\____\/:::/__\:::\   \:::\____\/:::/  \:::\____\/::\   \:::\   \:::\____\:::|   /:::/   /::\____\/:::/__\:::\   \:::\____\/:::/__\:::\   \:::\____\/:::/  \:::\   \:::|    |
\::/    /|::|  /:::/    /\:::\   \:::\   \::/    /:::/    \::/    /\:::\   \:::\   \::/    /:::|__/:::/   /:::/    /\:::\   \:::\   \::/    /\:::\   \:::\   \::/    /\::/    \:::\  /:::|____|
 \/____/ |::| /:::/    /  \:::\   \:::\   \/____/:::/    / \/____/  \:::\   \:::\   \/____/ \:::\/:::/   /:::/    /  \:::\   \:::\   \/____/  \:::\   \:::\   \/____/  \/_____/\:::\/:::/    / 
         |::|/:::/    /    \:::\   \:::\    \  /:::/    /            \:::\   \:::\    \      \::::::/   /:::/    /    \:::\   \:::\    \       \:::\   \:::\    \               \::::::/    /  
         |::::::/    /      \:::\   \:::\____\/:::/    /              \:::\   \:::\____\      \::::/___/:::/    /      \:::\   \:::\____\       \:::\   \:::\____\               \::::/    /   
         |:::::/    /        \:::\   \::/    /\::/    /                \:::\  /:::/    /       \:::\__/:::/    /        \:::\   \::/    /        \:::\   \::/    /                \::/____/    
         |::::/    /          \:::\   \/____/  \/____/                  \:::\/:::/    /         \::::::::/    /          \:::\   \/____/          \:::\   \/____/                  ~~          
         /:::/    /            \:::\    \                                \::::::/    /           \::::::/    /            \:::\    \               \:::\    \                                  
        /:::/    /              \:::\____\                                \::::/    /             \::::/    /              \:::\____\               \:::\____\                                 
        \::/    /                \::/    /                                 \::/    /               \::/____/                \::/    /                \::/    /                                 
         \/____/                  \/____/                                   \/____/                 ~~                       \/____/                  \/____/                                  
                                                                                                                                                                                               
                                                                                                                                                                                               
                                                                                         A local network scanner. 

EOF
source ./config.ini

# === MODE HANDLING ===
MODE="auto"
[[ "$1" == "--interactive" ]] && MODE="interactive"
[[ "$1" == "--help" ]] && {
    echo "Usage: $0 [--interactive]"
    echo "  --interactive   Prompt to trust new devices (no email alerts)"
    echo "  (no flag)       Scheduled/automated run, triggers email alert for unknowns"
    exit 0
}

echo "[*] NetSweep run at $(date) | Mode: $MODE"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
TMP_SCAN="scan_result.tmp"
TMP_UNKNOWN="unknown_devices.tmp"

# === STEP 1: Network scan ===
if [[ $EUID -ne 0 ]]; then
    sudo arp-scan --interface="$SCAN_INTERFACE" --localnet > "$TMP_SCAN"
else
    arp-scan --interface="$SCAN_INTERFACE" --localnet > "$TMP_SCAN"
fi

# === STEP 2: Extract IP + MAC only ===
grep -Eo '([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+([0-9a-f]{2}(:[0-9a-f]{2}){5})' "$TMP_SCAN" > parsed_scan.txt

# Compare with trusted devices
> "$TMP_UNKNOWN"
while read -r ip mac; do
    if ! grep -iq "$mac" trusted_devices.txt; then
        echo "$ip $mac" >> "$TMP_UNKNOWN"
    fi
done < parsed_scan.txt

# === STEP 3: Report + Action ===
if [[ -s "$TMP_UNKNOWN" ]]; then
    echo -e "\n[!] Unknown devices found:\n$(cat $TMP_UNKNOWN)"
    echo -e "\n[$TIMESTAMP] ALERT: Unknown devices:\n$(cat $TMP_UNKNOWN)" >> "$LOG_FILE"

    while read -r line; do
        IP=$(echo "$line" | awk '{print $1}')
        MAC=$(echo "$line" | awk '{print $2}')

        # Run nmap and output to terminal and log file
        echo -e "\n[*] Running nmap on $IP..."
        if [[ $EUID -ne 0 ]]; then
            sudo nmap -O -sV "$IP" | tee -a "$LOG_FILE"
        else
            nmap -O -sV "$IP" | tee -a "$LOG_FILE"
        fi
        echo "[+] Scan complete for $IP — logged."

        if [[ "$MODE" == "interactive" ]]; then
            # Force reading from terminal
            echo -n "➕ Add $IP $MAC to trusted_devices.txt? [y/N]: " >/dev/tty
            read -r response </dev/tty
            if [[ "$response" =~ ^[Yy]$ ]]; then
                echo "$IP $MAC" >> trusted_devices.txt
                echo "[*] Added $IP $MAC to trusted_devices.txt"
            else
                echo "[-] Skipped adding $IP $MAC"
            fi
        else
            ./notify.sh "$IP" "$MAC"
            echo "[-] Skipped adding $IP $MAC (non-interactive scan)"
        fi
    done < "$TMP_UNKNOWN"
else
    echo "[✓] No unknown devices found."
    echo "[$TIMESTAMP] Clean sweep." >> "$LOG_FILE"
fi

# === Cleanup ===
rm -f "$TMP_SCAN" "$TMP_UNKNOWN" parsed_scan.txt
