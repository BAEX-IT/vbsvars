#!/usr/bin/bash

func() {
    echo Hello!
}

# MAINTENANCE

dropcaches() {
    sync && echo 3 > /proc/sys/vm/drop_caches
    echo "Cache dropped." > vbsvars.log
}

recovery() {
    if [`pidof urbackupsrv` -z "$1"];
    then
        systemctl stop urbackupsrv.service
        dropcaches
        urbackupsrv repair-database
        urbackupsrv defrag-database
        urbackupsrv cleanup-unknown
        systemctl start urbackupsrv.service
    fi
}

setuputils() {
    dnf --assumeyes install epel-release
    dnf --assumeyes update
    dnf --assumeyes install nano htop sqlite wget cronie git
    dnf --assumeyes install libguestfs libguestfs-tools
    dnf --assumeyes install glibc-all-langpacks
    dnf --assumeyes install hypervvssd hypervkvpd hyperv-tools hyperv-daemons
    dnf --assumeyes install zram-generator
    systemctl start crond
}

makepartitions() {
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

setupurbackup() {
    repo="https://download.opensuse.org/repositories/home:uroni/Fedora_Rawhide/home:uroni.repo"
    dnf config-manager --add-repo $repo
    dnf update
    dnf --assumeyes install urbackup-server
    systemctl enable urbackup-server
    mkhomedir_helper urbackup
    ls /home/urbackup/ -aghl
}

configurbackup() {
    service="/usr/lib/systemd/system/urbackup-server.service"
    cat $service
    sed -i '/\[Service\]/a ExecStartPre=/bin/sleep 10' $service
    mkdir /etc/urbackup
    echo "/mnt/sdb1/backups" >> /etc/urbackup/backupfolder
    chown urbackup:urbackup /etc/urbackup/backupfolder
    systemctl daemon-reload
}

configfirewall() {
    firewall-cmd --add-port=55415/tcp
    firewall-cmd --add-port=55414/tcp
    firewall-cmd --add-port=55413/tcp
    firewall-cmd --add-port=35623/udp
    firewall-cmd --runtime-to-permanent
    firewall-cmd --list-ports
}

configsystemd() {
    vm_conf_file='/etc/sysctl.d/20-custom.conf'
    echo "# Custom settings for systemd
    vm.swappiness=10
    vm.vfs_cache_pressure=50
    vm.dirty_background_ratio=5
    vm.dirty_ratio=10
    vm.min_free_kbytes=262144
    " > $vm_conf_file
    sysctl --system
}

"$@"
