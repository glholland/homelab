# OKD

[Installing an OpenShift Container Platform cluster with the Agent-based Installer](https://docs.openshift.com/container-platform/4.16/installing/installing_with_agent_based_installer/installing-with-agent-based-installer.html#agent-install-verifying-architectures_installing-with-agent-based-installer)

## Install Dependencies

### kubectl

add upstream repo to yum

```bash
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
EOF
```

and then install

```bash
sudo yum install -y kubectl
```

### openshift-installer and oc client(okd)

Download, extract, and move to bin

```bash
wget https://github.com/okd-project/okd/releases/download/4.15.0-0.okd-2024-03-10-010116/openshift-install-linux-4.15.0-0.okd-2024-03-10-010116.tar.gz -O /tmp/openshift-install.tar.gz

tar xzf /tmp/openshift-install.tar.gz -C ~/bin
```

```bash
wget https://github.com/okd-project/okd/releases/download/4.15.0-0.okd-2024-03-10-010116/openshift-client-linux-4.15.0-0.okd-2024-03-10-010116.tar.gz -O /tmp/openshift-client.tar.gz

tar xzf /tmp/openshift-client.tar.gz -C ~/bin
```

### Configure pfsense VIP

...

### Configure HA Proxy for LoadBalancing

...

### Configure `agent-config` and `install-config`

[OCP Docs | Creating the preferred config inputs](https://docs.openshift.com/container-platform/latest/installing/installing_with_agent_based_installer/installing-with-agent-based-installer.html#installing-ocp-agent-inputs_installing-with-agent-based-installer)

### Create working dir and prep for deployment

The configs will be consumed, run the next part on copies of the originals.

#### Generate manifests and agent iso

Create manifests

```bash
openshift-install --dir . agent create cluster-manifests
```

Create iso (consumes configs)

```bash
openshift-install --dir . agent create image
```

### Copy iso to proxmox

```bash
scp agent.x86_64.iso  ${USER}@${PVE_IP}:/var/lib/vz/template/iso
```

### Stand up nodes in proxmox

Use this command to standup all nodes with the agent ISO attached and boot order set with the targeted installation disk first so after installation the node boots correctly.

```bash
cd proxmox/terraform
terraform apply --var-file=secrets.tfvars
```

## Installation

Use these commands to troubleshoot and watch the installation

### openshift-install utility

[OCP Docs | Tracking and verifying install progress](https://docs.openshift.com/container-platform/latest/installing/installing_with_agent_based_installer/installing-with-agent-based-installer.html#installing-ocp-agent-verify_installing-with-agent-based-installer)

[OKD Docs | Troubleshooting Installations](https://docs.okd.io/latest/support/troubleshooting/troubleshooting-installations.html)

This watches the install from outside the cluster, where you initially generated the iso.

```bash
openshift-install --dir . agent wait-for install-complete --log-level=info
```

... or to watch it until completion

```bash
openshift-install --dir .working-dir/ agent wait-for install-complete --log-level=debug
```

...or tail the install log

```bash
tail -f ~/<installation_directory>/.openshift_install.log
```

### Watch node logs via SSH

SSH into each node and you can view these key services running.

```bash
ssh core@${NODE_IP} -i ~/.ssh/key

# Watch all logs
journalctl -f

# Watch the bootkube service
journalctl -b -f -u bootkube.service

# Watch the kubelet service
journalctl -b -f -u kubelet.service
```

### Watch logs when API is up

```bash
# Watch crio logs or other services
oc adm node-logs --role=master -u crio --kubeconfig auth/kubeconfig

# Watch the cluster operators role
watch -n 3 oc get co --kubeconfig auth/kubeconfig
```

Check out the console when it's up

[Your new OKD console](https://console-openshift-console.apps.okd.garrettholland.com/dashboards)
