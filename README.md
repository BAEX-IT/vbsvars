# vbsvars

Virtual Backup Server setup, configuration, and maintenance scripts

## Download scripts

```bash
git clone https://github.com/artyomtsybulkin/vbsvars.git /var
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
sh vbsvars.sh dependencies
sh vbsvars.sh partition
sh vbsvars.sh urbackup
sh vbsvars.sh systemd
sh vbsvars.sh firewall
sh vbsvars.sh ip 192.168.1.2 24 192.168.1.1 vbs.domain.com
```

## Maintenance

Sync data to disk and drop cache in memory or recover if porcess failed.
```bash
vbsvars.sh drop
vbsvars.sh recover
```
