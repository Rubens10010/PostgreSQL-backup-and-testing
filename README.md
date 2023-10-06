# PostgreSQL-backup-and-testing

This is valid "only" for centos 7. Should be adapted...

# Prerequisites:
- PostgreSQL server installed
- Mailx installed
- .pgpass is configured correctly

# Basic PostgreSQL-12 Installation
sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum install -y postgresql12-server
check dns 8.8.8.8
sudo yum install -y postgresql12-contrib
sudo /usr/pgsql-12/bin/postgresql-12-setup initdb
sudo systemctl start postgresql-12

# Basic Mailx Installation
from: https://gist.github.com/ppdeassis/badd934991b7939f088274bfeebb613d
