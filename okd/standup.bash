#!/bin/bash

#set -o errexit
#set -o pipefail
#set -o nounset

BLUE='\033[1;34m'
NC='\033[0m'

# Delete all virtual machines
for i in $(virsh list --all | awk ' { print $2 }' | tail -n +3);
do
	virsh undefine $i
	virsh destroy $i
done
# Delete all existing datas
echo -e "\n${BLUE}Deleting existing files in data...${NC}"
rm -rf /home/data/okd
rm -rf /home/data/*.qcow2
rm -rf /home/data/*.raw
rm -rf /home/data/fedora-coreos*
rm -rf ~/.ssh/known_hosts
rm -f openshift-install-linux* openshift-client-linux* oc kubectl openshift-install

# Create okd directory of openshift-install files
echo -e "\n${BLUE}Make okd dir...${NC}"
mkdir /home/data/okd

# Copy the install-config.yaml
echo -e "\n${BLUE}Copy install config...${NC}"
cp install-config.yaml /home/data/okd/

# Download the latest Fedora CoreOS
echo -e "\n${BLUE}Downloading Fedora Coreos...${NC}"
COREOS=35.20220227.3.0
wget https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/"${COREOS}"/x86_64/fedora-coreos-"${COREOS}"-qemu.x86_64.qcow2.xz -P /home/data
echo -e "\n${BLUE}Unzipping Fedora Coreos...${NC}"
xz -d -T10 /home/data/fedora-coreos-*.xz -v

# Download openshift-install and openshift-client
echo -e "\n${BLUE}Download openshift-install and openshift-client...${NC}"
wget "$(curl https://api.github.com/repos/openshift/okd/releases/latest | grep openshift-install-linux | grep browser_download_url | cut -d\" -f4)"
wget "$(curl https://api.github.com/repos/openshift/okd/releases/latest | grep openshift-client-linux | grep browser_download_url | cut -d\" -f4)"
echo -e "\n${BLUE}Unzipping openshift-install and openshift-client...${NC}"
tar xvzf openshift-install-linux*
tar xvzf openshift-client-linux*

# Create the ignition files
echo -e "\n${BLUE}Create ign files...${NC}"
./openshift-install create ignition-configs --dir=/home/data/okd --log-level debug

# Download the latest Fedora CoreOS
# coreos-installer download -p qemu -C /home/data -d -f qcow2.xz

chown -R qemu:qemu /home/data

j=0
for VM_NAME in bootstrap master worker;
do
	IGNITION_CONFIG="/home/data/okd/${VM_NAME}.ign"
	IMAGE="/home/data/${VM_NAME}.raw"
	VCPUS="4"
	RAM_MB="16384"
	SIZE="50G"
	MAC="52:54:00:00:00:2$j" #Generate the MAC addresses to match the libvirt network configuration

	echo -e "\n${BLUE}Create virt disk in raw format...${NC}"
	qemu-img create "${IMAGE}" "${SIZE}" -f raw
	echo -e "\n${BLUE}Expand cloud disk...${NC}"
	virt-resize --expand /dev/sda4 /home/data/fedora-coreos-*.qcow2 "${IMAGE}"

  # When I'm creating the worker, I'm stopping the bootstrap VM
	if [ "$VM_NAME" = "worker" ]; then
		echo -e "\n${BLUE}Creating worker...${NC}"
		RAM_MB="12288"
	fi;
	
	echo -e "\n${BLUE}Installing machine...${NC}"
	virt-install --connect="qemu:///system" \
		--name="${VM_NAME}" \
		--vcpus="${VCPUS}" \
		--memory="${RAM_MB}" \
		--os-variant="fedora-coreos-stable" \
		--import \
		--graphics vnc \
		--network network=kubernetes,model=virtio,mac="${MAC}" \
		--disk="${IMAGE},cache=none" \
		--cpu="host-passthrough" \
		--noautoconsole \
		--qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}"

  	### # If I'm deploying the master it means the bootstrap is launched already and I can wait for the bootstrap process to end before I setup my worker.
	if [ "$VM_NAME" = "master" ]; then
		echo -e "\n${BLUE}Waiting for bootstraping to complete...${NC}"
		# Wait 1200 secs and then wait for bootstrap, then make Worker node and wait for bootstrap again cause slow CPU
		while !
		do
			sleep 1200
			./openshift-install --dir=/home/data/okd wait-for bootstrap-complete --log-level debug
		done
	fi;
	j=$((j+1))
done
echo -e "\n${BLUE}Exiting loops, machines created, now waiting for completion of standup...${NC}"
./openshift-install --dir=/home/data/okd wait-for bootstrap-complete --log-level debug
./openshift-install --dir=/home/data/okd wait-for install-complete --log-level debug

echo -e "\n${BLUE}FIN!${NC}"
