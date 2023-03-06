#!/usr/bin/bash

# Notes
# 07-2022 Swap file/partition replaced by zram filesystem

set_tasks() {
    task1="*/20 * * * * /usr/bin/flock -n /tmp/do_cleanup.lock /autolinux/scripts/do_cleanup.sh"
}

start_cleanup() {
    sync && echo 3 > /proc/sys/vm/drop_caches
}

start_recovery() {
    if [ -z "$1" ];
    then
        systemctl stop urbackupsrv.service
        start_cleanup
        urbackupsrv repair-database
        urbackupsrv cleanup-unknown
        urbackupsrv defrag-database
        start_cleanup
        systemctl start urbackupsrv.service
    fi
}

start_refresh() {
    p=`pidof urbackupsrv`
    t=`cat /proc/meminfo | grep MemTotal: | awk '{print $2}'`
    f=`cat /proc/meminfo | grep MemFree: | awk '{print $2}'`
    # If free memory less than 80% then do cleanup
    if [ `expr 100 \* $f / $t` -lt 80 -a -n "$p" ];
    then
        start_cleanup
    fi
    # If urbackup process not found then recover it
    start_recovery $p
}

# Complete maintenance
start_maintenance() {
    systemctl stop urbackupsrv.service
    cleanCache
    dnf --assumeyes check-update
    dnf --assumeyes upgrade-minimal
    urbackupsrv repair-database
    urbackupsrv cleanup-unknown
    urbackupsrv defrag-database
    init 6
}

# Update cache and install system utilities
get_utilities() {
    dnf --assumeyes update
    dnf --assumeyes install nano htop sqlite wget cronie git
    dnf --assumeyes install epel-release
    dnf --assumeyes install libguestfs libguestfs-tools
    dnf --assumeyes install hypervvssd hypervkvpd hyperv-tools hyperv-daemons
    systemctl start crond
    export EDITOR=/usr/bin/nano
}

# Install urBAckup Server
get_urbackup() {
    dnf config-manager --add-repo $1
    dnf update
    dnf --assumeyes install urbackup-server
    systemctl enable urbackup-server
    mkhomedir_helper urbackup
    ls /home/urbackup/ -aghl
}
# repo="https://download.opensuse.org/repositories/home:uroni/Fedora_35/home:uroni.repo"
# get_urbackup $repo

# Prepare and mount partition for backup storage
set_partition() {
    sgdisk -n 0:0:0 -t 0:8300 /dev/sdb
    sleep 10
    mkfs.ext4 -G 4096 /dev/sdb1
    sleep 10
    mkdir /mnt/sdb1
    partition=`lsblk -n --output UUID /dev/sdb1`
    options="rw,relatime,nobarrier,x-systemd.mount-timeout=600"
    echo "UUID=$partition /mnt/sdb1 ext4 $options 0 2" >> /etc/fstab
    mount -a
    sleep 10
    mkdir /mnt/sdb1/backups
    chown -R urbackup:urbackup /mnt/sdb1/backups    
}

# Configure urBackup Server
set_urbackup() {
    service="/usr/lib/systemd/system/urbackup-server.service"
    cat $service
    sed -i '/\[Service\]/a ExecStartPre=/bin/sleep 10' $service
    mkdir /etc/urbackup
    echo "/mnt/sdb1/backups" >> /etc/urbackup/backupfolder
    chown urbackup:urbackup /etc/urbackup/backupfolder
    systemctl daemon-reload
}

# Configure firewall for urBackup Server
set_firewall() {
    firewall-cmd --add-port=55415/tcp
    firewall-cmd --add-port=55414/tcp
    firewall-cmd --add-port=55413/tcp
    firewall-cmd --add-port=35623/udp
    firewall-cmd --runtime-to-permanent
    firewall-cmd --list-ports
}

get_status() {
    service urbackup-server status
    ls /mnt/sdb1/backups/urbackup_tmp_files/ -aghl
}

"$@"
