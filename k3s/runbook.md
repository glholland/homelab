# K3S VM install

Install machines plugin for cockpit

```bash
sudo dnf install cockpit-machines
sudo mkdir /home/vm
```

Install master vm

```bash
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
    --location /home/vm/Fedora-Server-dvd-x86_64-36-1.5.iso \
    --initrd-inject ks-worker1.cfg \
    --extra-args="\
            auto=true priority=critical vga=normal hostname=k3s-worker-1 inst.ks=file:/ks-worker1.cfg"
```

Start stopped vms

```bash
virsh list --state-shutoff --name | xargs virsh start
```

Install k3s server

```bash
curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode '0644' --node-taint 'node-role.kubernetes.io/master=true:NoSchedule' --disable 'traefik'

cat /var/lib/rancher/k3s/server/node-token
```

K3s docs say to remove FW on RHEL

```bash
# https://rancher.com/docs/k3s/latest/en/advanced/#additional-preparation-for-red-hat-centos-enterprise-linux
systemctl disable firewalld --now
```

[AV K3S Agent install](https://github.com/ArthurVardevanyan/HomeLab/blob/production/main.bash#L236-L241)

```bash
curl -sfL https://get.k3s.io | K3S_URL='https://192.168.1.210:6443' K3S_TOKEN="" sh - agent --node-label 'node_type=worker'
```

Install iscsi for longhorn

```bash
yum --setopt=tsflags=noscripts install iscsi-initiator-utils
systemctl enable iscsid
systemctl start iscsid
```

---

Get kubeconfig and do more things

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```
