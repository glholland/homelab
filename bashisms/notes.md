# Bashisms

Add SSH keys _the easy way_

```bash
ssh-copy-id ${USER}@${IP}
```

Remove old known hosts

```bash
ssh-keygen -f "${HOME}/.ssh/known_hosts" -R ${IP}
```
