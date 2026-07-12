#!/bin/bash
#
# Install and configure vsftpd for anonymous FTP access to CFDP file transfer directories.
# Anonymous users can:
#   - Download from received_files (files downloaded from satellite)
#   - Upload to send_files (files to upload to satellite)
#
set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../env.sh"

SEND_DIR="$OPENC3_DIR/send_files"
RECV_DIR="$OPENC3_DIR/received_files"

echo "Installing vsftpd..."
sudo apt-get update -qq
sudo apt-get install -y -qq vsftpd

echo "Creating FTP directories..."
mkdir -p "$SEND_DIR" "$RECV_DIR"

# vsftpd requires the anonymous root to be owned by root and not writable
# We use /srv/ftp as the anon root with symlinks or bind mounts to the actual dirs
FTP_ROOT="/srv/ftp"
sudo mkdir -p "$FTP_ROOT/UPLINK" "$FTP_ROOT/DOWNLINK"

# Bind mount the openc3 directories so FTP sees them
# Remove stale mounts first
sudo umount "$FTP_ROOT/UPLINK" 2>/dev/null || true
sudo umount "$FTP_ROOT/DOWNLINK" 2>/dev/null || true
sudo mount --bind "$SEND_DIR" "$FTP_ROOT/UPLINK"
sudo mount --bind "$RECV_DIR" "$FTP_ROOT/DOWNLINK"

# Set permissions: anon root must be non-writable by ftp user
sudo chown root:root "$FTP_ROOT"
sudo chmod 755 "$FTP_ROOT"

# Upload dir must be writable by ftp (anonymous)
sudo chown ftp:ftp "$FTP_ROOT/UPLINK"
sudo chmod 775 "$FTP_ROOT/UPLINK"

# Download dir readable
sudo chmod 755 "$FTP_ROOT/DOWNLINK"

echo "Configuring vsftpd..."
sudo tee /etc/vsftpd.conf > /dev/null << 'EOF'
# vsftpd configuration for NOS3 CFDP file transfer
listen=YES
listen_ipv6=NO

# Anonymous access
anonymous_enable=YES
local_enable=NO
write_enable=YES

# Anonymous root directory
anon_root=/srv/ftp

# Allow anonymous uploads to /UPLINK (send_files)
anon_upload_enable=YES
anon_mkdir_write_enable=NO
anon_other_write_enable=NO

# Download from /DOWNLINK (received_files)
# Anonymous can read by default

# Security settings
no_anon_password=YES
hide_ids=YES
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100

# Logging
xferlog_enable=YES
xferlog_std_format=YES

# Misc
dirmessage_enable=YES
use_localtime=YES
seccomp_sandbox=NO
EOF

echo "Restarting vsftpd..."
sudo systemctl restart vsftpd
sudo systemctl enable vsftpd

# Make bind mounts persist across reboot
FSTAB_UPLOAD="$SEND_DIR $FTP_ROOT/UPLINK none bind 0 0"
FSTAB_DOWNLOAD="$RECV_DIR $FTP_ROOT/DOWNLINK none bind 0 0"
if ! grep -qF "$FTP_ROOT/UPLINK" /etc/fstab 2>/dev/null; then
    echo "$FSTAB_UPLOAD" | sudo tee -a /etc/fstab > /dev/null
fi
if ! grep -qF "$FTP_ROOT/DOWNLINK" /etc/fstab 2>/dev/null; then
    echo "$FSTAB_DOWNLOAD" | sudo tee -a /etc/fstab > /dev/null
fi

echo ""
echo "FTP configured:"
echo "  Anonymous login: ftp://<groundstation-ip>/"
echo "  Upload files:    PUT to /UPLINK/  → maps to $SEND_DIR"
echo "  Download files:  GET from /DOWNLINK/ → maps to $RECV_DIR"
echo ""
echo "Test: ftp localhost"
echo "  User: anonymous"
echo "  Password: (blank)"
