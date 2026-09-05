# DNS & Ingress Configuration

This directory documents the DNS and Ingress configuration managed by pfSense.

## DNS Overrides (Unbound)

The following DNS overrides are configured in pfSense Unbound DNS Resolver to route traffic to the appropriate internal IPs.

### OKD & Lab Wildcards

| Domain                           | Type     | Target IP    | Description               |
| :------------------------------- | :------- | :----------- | :------------------------ |
| `*.lab.garrettholland.com`       | Redirect | `10.0.1.199` | Lab Ingress VIP (HAProxy) |
| `*.apps.okd.garrettholland.com`  | Redirect | `10.0.1.200` | OKD Ingress VIP           |
| `api.okd.garrettholland.com`     | A Record | `10.0.1.200` | OKD API                   |
| `api-int.okd.garrettholland.com` | A Record | `10.0.1.200` | OKD Internal API          |

### Static Hosts

| Host                         | IP           | Description        |
| :--------------------------- | :----------- | :----------------- |
| `pfsense.garrettholland.com` | `10.0.0.1`   | Router/Firewall    |
| `pve.garrettholland.com`     | `10.0.0.100` | Proxmox VE         |
| `truenas.garrettholland.com` | `10.0.0.240` | NAS                |
| `unifi.garrettholland.com`   | `10.0.0.230` | Network Controller |

### Cluster Nodes

| Node                          | IP           | Role          |
| :---------------------------- | :----------- | :------------ |
| `master-1.garrettholland.com` | `10.0.1.210` | Control Plane |
| `master-2.garrettholland.com` | `10.0.1.211` | Control Plane |
| `master-3.garrettholland.com` | `10.0.1.212` | Control Plane |
| `worker-1.garrettholland.com` | `10.0.1.213` | Worker        |
| `worker-2.garrettholland.com` | `10.0.1.214` | Worker        |
| `worker-3.garrettholland.com` | `10.0.1.215` | Worker        |

## HAProxy Configuration (pfSense)

pfSense HAProxy is used to route traffic for `*.lab.garrettholland.com` to the OKD worker nodes where the `lab` IngressController is listening on NodePorts.

### Frontend: `okd-lab-https`

- **Listen IP**: `10.0.1.199`
- **Port**: `443`
- **ACL**: Matches `*.lab.garrettholland.com` (SNI)
- **Backend**: `okd-lab-https-backend`

### Backend: `okd-lab-https-backend`

- **Mode**: TCP
- **Balance**: Roundrobin
- **Health Check**: Basic TCP Connection
- **Servers**:
  - `worker1`: `10.0.1.213:30201 check`
  - `worker2`: `10.0.1.214:30201 check`
  - `worker3`: `10.0.1.215:30201 check`

### Frontend: `okd-lab-http`

- **Listen IP**: `10.0.1.199`
- **Port**: `80`
- **ACL**: Matches `*.lab.garrettholland.com` (Host header)
- **Backend**: `okd-lab-http-backend`

### Backend: `okd-lab-http-backend`

- **Mode**: HTTP
- **Balance**: Roundrobin
- **Health Check**: Basic TCP Connection
- **Servers**:
  - `worker1`: `10.0.1.213:30577 check`
  - `worker2`: `10.0.1.214:30577 check`
  - `worker3`: `10.0.1.215:30577 check`
