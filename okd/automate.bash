# https://blog.maumene.org/2020/11/18/OKD-or-OpenShit-in-one-box.html
# Make sure all VMs are stopped
for i in $(virsh list --all | awk ' { print $2 }' | tail -n +3);
do
	virsh undefine $i
	virsh destroy $i
done
# Delete all existing datas
rm -rf /data/okd
rm -rf /data/*.qcow2
rm -rf /data/*.raw
rm -rf ~/.ssh/known_hosts
rm openshift-install-linux* openshift-client-linux* oc kubectl openshift-install

# Create okd directory of openshift-install files
mkdir /data/okd
# Copy the install-config.yaml
cp install-config.yaml /data/okd/

# Download openshift-install and openshift-client
wget $(curl https://api.github.com/repos/openshift/okd/releases/latest | grep openshift-install-linux | grep browser_download_url | cut -d\" -f4)
wget $(curl https://api.github.com/repos/openshift/okd/releases/latest | grep openshift-client-linux | grep browser_download_url | cut -d\" -f4)
tar xvzf openshift-install-linux*
tar xvzf openshift-client-linux*

# Create the ignition files
./openshift-install create ignition-configs --dir=/data/okd

# Download the latest Fedora CoreOS
coreos-installer download -p qemu -C /data -d -f qcow2.xz
chown -R qemu:qemu /data

j=0
for VM_NAME in bootstrap master worker;
do
	IGNITION_CONFIG="/data/okd/${VM_NAME}.ign"
	IMAGE="/data/${VM_NAME}.raw"
	VCPUS="8"
	RAM_MB="30000"
	SIZE="200G"
	MAC="52:54:00:00:00:2$j" #Generate the MAC addresses to match the libvirt network configuration

	qemu-img create "${IMAGE}" "${SIZE}" -f raw

	virt-resize --expand /dev/sda4 /data/fedora-coreos-*.qcow2 "${IMAGE}"
  # When I'm creating the worker, I'm stopping the bootstrap VM
	if [ "$VM_NAME" = "worker" ]; then
		virsh destroy bootstrap
	fi;

	virt-install --connect="qemu:///system" --name="${VM_NAME}" --vcpus="${VCPUS}" --memory="${RAM_MB}" \
		--os-variant="fedora-coreos-stable" --import --graphics="none" --network network=default,model=virtio,mac="${MAC}" \
		--disk="${IMAGE},cache=none" --cpu="host-passthrough" --noautoconsole \
		--qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}"
  # If I'm deploying the master it means the bootstrap is launched already and I can wait for the bootstrap process to end before I setup my worker.
	if [ "$VM_NAME" = "master" ]; then
		./openshift-install --dir=/data/okd wait-for bootstrap-complete
	fi;

	j=$((j+1))
done