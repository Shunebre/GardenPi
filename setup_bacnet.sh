#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LOG_FILE=/var/log/gardenpi_setup.log
exec > >(tee -a "$LOG_FILE") 2>&1

run_cmd() {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "Error running command: $*" >&2
        exit $status
    fi
}

apt-get update -y
apt-get full-upgrade -y

command -v git >/dev/null || apt-get install -y git
command -v curl >/dev/null || apt-get install -y curl
command -v docker >/dev/null || apt-get install -y docker.io
command -v pip3 >/dev/null || apt-get install -y python3-pip

if ! dpkg -s qemu-user-static >/dev/null 2>&1 && ! dpkg -s qemu-user-binfmt >/dev/null 2>&1; then
    apt-get install -y qemu-user-static || apt-get install -y qemu-user-binfmt
else
    echo "qemu user binaries already installed"
fi

if ! python3 -c "import bacpypes" &>/dev/null; then
    pip3 install bacpypes
fi

if [ ! -d /opt/bacpypes ]; then
    run_cmd git clone https://github.com/JoelBender/bacpypes.git /opt/bacpypes
fi

cd /root
if [ ! -d BACnet_Pi_Server ]; then
    run_cmd git clone https://github.com/Shunebre/BACnet_Pi_Server.git
else
    run_cmd git -C BACnet_Pi_Server pull
fi

if [ ! -d EBO-ES-Raspberry-Pi ]; then
    run_cmd git clone https://github.com/Shunebre/EBO-ES-Raspberry-Pi.git
else
    run_cmd git -C EBO-ES-Raspberry-Pi pull
fi

run_cmd docker image pull ghcr.io/schneiderelectricbuildings/ebo-enterprise-server:latest

cat <<'EOS' >/root/update_bacnet.sh
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE=/var/log/bacnet_update.log
exec > >(tee -a "$LOG_FILE") 2>&1

changed=0

cd /root/BACnet_Pi_Server
git fetch origin
if [ "$(git rev-parse HEAD)" != "$(git rev-parse @{u})" ]; then
    git pull
    changed=1
fi

cd /root/EBO-ES-Raspberry-Pi
git fetch origin
if [ "$(git rev-parse HEAD)" != "$(git rev-parse @{u})" ]; then
    git pull
    changed=1
fi

if [ $changed -eq 1 ]; then
    systemctl restart bacnet.service
fi
EOS
chmod +x /root/update_bacnet.sh

cat <<'EOS' >/etc/systemd/system/bacnet.service
[Unit]
Description=BACnet Daemon (GardenPi)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=bacnet
WorkingDirectory=/opt/bacnet
ExecStart=/usr/local/bin/bacnet-daemon --config /etc/bacnet/config.yaml
Restart=on-failure
RestartSec=5
TimeoutStartSec=30
KillMode=control-group

[Install]
WantedBy=multi-user.target
EOS

systemctl daemon-reload
systemctl is-enabled bacnet.service >/dev/null 2>&1 || systemctl enable bacnet.service
systemctl start bacnet.service
