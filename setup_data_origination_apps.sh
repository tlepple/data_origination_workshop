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
#  start the red panda & the console:
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
sudo adduser --disabled-login datagen

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
#  Create the python faker data generator function
##########################################################################################
cat <<EOF > ~/datagen/datagenerator.py
import time
import collections
import datetime
from decimal import Decimal
from random import randrange, randint, sample
import sys
class DataGenerator():
	#  DataGenerator
	def __init__(self):
	    #  comments
	    self.z = 0
	def fake_person_generator(self, startkey, iterateval, f):
	    self.startkey = startkey
	    self.iterateval = iterateval
	    self.f = f
	    endkey = startkey + iterateval
	    for x in range(startkey, endkey):
	    	yield {'last_name': f.last_name(),
	    		'first_name': f.first_name(),
	    		'street_address': f.street_address(),
	    		'city': f.city(),
	    		'state': f.state_abbr(),
	    		'zip_code': f.postcode(),
	    		'email': f.email(),
	    		'home_phone': f.phone_number(),
	    		'mobile': f.phone_number(),
	    		'ssn': f.ssn(),
	    		'job_title': f.job(),
	    		'create_date': (f.date_time_between(start_date="-60d", end_date="-30d", tzinfo=None)).strftime('%Y-%m-%d %H:%M:%S'),
	    		'cust_id': x}
	def fake_txn_generator(self, txnsKey, txniKey, fake):
	    self.txnsKey = txnsKey
	    self.txniKey = txniKey
	    self.fake = fake

	    txnendKey = txnsKey + txniKey
	    for x in range(txnsKey, txnendKey):
	    	for i in range(1,randrange(1,7,1)):
	    		yield {'transact_id': fake.uuid4(),
	    			'category': fake.safe_color_name(),
	    			'barcode': fake.ean13(),
	    			'item_desc': fake.sentence(nb_words=5, variable_nb_words=True, ext_word_list=None),
	    			'amount': fake.pyfloat(left_digits=2, right_digits=2, positive=True),
	    			'transaction_date': (fake.date_time_between(start_date="-29d", end_date="now", tzinfo=None)).strftime('%Y-%m-%d %H:%M:%S'),
	    			'cust_id': x}
EOF




##########################################################################################
#  create python script to send data to redpanda script
##########################################################################################
cat <<EOF > ~/datagen/redpanda_dg.py
import time
from faker import Faker
from datagenerator import DataGenerator
import simplejson
import sys
from kafka import KafkaProducer

#########################################################################################
#       Define variables
#########################################################################################
dg = DataGenerator()
fake = Faker() # <--- Don't Forgot this
startKey = int(sys.argv[1])
iterateVal = int(sys.argv[2])
producer = KafkaProducer(bootstrap_servers="localhost:9092",value_serializer=lambda v: simplejson.dumps(v, default=myconverter).encode('utf-8'))

# functions to display errors
def myconverter(obj):
        if isinstance(obj, (datetime.datetime)):
                return obj.__str__()
#########################################################################################
#       Code execution below
#########################################################################################
# While loop
while(True):
        fpg = dg.fake_person_generator(startKey, iterateVal, fake)
        for person in fpg:
                print(simplejson.dumps(person, ensure_ascii=False, default = myconverter))
                producer.send('dgCustomer', person)
        producer.flush()
        print("Customer Done.")
        print('\n')
        txn = dg.fake_txn_generator(startKey, iterateVal, fake)
        for tranx in txn:
                print(tranx)
                producer.send('dgTxn', tranx)
        producer.flush()
        print("Transaction Done.")
        print('\n')
# increment and sleep
        startKey += iterateVal
        time.sleep(3)


EOF


##################################################################################
#  create python script to send data to postgres script
##################################################################################

cat <<EOF > ~/datagen/pg_upsert_dg.py
############################################
# file contents:
############################################
from __future__ import print_function
from faker import Faker
from datagenerator import DataGenerator
import simplejson
import sys
import psycopg2
#########################################################################################
#	Define variables
#########################################################################################
dg = DataGenerator()
fake = Faker() # <--- Don't Forgot this
startKey = int(sys.argv[1])
iterateVal = int(sys.argv[2])
# functions to display errors
def printf (format,*args):
	sys.stdout.write (format % args)
def printException (exception):
	error, = exception.args
	printf("Error code = %s\n",error.code);
	printf("Error message = %s\n",error.message);
def myconverter(obj):
	if isinstance(obj, (datetime.datetime)):
		return obj.__str__()
#########################################################################################
#	Code execution below
#########################################################################################
try:
    try:
        conn = psycopg2.connect(host="127.0.0.1",database="datagen", user="datagen", password="supersecret1")
        print("Connection Established")
    except psycopg2.Error as exception:
        printf ('Failed to connect to database')
        printException (exception)
        exit (1)
    cursor = conn.cursor()
    try:k
        fpg = dg.fake_person_generator(startKey, iterateVal, fake)
        for person in fpg:
#            print(simplejson.dumps(person, ensure_ascii=False, default = myconverter))
            json_out = simplejson.dumps(person, ensure_ascii=False, default = myconverter)
            print(json_out)
            insert_stmt = "SELECT datagen.insert_from_json('" + json_out +"');"
            cursor.execute(insert_stmt)
        print("Records inserted successfully")
    except psycopg2.Error as exception:
        printf ('Failed to insert\n')
        printException (exception)
        exit (1)
    finally:
        if(conn):
            conn.commit()
            cursor.close()
            conn.close()
            print("PostgreSQL connection is closed")
except (Exception, psycopg2.Error) as error:
    print("Something else went wrong...\n", error)
finally:
    print("script complete!")
EOF


##########################################################################################
#  create python script to verify data successfully wrote to database.
##########################################################################################

cat <<EOF > ~/datagen/testpg.py
import psycopg2

# Connect to your PostgreSQL database on a remote server
conn = psycopg2.connect(host="127.0.0.1", port="5432", dbname="datagen", user="datagen", password="supersecret1")

# Open a cursor to perform database operations
cur = conn.cursor()

# Execute a test query
cur.execute("SELECT * FROM customer")

# Retrieve query results
records = cur.fetchall()

# Finally, you may print the output to the console or use it anyway you like
print(records)
EOF

#########################################################################################
#   copy these files to the os user 'datagen' and set owner and permissions
##########################################################################################
sudo mv ~/datagen/* /home/datagen/datagen/
sudo chown datagen:datagen -R /home/datagen/

##########################################################################################
#  pip install some items
##########################################################################################
sudo pip install kafka-python uuid simplejson faker psycopg2-binary

#########################################################################################
# source this to set our new variables in current session
#########################################################################################
bash -l
