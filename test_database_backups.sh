#!/bin/sh
#
# Test for restoring postgresql backup dump files we stored in diferent folders
# BY: RUBEN EDWIN HUALLA QUISPE
# SO: Centos 7
#
set -eo pipefail

recipient_email=rhualla@unsa.edu.pe
databases=("db1" "db2" "db3")
paths=("bck_db1" "bck_db2" "bck_db3")

GLOBALSDIR=/home/user/bck_postgres_globals
GLOBALSFILE=$(ls -t $GLOBALSDIR | head -n1)
BACKUPDIR=/home/user/bck_siscom
PGDATADIR=/var/lib/pgsql/12/data

SUDO=/usr/bin/sudo
PSQL=/usr/bin/psql
PGRESTORE=/usr/bin/pg_restore
CREATEDB=/usr/bin/createdb
DROPDB=/usr/bin/dropdb

# -- Start a fresh new postgresql cluster and remove the old one --
cd /tmp
${SUDO} systemctl stop postgresql-12
${SUDO} rm -rf ${PGDATADIR}
# Auth method should be md5 but it would be overwritten when globals.sql is imported. TODO
# for md5 should add 'password' for postgres user on .pgpass file
${SUDO} -u postgres /usr/pgsql-12/bin/initdb -D /var/lib/pgsql/12/data/ -U postgres --auth-host=trust --auth-local=trust --pwfile=/var/lib/pgsql/local_postgres_pwd.dat --encoding=UTF8 --locale=es_PE.utf8
${SUDO} systemctl start postgresql-12

# Loading globals.sql file from backup dir
echo looking for GLOBALS...
if [ -r "${GLOBALSDIR}" ]
then
	echo loading GLOBALS
	${PSQL} -U postgres -q postgres < $GLOBALSDIR/$GLOBALSFILE
fi

# Find the latest backup dump files on given folder path with matching pattern
newest_file_matching_pattern(){ 
    #find $1 -name "$2" -print0 | xargs -0 ls -1 -t | head -1  
    ls -t $1/$2 | head -n1
}

echo finding newest backups...
FILES=()
for p in "${paths[@]}"
do
	file=$(newest_file_matching_pattern /home/user/${p} "bk_*.dump")
	FILES+=($file)
done

INITFILE=/home/user/pg-database-init.sql
NOW=$(/bin/date +'%Y%m%d_%H%M%S')
do_test_database_backup(){
	echo creating database $1 for backup $2
	${CREATEDB} -U postgres $1
        psql -q -U postgres $1 < $INITFILE

	echo restoring database $1
        # Restore backup
        if ${PGRESTORE} -U postgres --schema=public --jobs=4 --no-comments -d $1 $2 2> /tmp/restoring_errors.log ; then
           echo "$1 was restored succesfully" >> /tmp/restore_backup_log_${NOW}.log
        else
           echo "pg_restore return non-zero code restoring $1" >> /tmp/restore_backup_log_${NOW}.log
           return
        fi

	# If backup was gzipped use this instead
	#/bin/gunzip < $2 | psql -q -U postgres -d $1
	# Perform a simple test on database
	echo "Testing query"
	psql -d $1 -o /dev/null -c "select * from users limit 1"
}

echo testing backups...
for (( i=0; i<${#databases[@]}; i++ ))
do
        do_test_database_backup ${databases[$i]} ${FILES[$i]} &
done

wait
echo "All backups tested ${NOW}" | /bin/mailx -s 'Weekly test was run' -c cc@gmail.com admin@gmail.com
