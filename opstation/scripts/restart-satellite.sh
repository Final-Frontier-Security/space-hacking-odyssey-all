#!/bin/bash

# Show confirmation popup
zenity --question \
  --title="Restart Satellite?" \
  --text="This will restart the satellite.\n\nAre you sure you want to continue?"

if [ $? -ne 0 ]; then
  echo "User cancelled."
  exit 0
fi

# SSH password
PASSWORD='R6dduYerdbMhYvge_FXVo_4yWx2vYyMaNiEW'

# SSH command block using sshpass
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@10.10.10.10 <<'EOF'
echo "Restarting satellite service on 10.10.10.10..."
sudo reboot
echo "Satellite restarted."
EOF
