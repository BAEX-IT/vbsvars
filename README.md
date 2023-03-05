# vbsvars

Virtual Backup Server setup, configuration, and maintenance scripts

```bash
vbsvars.sh dropcaches
```

Sync dta to disk and drop cache in memory.

Update after some tests on 03/06/2023
```bash
# Step 1: Install prerequisites
sh vbsvars.sh setuputils
# Step 2: Prepare backup storage
sh vbsvars.sh makepartitions
# Step 3: Install urBackup Server
sh vbsvars.sh setupurbackup
```