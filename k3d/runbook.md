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

# Ok so you need Podman 4 which isn't in any repo yet... 



## Docker installation

### Install
```bash
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf update
sudo dnf install -y docker-ce docker-ce-cli containerd.io --allowerasing
# Allow erasing flag requiredd to erase any other nasty CNCF container managing technologies (ew...)
sudo systemctl enable docker
sudo systemctl start docker
```

### Install docker-cockpit
Download docker-cockpit and unzip into 
```bash
wget https://github.com/mrevjd/cockpit-docker/releases/download/v2.0.3/cockpit-docker.tar.gz
cp cockpit-docker.tar.gz /usr/share/cockpit/
sudo tar xf cockpit-docker.tar.gz -C .
```


