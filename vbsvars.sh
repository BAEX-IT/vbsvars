#!/usr/bin/bash

drop() {
    sync && echo 3 > /proc/sys/vm/drop_caches
    date +%s > /var/log/vbsvars-drop.log
}

recover() {
    if [`pidof urbackupsrv` -z "$1"];
    then
        systemctl stop urbackupsrv.service
        drop
        urbackupsrv repair-database
        urbackupsrv defrag-database
        urbackupsrv cleanup-unknown
        date +%s > /var/log/vbsvars-recover.log
        init 6
    fi
}

# Tested on 03/06/2023
dependencies() {
    dnf --assumeyes install epel-release
    dnf --assumeyes update
    dnf --assumeyes install nano htop sqlite wget cronie git mc
    # Test: libguestfs virt-win-reg - installed, very starnge dependencies
    dnf --assumeyes install libguestfs libguestfs-tools
    # Set locale to en_US.UTF-8 instead of C.UTF-8
    dnf --assumeyes install glibc-all-langpacks
    localectl set-locale LANG=en_US.UTF-8
    dnf --assumeyes install hypervvssd hypervkvpd hyperv-tools hyperv-daemons
    dnf --assumeyes install zram-generator
    systemctl start crond
    # Reboot required
}

# Tested on 03/06/2023
partition() {
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
}

# Tested on 03/06/2023
urbackup() {
    # Server installation
    repo="https://download.opensuse.org/repositories/home:uroni/Fedora_Rawhide/home:uroni.repo"
    dnf config-manager --add-repo $repo
    dnf update
    # Test: libstdc++.so.6(GLIBCXX_3.4.30)(64bit) needed by urbackup-server-2.5.30.0-1.1.x86_64
    dnf --assumeyes --nobest install urbackup-server
    chown -R urbackup:urbackup /mnt/sdb1/backups
    systemctl enable urbackup-server
    mkhomedir_helper urbackup
    ls /home/urbackup/ -aghl
    # Server post-installation configuration
    service="/usr/lib/systemd/system/urbackup-server.service"
    cat $service
    sed -i '/\[Service\]/a ExecStartPre=/bin/sleep 60' $service
    mkdir /etc/urbackup
    echo "/mnt/sdb1/backups" >> /etc/urbackup/backupfolder
    chown urbackup:urbackup /etc/urbackup/backupfolder
    systemctl daemon-reload
}

firewall() {
    firewall-cmd --add-port=55415/tcp
    firewall-cmd --add-port=55414/tcp
    firewall-cmd --add-port=55413/tcp
    firewall-cmd --add-port=35623/udp
    firewall-cmd --runtime-to-permanent
    firewall-cmd --list-ports
}

systemd() {
    vm='/etc/sysctl.d/20-custom.conf'
    echo "# Custom settings for systemd" > $vm
    echo "vm.swappiness=10" >> $vm
    echo "vm.vfs_cache_pressure=50" >> $vm
    echo "vm.dirty_background_ratio=5" >> $vm
    echo "vm.dirty_ratio=10" >> $vm
    echo "vm.min_free_kbytes=262144" >> $vm
    sysctl --system
}

# Tested on 03/06/2023
ip() {
    # Usage: ip ipaddress subnet gateway
    # Example: ip 192.168.1.2 24 192.168.1.1 
    nmcli connection modify eth0 IPv4.address $1/$2
    nmcli connection modify eth0 IPv4.gateway $3
    nmcli connection modify eth0 IPv4.dns 8.8.8.8,8.8.4.4
    nmcli connection modify eth0 IPv4.method manual
    # Offloading disable below
    nmcli connection modify eth0 ethtool.feature-gro off
    nmcli connection modify eth0 ethtool.feature-lro off
    nmcli connection modify eth0 ethtool.feature-gso off
    nmcli connection modify eth0 ethtool.feature-tso off
    # Reload connection
    nmcli connection down eth0 && nmcli connection up eth0
}

"$@"
