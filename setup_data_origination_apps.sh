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

###########################################################################################################
## Create a DDL file for all our Db’s
###########################################################################################################

cat <<EOF > ~/create_user_datagen.sql
CREATE ROLE datagen LOGIN PASSWORD 'supersecret1';
CREATE DATABASE datagen OWNER datagen ENCODING 'UTF-8';
ALTER ROLE "datagen" WITH LOGIN;
ALTER ROLE "datagen" WITH REPLICATION;
EOF

cat <<EOF > ~/create_ddl_datagen.sql
CREATE schema datagen;
CREATE TABLE datagen.customer
(
    first_name character varying(50) COLLATE pg_catalog."default",
    last_name character varying(50) COLLATE pg_catalog."default",
    street_address character varying(100) COLLATE pg_catalog."default",
    city character varying(50) COLLATE pg_catalog."default",
    state character varying(50) COLLATE pg_catalog."default",
    zip_code character varying(50) COLLATE pg_catalog."default",
    home_phone character varying(50) COLLATE pg_catalog."default",
    mobile character varying(50) COLLATE pg_catalog."default",
    email character varying(50) COLLATE pg_catalog."default",
    ssn character varying(25) COLLATE pg_catalog."default",
    job_title character varying(50) COLLATE pg_catalog."default",
    create_date character varying(50) COLLATE pg_catalog."default",
	cust_id integer NOT NULL,
    CONSTRAINT customer_pkey PRIMARY KEY (cust_id)
);
CREATE or REPLACE FUNCTION datagen.insert_from_json(json)
    RETURNS void
LANGUAGE 'plpgsql'
COST 100
VOLATILE
AS \$BODY\$

BEGIN
  INSERT INTO datagen.customer(first_name, last_name, street_address, city, state, zip_code, home_phone, mobile, email, ssn, job_title, create_date, cust_id)
   SELECT
    x.first_name
,x.last_name
,x.street_address
,x.city
,x.state
,x.zip_code
,x.home_phone
,x.mobile
,x.email
,x.ssn
,x.job_title
,x.create_date
,x.cust_id
FROM json_to_record($1) AS x
  (
    first_name text,
last_name text,
street_address text,
city text,
state text,
zip_code text,
home_phone text,
mobile text,
email text,
ssn text,
job_title text,
create_date text,
cust_id int
  )
ON CONFLICT (cust_id) DO UPDATE SET
    first_name = EXCLUDED.first_name
    ,last_name = EXCLUDED.last_name
    ,street_address = EXCLUDED.street_address
    ,city = EXCLUDED.city
    ,state = EXCLUDED.state
    ,zip_code = EXCLUDED.zip_code
    ,home_phone = EXCLUDED.home_phone
    ,mobile = EXCLUDED.mobile
    ,email = EXCLUDED.email
    ,ssn = EXCLUDED.ssn
    ,job_title = EXCLUDED.job_title
    ,create_date = EXCLUDED.create_date;


END;
\$BODY\$;

CREATE PUBLICATION dbz_publication FOR TABLE datagen.customer;
GRANT ALL ON ALL TABLES IN SCHEMA datagen TO datagen;
EOF

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
sudo -u postgres psql < ~/create_user_datagen.sql

sudo -u datagen psql < ~/create_ddl_datagen.sql

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
mkdir -p ~/kafka_connect/

#  get the public key
sudo wget https://dlcdn.apache.org/kafka/KEYS

# get the file:
wget https://dlcdn.apache.org/kafka/3.3.2/kafka_2.13-3.3.2.tgz -P ~/kafka_connect

#untar the file:
tar -xzf ~/kafka_connect/kafka_2.13-3.3.2.tgz --directory ~/kafka_connect/

##########################################################################################
# source this to set our new variables in current session
##########################################################################################
bash -l
