#!/bin/bash

recipient_email=recipient@unsa.edu.pe
databases=("db1" "db2" "db3")
paths=("bck_db1" "bck_db2" "bck_db3")

if [ ${#databases[@]} -ne ${#paths[@]} ]
then
        echo "# of databases and paths is different!"
	exit 1
fi

do_backup_database(){
	DB_NAME=$1
	PATH=$2
	NOW=$(/bin/date +'%Y%m%d_%H%M%S')
	FILENAME="bk_${DB_NAME}_${NOW}"
	BACKUP_SQL_FILE="/home/desarrollo/${PATH}/${FILENAME}.dump"
	BACKUP_GZIP_FILE="/home/desarrollo/${PATH}/${FILENAME}.gz"

	# create backup
	if /usr/bin/pg_dump -U postgres --host=10.100.100.207 -Fc ${DB_NAME} > ${BACKUP_SQL_FILE} ; then
	   echo "Sql dump was created for ${DB_NAME}"
	else
	   echo "pg_dump return non-zero code backing ${DB_NAME}" | /bin/mailx -s 'No backup was created!' $recipient_email
	   return
	fi

	# Compress backup, use when not using -Fc
	#if /bin/gzip -c $BACKUP_SQL_FILE > $BACKUP_GZIP_FILE ; then
	#   echo "Database ${DB_NAME} has been backed up on ${BACKUP_GZIP_FILE}" >> /tmp/backup_log_${NOW}.log
	#else
	#   echo "Error compressing backup on db ${DB_NAME}" | /bin/mailx -s 'Backup was not created!' $recipient_email
	#   return
	#fi

	#/bin/rm $BACKUP_SQL_FILE
}


# Do all backups on background and wait
for (( i=0; i<${#databases[@]}; i++ ))
do
	do_backup_database ${databases[$i]} ${paths[$i]} &
done
 
wait 
NOW=$(/bin/date +'%Y%m%d_%H%M%S')
echo "All backups done ${NOW}" | /bin/mailx -s 'Daily Backup was run' $recipient

# Delete old backups | TODO
#keep_day=30
#find $backupfolders -mtime +$keep_day -delete
