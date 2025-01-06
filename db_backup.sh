#!/bin/bash

date_ext=$(date '+%Y-%m-%d_%H-%M')
logfile="/backups/backup.log"
backup_retention="7" # Delete backups older than number of days

backup_root="/backups"

path_maria="mariadb"
user_maria="USER"
pass_maria="PASS"

path_influx="influxdb"
token_influx="xzMOjwRCkffyzg4  BLAH  c2_FMa1AKYAwuWbVXoV0vVQ=="



_initialize() {
        [ -d $backup_root ] || mkdir $backup_root
        [ -d $backup_root/$path_maria ] || mkdir $backup_root/$path_maria
        [ -d $backup_root/$path_influx ] || mkdir $backup_root/$path_influx
        [ -f $logfile ] || touch ${logfile}
}


_cleanup() {
    echo "${date_ext} Deleting old backups - mariadb"
    find ${backup_root}/${path_maria} -name "*.gz" -type f -mtime +${backup_retention} -delete
    echo "${date_ext} Deleting old backups - influxdb"
    find ${backup_root}/${path_influx} -type d -mtime +${backup_retention} -delete
    echo "${date_ext} Cleanup done."
}


_maria_backup() {
        echo "${date_ext} Starting MariaDB Backup."
        mariabackup --user=${user_maria} --password=${pass_maria} --backup --stream=xbstream | pigz -p 6 > "${backup_root}/${path_maria}/backup_${date_ext}.gz"
        echo "${date_ext} MariaDB Backup done."
}


_influx_backup() {
        echo "${date_ext} Starting influxDB Backup."
        influx backup "${backup_root}/${path_influx}/backup_${date_ext}" -t "${influxdb_token}"
        echo "${date_ext} MariaDB Backup done."
}



_finalize() {
    echo "${date_ext} Finished Backups."
        echo "#################################################################"
    exit 0
}


# Main
_initialize >> "${logfile}" 2>&1
_maria_backup >> "${logfile}" 2>&1
_influx_backup >> "${logfile}" 2>&1
_cleanup >> "${logfile}" 2>&1
_finalize >> "${logfile}" 2>&1




###############MARIADB

# https://backup.ninja/news/mariadb-backups-what-is-mariabackup

#Preparation Process
#When you create the backup of your database, it won’t be consistent as all the data files are copied at various times during the backup process. Therefore, you can’t directly restore your database. You have to prepare the data files to make it consistent.

#1
#$ mariabackup --prepare --target-dir=/tmp/mariadb/backup/
#Now we are ready to restore our database backup.

#Restoration Process
#To restore our database from a full backup, you can use either of --copy-back or --move-back options. The first one will retain the original files whereas the latter option will move the backup files to the data directory of your database. Before you run the following command, make sure that the MariaDB process is stopped and the data directory is empty.

#1
#$ mariabackup --copy-back --target-dir=/tmp/mariadb/backup/
#Once the data restore completes, the data directory and its files will be owned by the “backupuser” as we used that user in the backup process. You need to change it back to mysql user along with the group.

#1
#$ chown -R mysql:mysql /var/lib/mysql/
#Now, you can start the MariaDB server with the new data.

###############INFLUXDB

#https://docs.influxdata.com/influxdb/v2.6/reference/cli/influx/restore/

#The influx restore command restores backup data and metadata from an InfluxDB OSS backup directory.

#The restore process
#When restoring data from a backup file set, InfluxDB temporarily moves existing data and metadata while restore runs. After restore completes, the temporary data is deleted. If the restore process fails, InfluxDB preserves the data in the temporary location.

#For information about recovering from a failed restore process, see Restore data.

#Cannot restore to existing buckets
#The influx restore command cannot restore data to existing buckets. Use the --new-bucket flag to create a bucket with a new name and restore data into it. To restore data and retain bucket names, delete existing buckets and then begin the restore process.


#Restore backup data
###influx restore /path/to/backup/dir/
#Restore backup data for a specific bucket into a new bucket
###influx restore \
###  --bucket example-bucket \
###  --new-bucket new-example-bucket \
###  /path/to/backup/dir/
#Restore and replace all data
#influx restore --full restores all time series data and InfluxDB key-value data such as tokens, dashboards, users, etc.

###influx restore --full /path/to/backup/dir/
