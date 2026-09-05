# OKD Agent-Based Deployment Guide on Proxmox

**Cluster Name:** `okd`
**Base Domain:** `garrettholland.com`
**Version:** `4.20.0-okd-scos.11`
**Date:** December 2025

This guide documents the steps, configurations, and troubleshooting measures taken to deploy an OKD (SCOS) cluster on Proxmox VE using the Agent-based Installer.

## 1. Prerequisites & Environment

- **Infrastructure:** Proxmox VE (Terraform managed)
- **Networking:**
  - Subnet: `10.0.1.0/24`
  - Gateway: `10.0.1.1` (PFSense)
  - DNS: `10.0.0.1` (Pi-hole/Unbound)
  - DHCP: Static MAC Reservations (Managed by PFSense)
- **Load Balancer:** PFSense HAProxy
- **Workstation:** Fedora Linux with `oc` and `openshift-install` binaries.

### Software Versions

- **OKD Version:** `4.20.0-okd-scos.11`
  - Release Image: `quay.io/okd/scos-release@sha256:f9deda679ec53ad95d5d6b7471daea9dc76b57a12f68fa5ea4040507cf615418`
  - Client Download: [OKD SCOS Releases](https://github.com/okd-project/okd-scos/releases)

---

## 2. Configuration Files

### `install-config.yaml`

Defines the high-level cluster config.
**Key Settings:**

- `replicas`: 3 Masters, 3 Workers
- `networking`: OVNKubernetes
- `pullSecret`: Valid Red Hat Pull Secret (Required)
- `sshKey`: Public key for `core` user access.

### `agent-config.yaml`

Defines specific host configurations for the Agent Installer (SNO/Compact/Standard).
**CRITICAL CONFIGURATION (DNS Fix):**
We explicitly configured **Static DNS** for every node to bypass local resolver issues (`[::1]:53 connection refused`) encountered during bootstrap.

```yaml
apiVersion: v1alpha1
kind: AgentConfig
metadata:
  name: okd
rendezvousIP: 10.0.1.210
hosts:
  - hostname: master-1
    role: master
    interfaces:
      - name: net0
        macAddress: 00:00:00:00:AA:00
    networkConfig:
      interfaces:
        - name: net0
          type: ethernet
          state: up
          mac-address: 00:00:00:00:AA:00
          ipv4:
            enabled: true
            dhcp: true
      # STATIC DNS CONFIGURATION
      dns-resolver:
        config:
          server:
            - 10.0.0.1
# ... repeated for all other nodes ...
```

---

## 3. Infrastructure (Proxmox/Terraform)

Managed via `proxmox/terraform/machines.tf`.
**Hardware Specs:**

- **Master Nodes:**
  - **RAM:** 32GB (Increased from 16GB to fix "No space left on device" during bootstrap)
  - **CPU:** 4 vCPUs (host)
  - **Disk:** 120GB (VirtIO)
- **Worker Nodes:**
  - **RAM:** 16GB
  - **CPU:** 4 vCPUs
  - **Disk:** 120GB (VirtIO)

---

## 4. Load Balancer Configuration (HAProxy)

Configured on PFSense. This was a critical failure point initially.

### VIPs

- **API VIP:** `10.0.1.200` (Ports 6443, 22623)
- **Ingress VIP:** `10.0.1.200` (Ports 80, 443) _(Note: Reused same IP, but different Frontends)_

### Critical Settings (The Fixes)

1.  **Mode:** MUST be **TCP** (Layer 4).
    - **Do NOT** use SSL Offloading/Termination.
    - The OpenShift API and Router expect to handle their own TLS.
2.  **Health Checks:**
    - **Bootstrap Deadlock:** During bootstrap, `master-1` (Rendezvous) needs to serve the Ignition config via the Machine Config Server (Port 22623).
    - If HAProxy Health Checks fail (e.g., checking port 6443 which isn't up yet), it won't forward traffic to 22623, preventing the node from configuring itself.
    - **Fix:** **Disable Health Checks** for `master-1` during bootstrap, or configure a specific check for 22623.
3.  **Ingress Separation (Port 80 vs 443):**
    - **Problem:** A single Frontend listening on 80 & 443 forwarding to a backend pool listening on 80.
    - **Result:** HTTPS traffic was sent to Port 80, causing `http: server gave HTTP response to HTTPS client` errors.
    - **Fix:** Create **Two Separate Frontends/Backends**:
      - **HTTP Frontend (80)** -> `okd-ingress-pool` (Backend Port 80)
      - **HTTPS Frontend (443)** -> `okd-ingress-https` (Backend Port 443) -> **Mode: TCP**

---

## 5. Deployment Process

### Step 1: Generate ISO

Run the installer command from the `okd-agent-based-install` directory:

```bash
# This consumes install-config.yaml and agent-config.yaml
openshift-install --dir=. agent create image
```

**Output:** `agent.x86_64.iso`

### Step 2: Upload ISO

Upload the generated ISO to Proxmox storage (`local:iso/`).

### Step 3: Provision VMs

Use Terraform to destroy old VMs and create new ones with the fresh ISO:

```bash
cd ../proxmox/terraform
terraform apply -auto-approve --var-file=secrets.tfvars
```

### Step 4: Monitor Installation

Wait for the Agent to boot and the cluster to bootstrap:

```bash
openshift-install --dir=. agent wait-for install-complete --log-level=info
```

### Step 5: Verify Access

- **SSH:** `ssh core@master-1` (Should work once bootstrapped).
- **Console:** `https://console-openshift-console.apps.okd.garrettholland.com` (Requires Ingress HAProxy fix).
- **CLI:** `export KUBECONFIG=$(pwd)/auth/kubeconfig && oc get nodes`

---

## 6. Troubleshooting Log

| Issue                   | Symptom                                                        | Root Cause                                                                                       | Fix                                                                                                  |
| :---------------------- | :------------------------------------------------------------- | :----------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------- |
| **OOM / Disk Space**    | `No space left on device` during bootstrap image pull.         | Default 16GB RAM was insufficient for `tmpfs` usage by `podman` on the Rendezvous host.          | Increased Master nodes to **32GB RAM**.                                                              |
| **Ignition Fetch Fail** | `Connection refused` on Port 22623.                            | HAProxy Health Checks marked `master-1` DOWN because API (6443) wasn't up, blocking MCS (22623). | **Disabled Health Checks** on `master-1` in HAProxy.                                                 |
| **DNS Lockup**          | `dial tcp [::1]:53: connection refused` in boot logs.          | Node queried local IPv6 resolver which failed; DHCP settings insufficient.                       | Added explicit **Static DNS (10.0.0.1)** to `agent-config.yaml` for all nodes.                       |
| **Console Crash**       | `context deadline exceeded` / `http response to https client`. | HAProxy Ingress VIP (443) was forwarding to Worker Port 80 (Termination mismatch).               | Changed HAProxy Ingress to **TCP Mode** and split HTTP (80) and HTTPS (443) into separate Frontends. |
