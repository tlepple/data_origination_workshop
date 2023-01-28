#!/bin/bash

##########################################################################################
#  install some OS utilities
#########################################################################################
sudo apt-get install wget curl apt-transport-https unzip -y
sudo apt-get update

##########################################################################################
#  download and install community edition of redpanda
##########################################################################################
## Run the setup script to download and install the repo
curl -1sLf 'https://dl.redpanda.com/nzc4ZYQK3WRGd9sy/redpanda/cfg/setup/bash.deb.sh' | sudo -E bash

sudo apt-get update
sudo apt install redpanda -y

##########################################################################################
#   download and install 'rpk' - cli tools for working with red panda
#########################################################################################
curl -LO https://github.com/redpanda-data/redpanda/releases/latest/download/rpk-linux-amd64.zip

##########################################################################################
#  create a few directories
##########################################################################################
mkdir -p ~/.local/bin
mkdir -p ~/datagen

#########################################################################################
# add items to path for future use
#########################################################################################
export PATH="~/.local/bin:$PATH"
export REDPANDA_HOME=~/.local/bin

##########################################################################################
# add to path perm  https://help.ubuntu.com/community/EnvironmentVariables
##########################################################################################
echo "" >> ~/.profile
echo "#  set path variables here:" >> ~/.profile
echo "export REDPANDA_HOME=~/.local/bin" >> ~/.profile
echo "PATH=$PATH:$REDPANDA_HOME" >> ~/.profile

##########################################################################################
#  unzip rpk to --> ~/.local/bin
##########################################################################################
unzip rpk-linux-amd64.zip -d ~/.local/bin/

##########################################################################################
#  Install the red panda console package
##########################################################################################
curl -1sLf \
  'https://dl.redpanda.com/nzc4ZYQK3WRGd9sy/redpanda/cfg/setup/bash.deb.sh' \
  | sudo -E bash

sudo apt-get install redpanda-console -y

##########################################################################################
#  install pip for python3
##########################################################################################
sudo apt install python3-pip -y

##########################################################################################
#  install jq
##########################################################################################
sudo apt install -y jq

##########################################################################################
#  create the redpanda conig.yaml
##########################################################################################
cat <<EOF > ~/redpanda-console-config.yaml
kafka:
  brokers: "localhost:9092"
  schemaRegistry:
    enabled: true
    urls: ["http://localhost:8081"]
connect:
  enabled: true
  clusters:
    - name: postgres-dbz-connector
      url: http://localhost:8083
EOF

##########################################################################################
#   move this file to proper directory
##########################################################################################
sudo mv ~/redpanda-console-config.yaml /etc/redpanda/redpanda-console-config.yaml
sudo chown redpanda:redpanda -R /etc/redpanda

##########################################################################################
#  start redpanda & the console:
##########################################################################################
sudo systemctl start redpanda
sudo systemctl start redpanda-console

##########################################################################################
#  install a specific version of postgresql (version 14)
##########################################################################################
apt policy postgresql

##########################################################################################
#  install the pgp key for this version of postgresql:
##########################################################################################
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg

sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

sudo apt update

sudo apt install postgresql-14 -y

sudo systemctl enable postgresql

##########################################################################################
#  backup the original postgresql conf file
##########################################################################################
sudo cp /etc/postgresql/14/main/postgresql.conf /etc/postgresql/14/main/postgresql.conf.orig

##########################################################################################
#  setup the database to allow listeners from any host
##########################################################################################
sudo sed -e 's,#listen_addresses = \x27localhost\x27,listen_addresses = \x27*\x27,g' -i /etc/postgresql/14/main/postgresql.conf

##########################################################################################
#  increase number of connections allowed in the database
##########################################################################################
sudo sed -e 's,max_connections = 100,max_connections = 300,g' -i /etc/postgresql/14/main/postgresql.conf

##########################################################################################
#  need to setup postgres WAL to allow debezium to read from the logs
##########################################################################################
sudo sed -e 's,#listen_addresses = 'localhost',listen_addresses = '*',g' -i /etc/postgresql/14/main/postgresql.conf
sudo sed -e 's,#wal_level = replica,wal_level = logical,g' -i /etc/postgresql/14/main/postgresql.conf
sudo sed -e 's,#max_wal_senders = 10,max_wal_senders = 4,g' -i /etc/postgresql/14/main/postgresql.conf
sudo sed -e 's,#max_replication_slots = 10,max_replication_slots = 4,g' -i /etc/postgresql/14/main/postgresql.conf

