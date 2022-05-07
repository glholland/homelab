# Installing K3d on Rocky Linux & Podman
# https://k3d.io/
# https://k3d.io/v5.4.0/usage/advanced/podman/

## Install via bash script 
```bash
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

## Enable Podman
```bash
systemctl enable --now podman.socket
```

## Make sym link from docker's socket to podman's socket
... for maximum trickery
```bash
ln -s /run/podman/podman.sock /var/run/docker.sock
```


