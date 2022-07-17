# Longhorn 

Install iscsi for longhorn

```bash
yum --setopt=tsflags=noscripts install iscsi-initiator-utils
systemctl enable iscsid
systemctl start iscsid
```