# GitHub Copilot Instructions

## Project Context

This is a homelab infrastructure repository managing Kubernetes (OKD), Proxmox, and Cloud resources.

- **OS**: Fedora Linux (primary workstation).
- **Orchestration**: Kubernetes (OKD/OpenShift).
- **Automation**: Ansible, Terraform, Kustomize.

## Directory Structure & Architecture

- **`kubernetes/`**: Application manifests. One directory per app (e.g., `kubernetes/authentik/`).
- **`ansible/`**: System configuration playbooks (`ansible/playbooks/`).
- **`okd/`**: OpenShift specific configuration and installation. See `okd/README.md`.
- **`proxmox/`**: Infrastructure as Code for Proxmox VE.
- **`cloud/`**: Cloud provider configurations.
- **`dns/`**: DNS configurations. See `dns/pihole_install.md`.

## Critical Workflows & Patterns

### 0. Environment Setup

- **Fedora Workstation**: The root `README.md` contains scripts for setting up the local development environment (ZSH, Brew, VS Code, kubectl).

### 1. Kubernetes Manifest Management (Helm -> Kustomize)

**DO NOT** use Helm directly in the cluster. We use a "Hydrated Helm" pattern.

- **Pattern**: Render Helm charts to static YAML, split by Kind, and manage via Kustomize.
- **Structure**:
  ```text
  app/
  ├── values.yaml        # Source of truth for Helm values
  ├── base/              # Generated static manifests (NEVER EDIT MANUALLY)
  └── overlays/          # Environment patches (e.g., overlays/okd/)
  ```
- **Generation Command**: Use `helm template` + `kfilt` to regenerate `base/`.
  _Reference_: See `kubernetes/metallb/README.md` for the canonical script.

### 2. OpenShift/OKD Specifics

- **Security Context Constraints (SCC)**: Apps often need privileged SCCs.
  _Example_: See `kubernetes/metallb/overlays/okd/rolebinding.yaml` for granting `system:openshift:scc:privileged`.
- **Security Contexts**: Remove `fsGroup`, `runAsUser` in OKD overlays as OpenShift handles this dynamically.
  _Example_: See `kubernetes/metallb/overlays/okd/deployment-patch.yaml`.
- **Lab Ingress Controller**: Internal services on `*.lab.garrettholland.com` use a custom IngressController.
  - **Requirement**: Routes MUST have the label `type: lab` to be picked up by this controller.
  - **Certificate**: Managed via `okd/lab-wildcard-cert.yaml`.
- **CLI**: Prefer `oc` over `kubectl` when working in OKD contexts.

### 3. Ansible

- **Location**: Playbooks are in `ansible/playbooks/`.
- **Idempotency**: Ensure all tasks can be run multiple times without side effects.

## Development Guidelines

- **New Apps**: Create a new directory in `kubernetes/<app-name>`.
- **Edits**: When modifying K8s apps, check if it's a Helm-based app. If so, edit `values.yaml` and regenerate `base/`, or add a patch in `overlays/`. Do not edit `base/*.yaml` directly.
- **Networking**: MetalLB is used for LoadBalancing. L2Advertisements are required for ARP.
- **Documentation**: Every `kubernetes/<app>` directory MUST have a `README.md` following the `kubernetes/metallb/README.md` template. It should include:
  - **Hydration Script**: The exact `helm template` + `kfilt` command used to generate `base/`.
  - **OKD Specifics**: Any SCCs, Route configurations, or security context patches required.
  - **Manual Steps**: Any secrets or one-off commands (e.g., `openssl` generation).
  - **Testing**: Commands to verify the deployment (e.g., `curl`, `oc get svc`).
