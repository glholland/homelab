# Microshift

Ben's homelab allowed me to enable the console locally for testing

[Microshift Homelab](https://medium.com/@ben.swinney_ce/microshift-homelab-ddf57864c1d00)

[OKD CRC Docs](https://www.okd.io/crc/)

[CRC Binaries](https://developers.redhat.com/content-gateway/rest/mirror2/pub/openshift-v4/clients/crc/latest/)

Setup local for CRC

```bash
crc setup
```

Set Config for which flavor to deploy locally. Defaults to OpenShift but there exist options...

```bash
crc config set preset microshift  # okd
crc start
```

... and voila... you have a local cluster of your choosing!
