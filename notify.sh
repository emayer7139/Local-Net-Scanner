#!/bin/bash

IP="$1"
MAC="$2"
EMAIL=$(grep ALERT_EMAIL config.ini | cut -d '=' -f2 | tr -d '"')

SUBJECT="🚨 NetSweep Alert: $IP - Unknown Device"
BODY="Unknown device detected!\nIP: $IP\nMAC: $MAC\nTime: $(date)"

echo -e "$BODY" | msmtp "$EMAIL"
echo "[DEBUG] Sent NetSweep alert for $IP ($MAC)" >> netsweep.log
