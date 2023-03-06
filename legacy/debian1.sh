#!/bin/bash

# Benchmark ===========================================================================
s=`awk '{print $1}' /proc/uptime | cut -d "." -f 1`
du /mnt/sdb1/ 2>/dev/null | wc -l >/dev/null
f=`awk '{print $1}' /proc/uptime | cut -d "." -f 1`
echo "$f - $s" | bc

# Cleanup ===========================================================================
# Cron task example:
# */20 * * * * /usr/bin/flock -n /tmp/do_cleanup.lock /autolinux/scripts/do_cleanup.sh
# urBackup process uptime in seconds:
# ps -p `pidof urbackupsrv` -o etimes --no-headers | awk '{print $1}'
p=`pidof urbackupsrv`
t=`cat /proc/meminfo | grep MemTotal: | awk '{print $2}'`
f=`cat /proc/meminfo | grep MemFree: | awk '{print $2}'`
cleanup () {
    sync && echo 3 > /proc/sys/vm/drop_caches
}
if [ `expr 100 \* $f / $t` -lt 80 ];
then
cleanup
fi

# Ethernet ===========================================================================
echo "Ethernet advanced features modify."
read -p "Continue (y/n): " action
if [ "$action" = "y" ];
then
if_name=`cat /proc/net/route | awk '{if($3!=00000000)print($1)}' | tail -n 1`
if_conf_file="/etc/network/interfaces.d/$if_name"
read -p "Address (x.x.x.x): " ipaddress
read -p "Mask (x.x.x.x): " ipmask
read -p "Gateway (x.x.x.x): " ipgate
read -p "Domain (domain.local): " ipdomain
read -p "DNS (single x.x.x.x): " ipdns
rm $if_conf_file
echo "
# Enable static IPv4 for $if_name
auto eth0
iface eth0 inet static
address $ipaddress
netmask $ipmask
gateway $ipgate
dns-domain $ipdomain
dns-nameservers $ipdns 8.8.8.8

# Disable offloading for $if_name
post-up ethtool --offload $if_name rx off tx off
post-up ethtool --features $if_name tso off
post-up ethtool --features $if_name sg off
post-up ethtool --features $if_name gso off
post-up ethtool --features $if_name gro off
post-up ethtool --features $if_name lro off
" >> $if_conf_file
systemctl restart networking.service
ifup $if_name
echo "Use (or via editor): sed "/$if_name/d" -i /etc/network/interfaces"
else
echo "Stage skipped."
fi

# fstab ===========================================================================
# ext4_hdd: rw, relatime, nobarrier, journal_checksum, journal_async_commit, data=ordered
# est4 ssd: rw, relatime, nobarrier, discard
echo "Modify fstab."
read -p "Continue (y/n): " action
if [ "$action" = "y" ];
then
echo "Modifying fstab"
# use for sda: rw, relatime, nobarrier, discard
# use for sdb: rw, relatime, nobarrier
# use for sdc: rw, noatime, nobarrier, discard
else
echo "Stage skipped."
fi

# grub ===========================================================================
echo "Grub bootloader configure."
read -p "Continue (y/n): " action

if [ "$action" = "y" ];
then
grub_conf='/etc/default/grub'
grub_t="GRUB_TIMEOUT"
grub_ts="GRUB_TIMEOUT_STYLE"
grub_cmd_def="GRUB_CMDLINE_LINUX_DEFAULT"
grub_cmd="GRUB_CMDLINE_LINUX"
sed -i "s/$grub_t=.*/$grub_t=30/g" $grub_conf
sed -i "s/$grub_ts=.*/$grub_ts=menu/g" $grub_conf
sed -i "s/$grub_cmd_def=.*/$grub_cmd_def=\"scsi_mod.use_blk_mq=0 elevator=noop\"/g" $grub_conf
sed -i "s/$grub_cmd=.*/$grub_cmd=\"ipv6.disable=1\"/g" $grub_conf
update-grub
else
echo "Skipped."
fi

# hostname ===========================================================================
read -p "Hostname: " hostfqdn
hostnamectl set-hostname $hostfqdn
dpkg-reconfigure tzdata

# swap ===========================================================================
#!/bin/bash

fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
swapon
swapon --show


# systemd ===========================================================================
echo "Linux Systemd VM settings tuning."
read -p "Continue (y/n): " action

if [ "$action" = "y" ];
then
vm_conf_file='/etc/sysctl.d/20-custom.conf'
echo "# Custom settings for VM
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_background_ratio=5
vm.dirty_ratio=10
vm.min_free_kbytes=262144
" > $vm_conf_file
sysctl --system
else
echo "Skipped."
fi

# urbackup cleanup ===========================================================================
#!/bin/bash

# Cron task example:
# */20 * * * * /usr/bin/flock -n /tmp/do_cleanup.lock /autolinux/scripts/do_cleanup.sh
# urBackup process uptime in seconds:
# ps -p `pidof urbackupsrv` -o etimes --no-headers | awk '{print $1}'

p=`pidof urbackupsrv`
mem_total=`cat /proc/meminfo | grep MemTotal: | awk '{print $2}'`
mem_free=`cat /proc/meminfo | grep MemFree: | awk '{print $2}'`

cleanup () {
    sync && echo 3 > /proc/sys/vm/drop_caches
}

if [ `expr 100 \* $mem_free / $mem_total` -lt 80 ];
then
cleanup
fi

if [ -z "$p" ];
then
systemctl stop urbackupsrv.service
cleanup
urbackupsrv repair-database
urbackupsrv remove-unknown
urbackupsrv defrag-database
cleanup
systemctl start urbackupsrv.service
fi

# software ===========================================================================

#!/bin/bash

apt -y install python3-pip
sudo -H pip3 install --upgrade pip

apt -y install htop sdparm sysstat curl wget git mc
apt -y install net-tools ethtool parted bash-completion
apt -y install debian-keyring software-properties-common

# urbackup ===========================================================================

#!/bin/bash

wget https://hndl.urbackup.org/Server/2.4.13/urbackup-server_2.4.13_amd64.deb
dpkg -i urbackup-server_2.4.13_amd64.deb
apt install -f
rm urbackup-server_2.4.13_amd64.deb

# ethernet ===========================================================================
#!/bin/bash

echo "Ethernet advanced features modify."
read -p "Continue (y/n): " action

if [ "$action" = "y" ];
then
if_name=`cat /proc/net/route | awk '{if($3!=00000000)print($1)}' | tail -n 1`
if_conf_file="/etc/network/interfaces.d/$if_name"
read -p "Address (x.x.x.x): " ipaddress
read -p "Mask (x.x.x.x): " ipmask
read -p "Gateway (x.x.x.x): " ipgate
read -p "Domain (domain.local): " ipdomain
read -p "DNS (single x.x.x.x): " ipdns
rm $if_conf_file
echo "
# Enable static IPv4 for $if_name
auto eth0
iface eth0 inet static
address $ipaddress
netmask $ipmask
gateway $ipgate
dns-domain $ipdomain
dns-nameservers $ipdns 8.8.8.8

# Disable offloading for $if_name
post-up ethtool --offload $if_name rx off tx off
post-up ethtool --features $if_name tso off
post-up ethtool --features $if_name sg off
post-up ethtool --features $if_name gso off
post-up ethtool --features $if_name gro off
post-up ethtool --features $if_name lro off
" >> $if_conf_file
systemctl restart networking.service
ifup $if_name
echo "Use (or via editor): sed "/$if_name/d" -i /etc/network/interfaces"
else
echo "Stage skipped."
fi

# 