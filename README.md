# GardenPi

Raspberry Pi setup for BACnet and EBO Enterprise Server.

Run the setup script as **root**:

```bash
sudo bash setup_bacnet.sh
```

The script performs system updates and installs the required packages only when they are not already present. It then clones the BACnet and EBO repositories, pulls the Enterprise Server Docker image and sets up a `bacnet.service` systemd unit. An update helper is saved at `/root/update_bacnet.sh` which pulls the latest code and restarts the service.
