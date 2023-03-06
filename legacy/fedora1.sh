#!/usr/bin/bash

# 1. Install required software from repositories
dnf update --assumeyes
dnf install --assumeyes epel-release
dnf update --assumeyes
dnf install --assumeyes htop net-tools libguestfs
dnf install --assumeyes curl wget sqlite cronie nano
dnf install --assumeyes hyperv-daemons hyperv-tools hypervvssd

# 2. Install urBackup from package
mkdir /home/vbsadmin/downloads
cd /home/vbsadmin/downloads
wget https://download.opensuse.org/repositories/home:/uroni/CentOS_8_Stream/x86_64/urbackup-server-2.4.15.0-1.10.x86_64.rpm
sleep 30

groupadd urbackup
adduser --create-home -g urbackup urbackup
mkdir /etc/urbackup
echo "/mnt/sdb1/backups" >> /etc/urbackup/backupfolder
chown urbackup:urbackup /etc/urbackup/backupfolder

yum install urbackup-server-2.4.15.0-1.10.x86_64.rpm
systemctl enable urbackup-server

sgdisk -n 0:0:0 -t 0:8300 /dev/sdb
sleep 10
mkfs.ext4 -G 4096 /dev/sdb1
sleep 10
echo "UUID=`lsblk -n --output UUID /dev/sdb1` /mnt/sdb1 ext4 rw,relatime,nobarrier,x-systemd.mount-timeout=600 0 2" >> /etc/fstab
mkdir /mnt/sdb1
mount -a
mkdir /mnt/sdb1/backups
chown -R urbackup:urbackup /mnt/sdb1/backups

systemctl start urbackup-server

firewall-cmd --add-port=55415/tcp
firewall-cmd --add-port=55414/tcp
firewall-cmd --add-port=55413/tcp
firewall-cmd --add-port=35623/udp
firewall-cmd --runtime-to-permanent
firewall-cmd --list-ports

dnf search urbackup
dnf install urbackup-server

fallocate -l 2G /swapfile
chown root:root /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon -s
swapon
swapon /swapfile
free -h

nano /etc/ssh/sshd_config
# PermitRootLogin yes > PermitRootLogin no
systemctl restart sshd.service 