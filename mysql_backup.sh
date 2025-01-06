#!/bin/bash
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
DEST="/backup/mysqlDump.sql"
MYSQLUSER="root"
MYSQLPASS="mypassword"
# no need to change anything below...
#####################################################
LOCKFILE=/tmp/myBkup.lock
if [ -f $LOCKFILE ]; then
echo "Lockfile $LOCKFILE exists, exiting!"
exit 1
fi
touch $LOCKFILE
echo "== MySQL Dump Starting $(date) =="
$MYSQLDUMP --single-transaction --user=${MYSQLUSER} --password="${MYSQLPASS}" -A > ${DEST}
echo "== MySQL Dump Ended $(date) =="
rm $LOCKFILE
