# vbsvars

Virtual Backup Server setup, configuration, and maintenance scripts

## Download scripts

```bash
dnf update && dnf install git -y
cd /var && git clone https://github.com/BAEX-IT/vbsvars.git
chmod +x /var/vbsvars/vbsvars.sh
chmod +x /var/vbsvars/status.sh
crontab /var/vbsvars/tasks.txt
```

## Setup sequence

> Update after some tests on 03/06/2023

Step 1: Install dependencies
Step 2: Prepare backup storage
Step 3: Install urBackup Server
Step 4: Define systemd and firewall settings
Step 5: Confiure static IP and host name

```bash
cd /var/vbsvars/
./vbsvars.sh dependencies
./vbsvars.sh partition
./vbsvars.sh urbackup
./vbsvars.sh systemd
./vbsvars.sh firewall
./vbsvars.sh ip 192.168.1.2 24 192.168.1.1 vbs.domain.com
```

## Maintenance

Sync data to disk and drop cache in memory or recover if porcess failed.
```bash
./vbsvars.sh drop
./vbsvars.sh recover
```
