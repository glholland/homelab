# PiHole podman container as a service

Remove systemd-resolve from being controlled by Network Manager
```bash
sudo nmcli connection modify br0 ipv4.method manual
sudo nmcli connection modify br0 ipv4.addresses 192.168.0.200/24
sudo nmcli connection modify br0 ipv4.gateway 192.168.0.1
```

```bash
sudo nmcli connection modify br0 ipv4.dns "8.8.8.8 8.8.4.4"
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
sudo unlink /etc/resolv.conf
sudo systemctl restart NetworkManager
```

Update firewall to allow pihole stuff
```bash
sudo firewall-cmd --zone=public --add-port=80/tcp
sudo firewall-cmd --zone=public --add-port=443/tcp
sudo firewall-cmd --zone=public --add-port=53/tcp
sudo firewall-cmd --zone=public --add-port=53/udp
sudo firewall-cmd --zone=public --add-port=67/udp
sudo firewall-cmd --permanent --zone=public --add-port=53/udp
sudo firewall-cmd --permanent --zone=public --add-port=53/tcp
sudo firewall-cmd --permanent --zone=public --add-port=443/tcp
sudo firewall-cmd --permanent --zone=public --add-port=67/udp
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --reload
```

Create volumes for podman
```bash
podman volume create pihole_pihole
podman volume create pihole_dnsmasq
```

```bash
podman run \
–-name=pihole \
-e TZ=America/Los_Angeles \
-e WEBPASSWORD=Password1 \
-e SERVERIP=192.168.0.200 \
–v pihole_pihole:/etc/pihole:Z \
-v pihole_dnsmasq:/etc/dnsmasq.d:Z \
–-dns=127.0.0.1 \
–-dns=1.1.1.1 \
-p 80:80 \
-p 67:67/udp \
-p 192.168.0.200:53:53/udp \
pihole/pihole
```

podman run --name=pihole -e TZ=America/Detroit -e WEBPASSWORD=Password1 -e SERVERIP=192.168.0.200 -v pihole_pihole:/etc/pihole:Z -v pihole_dnsmasq:/etc/dnsmasq.d:Z --dns=127.0.0.1 --dns=1.1.1.1 -p 80:80 -p 67:67/udp -p 192.168.0.200:53:53/udp pihole/pihole

Add Pihole as a service --> `/etc/systemd/system/pihole.service`
```cfg
[Unit]
Description=Pi-Hole Podman Container
After=firewalld.service

[Service]
ExecStart=/usr/bin/podman run --name=pihole --hostname=pi-hole --cap-add=NET_ADMIN --dns=127.0.0.1 --dns=1.1.1.1 -e TZ=America/Detroit -e SERVERIP=192.168.1.20 -e WEBPASSWORD=Password1 -e DNS1=1.1.1.1 -e DNS2=1.0.0.1 -e DNSSEC=true -e CONDITIONAL_FORWARDING=true -e CONDITIONAL_FORWARDING_IP=192.168.0.1 -e CONDITIONAL_FORWARDING_DOMAIN=lan -e TEMPERATUREUNIT=c -v pihole_pihole:/etc/pihole:Z -v pihole_dnsmasq:/etc/dnsmasq.d:Z -p 80:80/tcp -p 443:443/tcp -p 67:67/udp -p 53:53/tcp -p 53:53/udp pihole/pihole
ExecStop=/usr/bin/podman stop -t 2 pihole
ExecStopPost=/usr/bin/podman rm pihole

[Install]
WantedBy=multi-user.target
```

```bash
# https://jreypo.io/2021/03/12/running-pihole-as-a-podman-container-in-fedora/

# Needed for SELinux
# setsebool -P container_manage_cgroup on

sudo systemctl enable pihole.service
sudo systemctl start pihole.service
```

podman run \
–-name=mypihole \
-e TZ=America/Los_Angeles \
-e WEBPASSWORD=Password1 \
-e SERVERIP=192.168.1.103 \
–v pihole_pihole:/etc/pihole:Z \
-v pihole_dnsmasq:/etc/dnsmasq.d:Z \
–dns=127.0.0.1 –dns=1.1.1.1 \
-p 80:80 \
-p 67:67/udp \
-p 192.168.1.103:53:53/udp \
pihole/pihole
```

