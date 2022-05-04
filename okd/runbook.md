# Setup hypervisor for OKD install
https://blog.maumene.org/2020/11/18/OKD-or-OpenShit-in-one-box.html#network

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

I ended up disabling SELinux however these are somethings I tried before giving up

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

## TODO: Initial OAuth config

## Scale replicas down for 1 master running
```bash
oc scale --replicas=1 ingresscontroller/default -n openshift-ingress-operator
oc scale --replicas=1 deployment.apps/console -n openshift-console
oc scale --replicas=1 deployment.apps/downloads -n openshift-console
oc scale --replicas=1 deployment.apps/oauth-openshift -n openshift-authentication
oc scale --replicas=1 deployment.apps/packageserver -n openshift-operator-lifecycle-manager

oc scale --replicas=1 deployment.apps/prometheus-adapter -n openshift-monitoring
oc scale --replicas=1 deployment.apps/thanos-querier -n openshift-monitoring
oc scale --replicas=1 statefulset.apps/prometheus-k8s -n openshift-monitoring
oc scale --replicas=1 statefulset.apps/alertmanager-main -n openshift-monitoring
```

## Tune for 1 master 1 worker setup 
```bash
cat << EOF > etcd-quorum.yaml
- op: add
  path: /spec/overrides
  value:
  - kind: Deployment
    group: apps/v1
    name: etcd-quorum-guard
    namespace: openshift-machine-config-operator
    unmanaged: true
EOF
```
```bash
oc patch clusterversion version --type json -p "$(cat etcd-quorum.yaml)"
oc scale --replicas=1 deployment/etcd-quorum-guard -n openshift-machine-config-operator
oc label node worker.okd.garrettholland.com node-role.kubernetes.io/infra="true"
oc patch -n openshift-ingress-operator ingresscontroller/default --patch '{"spec":{"replicas": 1,"nodePlacement":{"nodeSelector":{"matchLabels":{"node-role.kubernetes.io/infra":"true"}}}}}' --type=merge
oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"defaultRoute":true}}'
```