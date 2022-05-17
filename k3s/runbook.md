# K3S VM install

Install machines plugin for cockpit
```bash
sudo dnf install cockpit-machines
sudo mkdir /home/vm
```

Install master vm

```bash
wget https://gist.github.com/glholland/f4895e1c1a9fc7114605971c60b2ba96 -O ks-master1.cfg
virt-install \
    --noautoconsole \
	--graphics vnc \
    --name master-1 \
    --memory 4096 \
    --vcpus 4 \
    --network bridge=br0 \
    --disk /home/vm/k3s-master.img,,format=raw,size=25 \
    --os-variant fedora35 \
    --location /home/vm/Fedora-Server-dvd-x86_64-36-1.5.iso \
    --initrd-inject ks-master1.cfg \
    --extra-args="\
            auto=true priority=critical vga=normal hostname=k3s-server inst.ks=file:/ks-master1.cfg"
```


Install k3s
```bash
curl -sfL https://get.k3s.io | sh -
```

Install worker
```bash
virt-install \
    --noautoconsole \
	--graphics vnc \
    --name worker-1 \
    --memory 4096 \
    --vcpus 4 \
    --network bridge=br0 \
    --disk /home/vm/k3s-worker1.img,,format=raw,size=25 \
    --os-variant fedora35 \
    --location https://download.fedoraproject.org/pub/fedora/linux/releases/36/Server/x86_64/os/ \
    --initrd-inject ks-worker1.cfg \
    --extra-args="\
            auto=true priority=critical vga=normal hostname=k3s-worker-1 inst.ks=file:/ks-worker1.cfg"
```

Start stopped vms
```bash
virsh list --state-shutoff --name | xargs virsh start
```

---

# Installing K3d on Rocky Linux & Podman
https://k3d.io/
https://k3d.io/v5.4.0/usage/advanced/podman/

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


