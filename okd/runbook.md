# Setup hypervisor for OKD install

This assumes the hypervisor will also be running HAProxy for the loadbalancer.

## Install dependencies
```bash
sudo dnf install libvirt-devel libvirt-daemon-kvm libvirt-client libguestfs-tools-c virt-install
```
...if running loadbalancer on hypervisor
```bash
sudo dnf install haproxy -y
```

## Start libvirtd
```bash
sudo systemctl enable --now libvirtd
```

## Configure default libvirt network
```bash
virsh net-create --file virsh-network/network.xml
```


## Needed if using SELinux
### https://stackoverflow.com/questions/34793885/haproxy-cannot-bind-socket-0-0-0-08888
### Resolves 'Starting frontend machine_config: cannot bind socket [0.0.0.0:22623]' error that causes HAProxy to fail

I ended up disabling SELinux...

```bash
setsebool -P haproxy_connect_any=1
```
```bash
semanage import <<EOF
boolean -D
login -D
interface -D
user -D
port -D
node -D
fcontext -D
module -D
ibendport -D
ibpkey -D
permissive -D
boolean -m -1 virt_sandbox_use_all_caps
boolean -m -1 virt_use_nfs
port -a -t http_port_t -r 's0' -p tcp 6443
port -a -t http_port_t -r 's0' -p tcp 22623
fcontext -a -f a -t virt_image_t -r 's0' '/data'
fcontext -a -f a -t virt_image_t -r 's0' '/data(/.*)?'
fcontext -a -f a -t virt_image_t -r 's0' '/data/okd(/.*)?'
EOF
```
#### Disable SELinux if needed
https://www.shellhacks.com/disable-selinux/

## Copy HAProxy cfg
...if running that on hypervisor
```bash
cp haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
systemctl restart haproxy
```

## TODO: Firewall settings. 🙃