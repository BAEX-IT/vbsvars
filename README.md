# vbsvars

Virtual Backup Server setup, configuration, and maintenance scripts

```bash
vbsvars.sh dropcaches
```

Sync dta to disk and drop cache in memory.

Update after some tests on 03/06/2023
```bash
# Step 1: Install prerequisites
sh vbsvars.sh dependencies
# Step 2: Prepare backup storage
sh vbsvars.sh partition
# Step 3: Install urBackup Server
sh vbsvars.sh urbackup
# Step 4: Define systemd and firewall settings
sh vbsvars.sh systemd
sh vbsvars.sh firewall
# Step 5: Confiure static IP
sh vbsvars.sh ip 192.168.1.2 24 192.168.1.1
```