#!/bin/bash

# Variables setup
HOST="status.domain.com"
PORT=7521
USER="user"
PASS="1234567890"
NODE=`hostname`
LOCAL_PATH="/tmp/clients_$NODE.csv"
SERVER_PATH="/home/foreachstatus/ftp/clients_$NODE.csv"
DB_PATH="/var/urbackup/backup_server.db"
FIELDS="lastseen,lastbackup,lastbackup_image,file_ok,image_ok,name"

# Retrieve status from urBackup server DB, .csv file will be overwriten
sqlite3 -header -csv $DB_PATH "select $FIELDS from clients" > $LOCAL_PATH

# Upload status file to ftp server
sshpass -p $PASS scp -o StrictHostKeychecking=no -P $PORT $LOCAL_PATH $USER@$HOST:${SERVER_PATH}