##########################################################################################
#  create a new 'pg_hba.conf' file
##########################################################################################
# backup the orig
sudo mv /etc/postgresql/14/main/pg_hba.conf /etc/postgresql/14/main/pg_hba.conf.orig

cat <<EOF > pg_hba.conf
  # TYPE  DATABASE        USER            ADDRESS                 METHOD
  local   all             all                                     peer
  host    datagen         datagen        0.0.0.0/0                md5
EOF

##########################################################################################
#   set owner and permissions of this conf file
##########################################################################################
sudo mv pg_hba.conf /etc/postgresql/14/main/pg_hba.conf
sudo chown postgres:postgres /etc/postgresql/14/main/pg_hba.conf
sudo chmod 600 /etc/postgresql/14/main/pg_hba.conf

##########################################################################################
#  restart postgresql
##########################################################################################
sudo systemctl restart postgresql

##########################################################################################
#  install Java 11
##########################################################################################
sudo apt install openjdk-11-jdk -y

##########################################################################################
#  create an osuser datagen
##########################################################################################
#sudo adduser --disabled-login datagen
sudo useradd -m -s /usr/bin/bash datagen

echo supersecret1 > passwd.txt
echo supersecret1 >> passwd.txt

sudo passwd datagen < passwd.txt

rm -f passwd.txt

##########################################################################################
## Run the sql file to create the schema for all DB’s
##########################################################################################
sudo -u postgres psql < ~/db_ddl/create_user_datagen.sql
sudo -u datagen psql < ~/db_ddl/create_ddl_datagen.sql
sudo -u postgres psql < ~/db_ddl/grants4dbz.sql

##########################################################################################
#  create a directory for data assets in our new 'datagen' user
##########################################################################################
sudo mkdir -p /home/datagen/datagen
sudo chown datagen:datagen -R /home/datagen

##########################################################################################
#   copy these files to the os user 'datagen' and set owner and permissions
##########################################################################################
sudo mv ~/data_origination_workshop/datagen/* /home/datagen/datagen/
sudo chown datagen:datagen -R /home/datagen/

##########################################################################################
#  pip install some items
##########################################################################################
sudo pip install kafka-python uuid simplejson faker psycopg2-binary

##########################################################################################
#  kafka connect downloads
##########################################################################################
#  create some directories
mkdir -p ~/kafka_connect/configuration
mkdir -p ~/kafka_connect/plugins

#  get the public key
sudo wget https://dlcdn.apache.org/kafka/KEYS

# get the file:
wget https://dlcdn.apache.org/kafka/3.3.2/kafka_2.13-3.3.2.tgz -P ~/kafka_connect

#untar the file:
tar -xzf ~/kafka_connect/kafka_2.13-3.3.2.tgz --directory ~/kafka_connect/

# remove the tar file:
rm ~/kafka_connect/kafka_2.13-3.3.2.tgz

# copy the properties files:
cp ~/data_origination_workshop/kafka_connect/*.properties ~/kafka_connect/configuration/

##########################################################################################
#  debezium download
##########################################################################################
wget https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/2.1.1.Final/debezium-connector-postgres-2.1.1.Final-plugin.tar.gz -P ~/kafka_connect

# untar this file:
tar -xzf ~/kafka_connect/debezium-connector-postgres-2.1.1.Final-plugin.tar.gz --directory ~/kafka_connect/plugins/

# remove tar file
rm ~/kafka_connect/debezium-connector-postgres-2.1.1.Final-plugin.tar.gz
##########################################################################################
#  postgresql jdbc download
##########################################################################################
wget https://jdbc.postgresql.org/download/postgresql-42.5.1.jar -P ~/kafka_connect/plugins/debezium-connector-postgres/

##########################################################################################
#  copy jars to the kafka libs folder
##########################################################################################
cp ~/kafka_connect/plugins/debezium-connector-postgres/*.jar ~/kafka_connect/kafka_2.13-3.3.2/libs/

##########################################################################################
#  move & set permissions
##########################################################################################
sudo mv ~/kafka_connect/ /home/datagen/
sudo chown datagen:datagen -R /home/datagen

##########################################################################################
# source this to set our new variables in current session
##########################################################################################
bash -l
