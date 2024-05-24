# Fedora WSL

[Fedora on Windows](https://www.linuxfordevices.com/tutorials/linux/install-fedora-on-windows)

A simple Fedora container running on WSL

## Installation Commands

```pwsh
## Get Fedora Base here --> https://koji.fedoraproject.org/koji/packageinfo?packageID=26387

$VERSION="39"
$RELEASE="20240523.0"
$ARCH="x86_64"

wget https://kojipkgs.fedoraproject.org//packages/Fedora-Container-Base/$VERSION/${RELEASE}/images/Fedora-Container-Base-${VERSION}-${RELEASE}.${ARCH}.tar.xz

## extract tar.xz
7z x .\Fedora-Container-Base-${VERSION}-${RELEASE}.${ARCH}.tar.xz

## locate layer.tar for extraction
7z l .\Fedora-Container-Base-${VERSION}-${RELEASE}.${ARCH}.tar | Out-File search.txt
$layerString = Select-String -Raw -Path .\search.txt -Pattern '[0-9a-z]*\\layer.tar'
$layer = $layerString.Split(" ")

## Extract rootfs from tarball
7z e .\Fedora-Container-Base-${VERSION}-${RELEASE}.${ARCH}.tar $layer[-1]

## Import rootfs.tar as a WSL machine
wsl --import fedora $HOME\wsl\fedora layer.tar
```

## Update and add user

```pwsh
wsl -d fedora
```

```bash
sudo dnf update
sudo dnf install -y util-linux passwd cracklib-dicts
useradd -G wheel garrett
passwd garrett
exit

wsl -d fedora -u garrett
## https://learn.microsoft.com/en-us/windows/wsl/wsl-config
printf "[automount]\nenabled = true\n[user]\ndefault = garrett\n" | sudo tee -a /etc/wsl.conf
```
