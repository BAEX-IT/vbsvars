#!/bin/bash

apt -y install hyperv-daemons

# apt -y install linux-headers-`uname -r`
# repo="deb http://deb.debian.org/debian buster-backports main contrib non-free"
# echo "$repo" | tee -a /etc/apt/sources.list
# apt update
# apt -y install zfs-dkms zfsutils-linux
# systemctl enable zfs.target
# systemctl enable zfs-import-cache
# systemctl enable zfs-mount
# systemctl enable zfs-import.target
# systemctl enable zfs-import-scan
# systemctl enable zfs-share
# dmesg | grep ZFS

apt -y install net-tools ethtool parted
apt -y install htop sdparm sysstat curl
apt -y install bash-completion
apt -y install git mc
apt -y install debian-keyring software-properties-common

# Download key
curl -fsSL -o /usr/share/keyrings/salt-archive-keyring.gpg https://repo.saltproject.io/py3/debian/10/amd64/latest/salt-archive-keyring.gpg
# Create apt sources list file
echo "deb [signed-by=/usr/share/keyrings/salt-archive-keyring.gpg] https://repo.saltproject.io/py3/debian/10/amd64/latest buster main" | tee /etc/apt/sources.list.d/salt.list

# Setup Python Latest
sudo apt install python3-pip
sudo -H pip3 install --upgrade pip

# Setup NodeJS LTS
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g npm

apt -y install git
git config --global user.email "user@email.com"
git config --global user.name "Artyom Tsybulkin"

# Download the Microsoft repository GPG keys
wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb
# Register the Microsoft repository GPG keys
dpkg -i packages-microsoft-prod.deb
# Update the list of products
apt-get update
# Install PowerShell
apt-get install -y powershell
# Start PowerShell
pwsh

