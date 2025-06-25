# GardenPi

Setup tools for BACnet and EBO Enterprise Server on Raspberry Pi.

## Prerequisites
- Python 3 with pip
- Docker
- Git

## Setup
Run the setup script as **root**:

```bash
sudo bash setup_bacnet.sh
```

The script installs any missing packages, clones the required repositories,
pulls the Enterprise Server Docker image and configures the `bacnet.service`
unit. An update helper is placed at `/root/update_bacnet.sh`.

Check the service status with:

```bash
systemctl status bacnet.service
```

## Contributing
This project uses [Conventional Commits](https://www.conventionalcommits.org/).
Please keep pull requests small and focused.
