#!/bin/bash
set -e

# Update and upgrade system
apt-get update -y
apt-get full-upgrade -y

# Install required packages
apt-get install -y git curl docker.io qemu-user-binfmt qemu-user-static python3-pip

# Force install bacpypes
pip3 install --force-reinstall bacpypes

# Clone or update repositories
cd /root
if [ ! -d BACnet_Pi_Server ]; then
    git clone https://github.com/Shunebre/BACnet_Pi_Server.git
else
    git -C BACnet_Pi_Server pull
fi

if [ ! -d EBO-ES-Raspberry-Pi ]; then
    git clone https://github.com/Shunebre/EBO-ES-Raspberry-Pi.git
else
    git -C EBO-ES-Raspberry-Pi pull
fi

# Pull docker image
docker pull ghcr.io/schneiderelectricbuildings/ebo-enterprise-server:7.0.2.348

# Create update script
cat <<'EOS' >/root/update_bacnet.sh
#!/bin/bash
cd /root/EBO-ES-Raspberry-Pi && git pull
cd /root/BACnet_Pi_Server && git pull
systemctl restart bacnet.service
EOS
chmod +x /root/update_bacnet.sh

# Create systemd service for BACnet server
cat <<'EOS' >/etc/systemd/system/bacnet.service
[Unit]
Description=Local BACnet Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 /root/BACnet_Pi_Server/Bacnet-server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOS

systemctl daemon-reload
systemctl enable bacnet.service
systemctl start bacnet.service
