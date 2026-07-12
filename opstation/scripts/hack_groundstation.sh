#!/bin/bash

# Show confirmation popup
zenity --question \
  --title="Add IPTables Rules?" \
  --text="This will add IPTables rules to the Groundstation for the Command Interception lab.\n\nAre you sure you want to continue?"

if [ $? -ne 0 ]; then
  echo "User cancelled."
  exit 0
fi

# SSH password
PASSWORD='R6dduYerdbMhYvge_FXVo_4yWx2vYyMaNiEW'

# SSH command block using sshpass
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@cosmos.groundstation.earth <<'EOF'
echo "Adding IPTables rules for UDP port 5012..."

iptables -t nat -C OUTPUT -p udp -d 10.10.10.10 --dport 5012 -j DNAT --to-destination 10.10.20.20:5012 2>/dev/null || {
  echo "Adding OUTPUT DNAT rule..."
  iptables -t nat -A OUTPUT -p udp -d 10.10.10.10 --dport 5012 -j DNAT --to-destination 10.10.20.20:5012
}

iptables -t nat -C PREROUTING -p udp -d 10.10.10.10 --dport 5012 -j DNAT --to-destination 10.10.20.20:5012 2>/dev/null || {
  echo "Adding PREROUTING DNAT rule..."
  iptables -t nat -A PREROUTING -p udp -d 10.10.10.10 --dport 5012 -j DNAT --to-destination 10.10.20.20:5012
}

echo "IPTables rules complete."
EOF
