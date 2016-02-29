#!/bin/bash
umask 077

BACKUP_DAY="Tuesday"
DIR="tmp/db_backup home/isabel/global2/current/* home/isabel/global2/shared etc/apache2/sites-available etc/logrotate.conf etc/logrotate.d/ etc/awstats/ var/lib/awstats/ var/log/apache2/"
BACKUP_DIR=/mnt/backups
LOG=$BACKUP_DIR/backup.log
TODAY=$( date +%A )

DATEPREFIX=$( date +%y%m%d-%H%M )

#create backup of the database with mysqldump
cd /
mysqldump -u root -pisabel2005 --all-databases > /tmp/db_backup

# Write buffers to disk to avoid changed log errors
sync


function inc_backup()
{
    tar -g $BACKUP_DIR/backup.inc -zcf $BACKUP_DIR/backup-sir-inc-$DATEPREFIX.tar.gz $DIR 2> /dev/null 1>> $LOG
}

function full_backup ()
{
    tar -g $BACKUP_DIR/backup.inc -czf $BACKUP_DIR/backup-sir-full-$DATEPREFIX.tar.gz $DIR 2> /dev/null 1>> $LOG
}

function delete_daily_inc () { \rm -f $BACKUP_DIR/*inc* 1> /dev/null 2>&1 ; }

if [ "$TODAY" == "$BACKUP_DAY" ] ; then
    delete_daily_inc
    full_backup
else
   inc_backup
fi
