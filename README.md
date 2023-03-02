---
Title:  The Journey to Apache Iceberg with Red Panda & Debezium
Author:  Tim Lepple
Last Updated:  3.02.2023
Comments:  This repo will setup a data integration platform to evaluate some technology.
Tags:  Icegerg | Spark | Redpanda | PostgreSQL | Kafka Connect | Python | Debezium | Minio
---


---
---

---
---


# The Journey to Apache Iceberg with Red Panda & Debezium
---
---

## Objective:
The goal of this workshop was to evaluate [Red Panda](https://redpanda.com/) and Kafka Connect (with the Debezium CDC plugin). Set up a data generator that streams events directly into Red Panda and also into a traditional database platform and deliver it to an [Apache Iceberg](https://iceberg.apache.org/) data lake. 

I took the time to install these components manually on a traditional linux server and then wrote the setup script in this repo so others could try it out too. Please take the time to review that script [`setup_datagen.sh`](./setup_data_origination_apps.sh). Hopefully it becomes a reference for you one day if you use any of this technology.  

In this workshop, we will integrate this data platform and stream data from here into our Apache Iceberg data lake built in a previous workshop (all of those components will be installed here too). For step-by-step instruction on working with the Iceberg components, please check out my [Apache Iceberg Workshop](https://github.com/tlepple/iceberg-intro-workshop) for more details.  All of the tasks from that workshop can be run on this new server.

---
---

# Highlights:

---

The setup script will build and install our `Data Integration Platform` onto a single Linux instance.  It installs a data generating application, a local SQL database (PostgreSQL), a Red Panda instance, a stand-alone Kafka Connect instance, a Debezium plugin for Kafka Connect, a Debezium Server, Minio, Spark and Apache Iceberg.  In addition, it will configure them all to work together.   
 
---
---

###  Pre-Requisites:

---

 * I built this on a new install of Ubuntu Server
 * Version: 20.04.5 LTS 
 * Instance Specs: (min 4 core w/ 16 GB ram & 30 GB of disk) -- add more RAM if you have it to spare.
 * If you are going to test this in `AWS`, it ran smoothly for me using AMI: `ami-03a311cadf2d2a6f8` in region: `us-east-2` with a instance type of: `t3.xlarge`

---
### Create OS User `Datagen` 

*  This user account will be the owner of all the objects that get installed
*  Security is not in place for any of this workshop.

```
##########################################################################################
#  create an osuser datagen and add to sudo file
##########################################################################################
sudo useradd -m -s /usr/bin/bash datagen

echo supersecret1 > passwd.txt
echo supersecret1 >> passwd.txt

sudo passwd datagen < passwd.txt

rm -f passwd.txt
sudo usermod -aG sudo datagen
##########################################################################################
#  let's complete this install as this user:
##########################################################################################
# password: supersecret1
su - datagen 
```
---

###  Install Git tools and pull this repo.
*  ssh into your new Ubuntu 20.04 instance and run the below command:
 
---
```
sudo apt-get install git -y

cd ~
git clone https://github.com/tlepple/data_origination_workshop.git
```

---

### Start the build:

```
#  run it:
. ~/data_origination_workshop/setup_datagen.sh
```
  *  This should complete within 10 minutes.
---

---
###  Workshop One Refresher:

If you didn't complete my first workshop and need a primer on Iceberg, you can complete that work again in this platform by following this guide:  [Workshop 1 Exercises](./workshop1_revisit.md).   If you are already familiar with those items please proceed.   A later step has all of that workshop automated if you prefer.

---

###  What is Redpanda
  * Information in this section was gathered from their website.  You can find more detailed information about their platform here:  [Red Panda](https://redpanda.com/platform)
---

Redpanda is an event streaming platform: it provides the infrastructure for streaming real-time data.  It has been proven to be 10x faster and 6x lower in total costs. It is also JVM-free, ZooKeeper®-free, Jepsen-tested and source available.

Producers are client applications that send data to Redpanda in the form of events. Redpanda safely stores these events in sequence and organizes them into topics, which represent a replayable log of changes in the system.

Consumers are client applications that subscribe to Redpanda topics to asynchronously read events. Consumers can store, process, or react to the events.

Redpanda decouples producers from consumers to allow for asynchronous event processing, event tracking, event manipulation, and event archiving. Producers and consumers interact with Redpanda using the Apache Kafka® API.

| Event-driven architecture (Redpanda)     | Message-driven architecture |
| ----------- | ----------- |
| Producers send events to an event processing system (Redpanda) that acknowledges receipt of the write. This guarantees that the write is durable within the system and can be read by multiple consumers.     | Producers send messages directly to each consumer. The producer must wait for acknowledgement that the consumer received the message before it can continue with its processes.       |


Event streaming lets you extract value out of each event by analyzing, mining, or transforming it for insights. You can:

  *  Take one event and consume it in multiple ways.
  *  Replay events from the past and route them to new processes in your application.
  *  Run transformations on the data in real-time or historically.
  *  Integrate with other event processing systems that use the Kafka API.


####  Redpanda differentiators:
Redpanda is less complex and less costly than any other commerecial mission-critical event streaming platform. It's fast, it's easy, and it keeps your data safe.

  *  Redpanda is designed for maximum performance on any data streaming workload.

  *  It can scale up to use all available resources on a single machine and scale out to distribute performance across multiple nodes. Built on C++, Redpanda delivers greater throughput and up to 10x lower p99 latencies than other platforms. This enables previously-unimaginable use cases that require high throughput, low latency, and a minimal hardware footprint.

  *  Redpanda is packaged as a single binary: it doesn't rely on any external systems.

  *  It's compatible with the Kafka API, so it works with the full ecosystem of tools and integrations built on Kafka. Redpanda can be deployed on bare metal, containers, or virtual machines in a data center or in the cloud. Redpanda Console also makes it easy to set up, manage, and monitor your clusters. Additionally, Tiered Storage lets you offload log segments to cloud storage in near real time, providing infinite data retention and topic recovery.

  *  Redpanda uses the Raft consensus algorithm throughout the platform to coordinate writing data to log files and replicating that data across multiple servers.

  *  Raft facilitates communication between the nodes in a Redpanda cluster to make sure that they agree on changes and remain in sync, even if a minority of them are in a failure state. This allows Redpanda to tolerate partial environmental failures and deliver predictable performance, even at high loads.

  *  Redpanda provides data sovereignty.

---
---
###  Hands-On Workshop begins here:
---
---

####  Explore the Red Panda CLI tool `RPK`  
  *   Redpanda Keeper `rpk` is Redpanda's command line interface (CLI) utility.  Detailed documentation of the CLI can be explored further here: [Redpanda Keeper Commands](https://docs.redpanda.com/docs/reference/rpk/)

#####  Create our first Redpanda topic with the CLI:
*  run this from a terminal window:
```
#  Let's create a topic with RPK
rpk topic create movie_list
```
####  Start a Redpanda `Producer` using the `rpk` CLI to add messages:
  *  this will open a producer session and await your input until you close it with `<ctrl> + d`
```
rpk topic produce movie_list
```

####  Add some messages to the `movie_list` topic:
  *  The producer will appear to be hung in the terminal window.   It is really just waiting for you to type in a message and hit `<return>`.


######  Entry 1:
```
Top Gun Maverick
```
######  Entry 2:
```
Star Wars - Return of the Jedi
```
#### Expected Output:
```
Produced to partition 0 at offset 0 with timestamp 1675085635701.
Star Wars - Return of the Jedi
Produced to partition 0 at offset 1 with timestamp 1675085644895.
```

##### Exit the producer:  `<ctrl> + d`

####  View these messages from Redpanda `Consumer` using the `rpk` CLI:

```
rpk topic consume movie_list --num 2
```

---

####  Expected Output:

```
{
  "topic": "movie_list",
  "value": "Top Gun Maverick",
  "timestamp": 1675085635701,
  "partition": 0,
  "offset": 0
}
{
  "topic": "movie_list",
  "value": "Star Wars - Return of the Jedi",
  "timestamp": 1675085644895,
  "partition": 0,
  "offset": 1
}

```
---
---

##  Explore the Red Panda GUI:
  *  Open a browser and navigate to your host ip address:  `http:\\<your ip address>:8888`  This will open the Red Panda GUI.  
  *  This is not the standard port for the Redpanda Console.   It has been modified to avaoid confilcts with other tools used in this workshop

---
---
  
  ![](./images/panda_view_topics.png)
  
---

####  We can delete this topic from the `rpk` CLI:

```
rpk topic delete movie_list
```
---
---

### Data Generator:
---

I have written a data generator CLI application and included it in this workshop to simplify creating some realistic data for us to explore.  We will use this data generator application to stream some realistic data directly into some topics (and later into a database).  The data generator is written in python and uses the component [Faker](https://faker.readthedocs.io/en/master/).  I encourage you to look at the code here if you want to look deeper into it.  [Data Generator Items](./datagen)   

---

#####  Let's create some topics for our data generator using the CLI:
```
rpk topic create dgCustomer
rpk topic create dgTxn
```
---
##### Console view of our `Topics`:
  ![](./images/panda_view__dg_load_topics.png)

---
---

#####  Data Generator Notes:   
---

The data generator app in this section accepts 3 integer arguments:  
  *  An integer value for the `customer key`.
  *  An integer value for the `N` number of groups to produce in small batches.
  *  An integer value for `N` number of times to loop until it will exit the script.

---
#####  Call the `Data Generator` to stream some messages to our topics:
---

```
cd ~/datagen

#  start the script:
python3 redpanda_dg.py 10 3 2
```

##### Sample Output:

This will load sample JSON data into our two new topics and write out a copy of those records to your terminal that looks something like this:

---

```
{"last_name": "Mcmillan", "first_name": "Linda", "street_address": "7471 Charlotte Fall Suite 835", "city": "Lake Richardborough", "state": "OH", "zip_code": "25649", "email": "tim47@example.org", "home_phone": "001-133-135-5972", "mobile": "001-942-819-7717", "ssn": "321-16-7039", "job_title": "Tourism officer", "create_date": "2022-12-19 20:45:34", "cust_id": 10}
{"last_name": "Hatfield", "first_name": "Denise", "street_address": "5799 Solis Isle", "city": "Josephbury", "state": "LA", "zip_code": "61947", "email": "lhernandez@example.org", "home_phone": "(110)079-8975x48785", "mobile": "976.262.7268", "ssn": "185-93-0904", "job_title": "Engineer, chemical", "create_date": "2022-12-31 00:29:36", "cust_id": 11}
{"last_name": "Adams", "first_name": "Zachary", "street_address": "6065 Dawn Inlet Suite 631", "city": "East Vickiechester", "state": "MS", "zip_code": "52115", "email": "fgrimes@example.com", "home_phone": "001-445-395-1773x238", "mobile": "(071)282-1174", "ssn": "443-22-3631", "job_title": "Maintenance engineer", "create_date": "2022-12-07 20:40:25", "cust_id": 12}
Customer Done.


{"transact_id": "020d5f1c-741d-40b0-8b2a-88ff2cdc0d9a", "category": "teal", "barcode": "5178387219027", "item_desc": "Government training especially.", "amount": 85.19, "transaction_date": "2023-01-07 21:24:17", "cust_id": 10}
{"transact_id": "af9b7e7e-9068-4772-af7e-a8cb63bf555f", "category": "aqua", "barcode": "5092525324087", "item_desc": "Take study after catch.", "amount": 82.28, "transaction_date": "2023-01-18 01:13:13", "cust_id": 10}
{"transact_id": "b11ae666-b85c-4a86-9fbe-8f4fddd364df", "category": "purple", "barcode": "3527261055442", "item_desc": "Likely age store hold.", "amount": 11.8, "transaction_date": "2023-01-26 01:15:46", "cust_id": 10}
{"transact_id": "e968daad-6c14-475f-a183-1afec555dd5f", "category": "olive", "barcode": "7687223414666", "item_desc": "Performance call myself send.", "amount": 67.48, "transaction_date": "2023-01-25 01:51:05", "cust_id": 10}
{"transact_id": "d171c8d7-d099-4a41-bf23-d9534b711371", "category": "teal", "barcode": "9761406515291", "item_desc": "Charge no when.", "amount": 94.57, "transaction_date": "2023-01-05 12:09:58", "cust_id": 11}
{"transact_id": "2297de89-c731-42f1-97a6-98f6b50dd91a", "category": "lime", "barcode": "6484138725655", "item_desc": "Little unit total money raise.", "amount": 47.88, "transaction_date": "2023-01-13 08:16:24", "cust_id": 11}
{"transact_id": "d3e08d65-7806-4d03-a494-6ec844204f64", "category": "black", "barcode": "9827295498272", "item_desc": "Yeah claim city threat approach our.", "amount": 45.83, "transaction_date": "2023-01-07 20:29:59", "cust_id": 11}
{"transact_id": "97cf1092-6f03-400d-af31-d276eff05ecf", "category": "silver", "barcode": "2072026095184", "item_desc": "Heart table see share fish.", "amount": 95.67, "transaction_date": "2023-01-12 19:10:11", "cust_id": 11}
{"transact_id": "11da28af-e463-4f7c-baf2-fc0641004dec", "category": "blue", "barcode": "3056115432639", "item_desc": "Writer exactly single toward same.", "amount": 9.33, "transaction_date": "2023-01-29 02:49:30", "cust_id": 12}
{"transact_id": "c9ebc8a5-3d1a-446e-ac64-8bdd52a1ce36", "category": "fuchsia", "barcode": "6534191981175", "item_desc": "Morning who lay yeah travel use.", "amount": 73.2, "transaction_date": "2023-01-21 02:25:02", "cust_id": 12}
Transaction Done.

```
---

####  Explore messages in the Red Panda Console from a browser
  * `http:\\<your ip address>:8888`  Make sure to click the `Topics` tab in the left side of our Console Application:
---
##### Click on the topic `dgCustomer` from the list.

---

 ![](./images/topic_customer_view.png)
 
---

##### Click on the topic '+' icon under the `Value` column to see the record details of a message.

---

 ![](./images/detail_view_of_cust_msg.png)
 
---
---
## Explore Change Data Capture (CDC) via `Kafka Connect` and `Debezium`

---

##### Define Change Data Capture (CDC):

Change Data Capture (CDC) is a database technique used to track and record changes made to data in a database. The changes are captured as soon as they occur and stored in a separate log or table, allowing applications to access the most up-to-date information without having to perform a full database query. CDC is often used for real-time data integration and data replication, enabling organizations to maintain a consistent view of their data across multiple systems.

---

##### Define `Kafka Connect`:

Kafka Connect is a tool for scalable and reliable data import/export between Apache Kafka and other data systems. It allows you to integrate Kafka or Red Panda with sources such as databases, key-value stores, and file systems, as well as with sinks such as data warehouses and NoSQL databases. Kafka Connect provides pre-built connectors for popular data sources, and also supports custom connectors developed by users. It uses the publish-subscribe model of Kafka to ensure that data is transported between systems in a fault-tolerant and scalable manner.

---

##### Define `Debezium`:

Debezium is an open-source change data capture (CDC) platform that helps to stream changes from databases such as MySQL, PostgreSQL, and MongoDB into Red Panda and Apache Kafka, among other data sources and sinks. Debezium is designed to be used for real-time data streaming and change data capture for applications, data integration, and analytics.  This component is a must for getting at legacy data in an effecient manner.

---

##### Why use these tools together?

By combining CDC with Kafa Connect (and using the Debezium plugin) we easily roll out a new system that could eliminate expensive legacy solutions for extracting data from databases and replicating them to a modern `Data Lake`. This approach requires very little configuration and will have a minimal performance impact on your legacy databases.   It will also allow you harness data in your legacy applications and implement new real-time streaming applications to gather insights that were previously very difficult and expensive to get at.

---
---

#### Integrate PostgreSQL with Kafka Connect:

In these next few exercises we will load data into a sql database and configure Kafka Connect to extract the CDC records and stream them to a new topic in Red Panda.

---
---

#### Data Generator to load data into PostgreSQL:

There is a second data generator application and we will use it to stream JSON records and load them directly into a Postgresql database.

---
---

#####  Data Generator Notes for stream to PostgreSQL:   
---
This data generator application accepts 2 integer arguments:  
  *  An integer value for the starting `customer key`.
  *  An integer value for `N` number of records to produce and load to the database.

#####  Call the Data Generator:

```
cd ~/datagen

#  start the script:
python3 pg_upsert_dg.py 10 4

```

##### Sample Output:
---
```
Connection Established
{"last_name": "Carson", "first_name": "Aaron", "street_address": "124 Campbell Overpass", "city": "Cummingsburgh", "state": "MT", "zip_code": "76816", "email": "aaron08@example.net", "home_phone": "786-888-8409x21666", "mobile": "001-737-014-7684x1271", "ssn": "394-84-0730", "job_title": "Tourist information centre manager", "create_date": "2022-12-04 00:00:13", "cust_id": 10}
{"last_name": "Allen", "first_name": "Kristen", "street_address": "00782 Richard Freeway", "city": "East Josephfurt", "state": "NJ", "zip_code": "87309", "email": "xwyatt@example.com", "home_phone": "085-622-1720x88354", "mobile": "4849824808", "ssn": "130-35-4851", "job_title": "Psychologist, occupational", "create_date": "2022-12-23 14:33:56", "cust_id": 11}
{"last_name": "Knight", "first_name": "William", "street_address": "1959 Coleman Drives", "city": "Williamsville", "state": "OH", "zip_code": "31621", "email": "farrellchristopher@example.org", "home_phone": "(572)744-6444x306", "mobile": "+1-587-017-1677", "ssn": "797-80-6749", "job_title": "Visual merchandiser", "create_date": "2022-12-11 03:57:01", "cust_id": 12}
{"last_name": "Joyce", "first_name": "Susan", "street_address": "137 Butler Via Suite 789", "city": "West Linda", "state": "IN", "zip_code": "63240", "email": "jeffreyjohnson@example.org", "home_phone": "+1-422-918-6473x3418", "mobile": "483-124-5433x956", "ssn": "435-50-2408", "job_title": "Gaffer", "create_date": "2022-12-14 01:20:02", "cust_id": 13}
Records inserted successfully
PostgreSQL connection is closed
script complete!

```
---
---
### Configure Integration of `Redpanda` and `Kafka Connect`
---
---

####  Kafka Connect Setup:

In the setup script, we downloaded and installed all the components and needed jar files that Kafka Connect will use.  Please review that setup file again if you want a refresher.  The script also configured the settings for our integration of PostgreSQL with Red Panda.   Let's review the configuration files that make it all work.

---

#####  The  property file that will link Kafka Connect to Red Panda is located here:
  * make sure you are logged into the OS as user `datagen` with a password of `supersecret1`
  
```

cd ~/kafka_connect/configuration
cat connect.properties
```
---

##### Expected output:

```
#Kafka broker addresses
bootstrap.servers=localhost:9092

#Cluster level converters
#These applies when the connectors don't define any converter
key.converter=org.apache.kafka.connect.json.JsonConverter
value.converter=org.apache.kafka.connect.json.JsonConverter

#JSON schemas enabled to false in cluster level
key.converter.schemas.enable=true
value.converter.schemas.enable=true

#Where to keep the Connect topic offset configurations
offset.storage.file.filename=/tmp/connect.offsets
offset.flush.interval.ms=10000

#Plugin path to put the connector binaries
plugin.path=:~/kafka_connect/plugins/debezium-connector-postgres/

```


---

#####  The  property file that will link Kafka Connect to PostgreSQL is located here:
  
```
cd ~/kafka_connect/configuration
cat pg-source-connector.properties
```
---

##### Expected output:

```
connector.class=io.debezium.connector.postgresql.PostgresConnector
offset.storage=org.apache.kafka.connect.storage.FileOffsetBackingStore
offset.storage.file.filename=offset.dat
offset.flush.interval.ms=5000
name=postgres-dbz-connector
database.hostname=localhost
database.port=5432
database.user=datagen
database.password=supersecret1
database.dbname=datagen
schema.include.list=datagen
plugin.name=pgoutput
topic.prefix=pg_datagen2panda

```

---
---
###  Start the `Kafka Connect` processor:
  *  This will start our processor and pull all the CDC records out of the PostgreSQL database for our 'customer' table and ship them to a new Redpanda topic.  
  *  This process will run and pull the messages and then sleep until new messages get written to the originating database.   To exit out of the processor when it completes use the commands `<control> + c`.
---

##### Start Kafka Connect:
  * make sure you are logged into OS as user `datagen` with a password of `supersecret1`

```
cd ~/kafka_connect/configuration

export CLASSPATH=/home/datagen/kafka_connect/plugins/debezium-connector-postgres/*
../kafka_2.13-3.3.2/bin/connect-standalone.sh connect.properties pg-source-connector.properties
```
---

#####  Expected Output:

In this link you can see the expected sample output:  [`connect.output`](./sample_output/connect.output) 



---
##### Explore the `Connect` tab in the Redpanda console from a browser:
  *  This view is only available when `Connect` processes are running.
  ---
  ![](./images/console_view_run_connect.png)
---

#####  Exit out of Kafka Connect from the terminal with: `<control> + c`

---
---
#### Explore our new Redpanda topic `pg_datagen2panda.datagen.customer` in the console from a browser:

---
#####  Console View of topic:

  ![](./images/panda_topic_view_connect_topic.png)
  
---
---
##### Click on the topic `pg_datagen2panda.datagen.customer` from the list.

---

 ![](./images/connect_output_summary_msg.png)
 
---

##### Click on the topic '+' icon under the `Value` column to see the record details of a message.

---

 ![](./images/connect_ouput_detail_msg.png)
 
 #### Kafka Connect Observations:

---
---
As you can see, this message contains the values of the record `before` and `after` it was inserted into our PostgreSQL database. In this next section we explore loading all of the data currently in our redpanda topics and deliver it into our Iceberg data lake.

---
---
# Integration with our Apache Iceberg Data Lake Exercises
---
---

#### Load Data to Iceberg with Spark


---

In this shell script  [`stream_customer_ddl_script.sh`](./spark_items/stream_customer_ddl_script.sh) we will launch a `spark-sql` cli and run the DDL code [`stream_customer_ddl.sql`](./spark_items/stream_customer_ddl.sql) to create our `icecatalog.icecatalog.stream_customer` table in iceberg.

```
. /opt/spark/sql/stream_customer_ddl_script.sh
```
---

In this spark streaming job  [`consume_panda_2_iceberg_customer.py`](./datagen/consume_panda_2_iceberg_customer.py) we will consume our messages loaded into topic `dgCustomer` with our data generator and append them into our `icecatalog.icecatalog.stream_customer` table in iceberg.

```

spark-submit ~/datagen/consume_panda_2_iceberg_customer.py
```

---
####  Review tables in our Iceberg datalake 
```
cd /opt/spark/sql

. ice_spark-sql_i-cli.sh

#  query 
SHOW TABLES IN icecatalog.icecatalog;

# Query 2:
SELECT * FROM icecatalog.icecatalog.stream_customer;
```
---

In this shell script  [`stream_customer_event_history_ddl_script.sh`](./spark_items/stream_customer_event_history_ddl_script.sh) we will launch a `spark-sql` cli and run the this DDL code [`stream_customer_event_history_ddl.sql`](./spark_items/stream_customer_event_history_ddl.sql) to create our `icecatalog.icecatalog.stream_customer_event_history` table in iceberg.

```
. /opt/spark/sql/stream_customer_event_history_ddl_script.sh
```
---

In this spark streaming job  [`spark_from_dbz_customer_2_iceberg.py`](./datagen/spark_from_dbz_customer_2_iceberg.py) we will consume our messages loaded into topic `pg_datagen2panda.datagen.customer` from the `kafka_connect` processor and append them into the `icecatalog.icecatalog.stream_customer_event_history` table in iceberg.  Spark Streaming does not have the ability to merge this data directly into our iceberg table yet.  This feature should become available soon.   In the interim, we will have to create a seperate batch job to apply them.  In an upcoming section we will demonstrate a better solution that will merge this information and simplify the ammount of code needed to accomplish this task. This specific job will only append the activity to our table.

```
. spark-submit ~/datagen/spark_from_dbz_customer_2_iceberg.py
```
---

Let's explore our iceberg tables with the interactive `spark-sql` shell.

```
cd /opt/spark/sql

. ice_spark-sql_i-cli.sh
```

* to exit the shell type: `exit;` and hit `<return>`

---

Run the query to see some output:

```
SELECT * FROM icecatalog.icecatalog.stream_customer_event_history;
```

---

####  Here are some aditional exercises of Spark & Python that may be of interest:

[Additional Spark Exercises](./sample_spark_jobs.md)

---
---
###  Automation of Workshop 1 Exercises
---
---


*  Please skip these 2 commands if you completed them by hand in the earlier reference to Workshop 1.  They were included again to add additional data to our applications for use with the `Debezium Server` in the next section.

Let's load all the customer data from workshop 1 in one simple `spark-sql` shell command.  In this shell script  [`iceberg_workshop_sql_items.sh`](./spark_items/iceberg_workshop_sql_items.sh) we will launch a `spark-sql` cli and run the this DDL code [`all_workshop1_items.sql`](./spark_items/all_workshop1_items.sql) to load our `icecatalog.icecatalog.customer` table in iceberg.

```
. /opt/spark/sql/iceberg_workshop_sql_items.sh
```

---

In this spark job [`load_ice_transactions_pyspark.py`](./spark_items/load_ice_transactions_pyspark.py)  we will load all the transactions from workshop 1 as a pyspark batch job:

```
spark-submit /opt/spark/sql/load_ice_transactions_pyspark.py
```

---
---
---
---

#  What is Debezium Server?
---
Debezium Server is an open-source distributed platform for change data capture (CDC) that captures events from databases, message queues, and other systems in real-time and streams them to Kafka or other event streaming platforms. It is part of the Debezium project, which aims to simplify and automate the process of extracting change events from different sources and making them available to downstream applications.

The Debezium Server provides a number of benefits, including the ability to capture data changes in real-time, the ability to process events in a scalable and fault-tolerant manner, and the ability to integrate with various data storage and streaming technologies. It is built using Apache Kafka and leverages the Kafka Connect API for connecting to various data sources and targets.

Debezium Server supports a wide range of data sources, including popular databases like MySQL, PostgreSQL, Oracle, SQL Server, MongoDB, Cassandra, and others. It also supports message queues like Apache Kafka, Apache Pulsar, and RabbitMQ, as well as file-based sources like Apache Cassandra, Apache Hadoop HDFS and Apache Iceberg.

Debezium Server can be deployed on-premises or in the cloud, and it is available under the Apache 2.0 open-source license, which means that it is free to use, modify, and distribute.

You can find more information about Debezium Server here:  [Debezium Server Website](https://debezium.io/documentation/reference/stable/operations/debezium-server.html)

---

###  Debezium Server Observations:

The use of `Debezium Server` greatly simplifies the amount of code needed to capture information in upsteam systems and automatically delivers it downstream to a destination.  It requires only a few configuration files.
 
It is capturing every change to our Postresql database including:
  * inserts, updates, delete to tables
  * adding columns to existing tables
  * creation of new tables

If you recall, in an early exercise we ran some Spark code that grabbed these same change records pushed to a Redpanda topic from the Postgresql database (with Kafka Connect) but we had to write a significant amount of code for each table to achieve only half of the goal.  The Debezium Server is a much cleaner approach.   It is worth noting that signficant work is being developed by the open source community to bring this same functionality to `Kafka Connect`.  I expect to see lots of options soon.

---
---
##  Debezium Server Exercises:
---
---


#### Query the Iceberg catalog for list of current tables:

```
#  start the spark-sql cli in interactive mode:
cd /opt/spark/sql
. ice_spark-sql_i-cli.sh

# run query:
SHOW TABLES IN icecatalog.icecatalog;
```
---

#### Expected Sample Output:

```
namespace       tableName                           isTemporary
                customer
                stream_customer
                stream_customer_event_history
                transactions

```

---

#### Start the Debezium Server in a new terminal window:

```
cd ~/appdist/debezium-server-iceberg/

bash run.sh
```
*  This will run until terminated and pull in database changes to our Iceberg Data Lake:
*  To exit type `control` + `c`

---

#### Explore our Iceberg Catalog now (in the previous terminal window):

```
cd /opt/spark/sql
. ice_spark-sql_i-cli.sh

# query:
SHOW TABLES IN icecatalog.icecatalog;
```
---

#### Expected Sample Output:

```
namespace       tableName                           isTemporary
                cdc_localhost_datagen_customer
                customer
                stream_customer
                stream_customer_event_history
                transactions
```

---

#### Query our new CDC table `cdc_localhost_datagen_customer` in our Data Lake that was replicated by `Debezium Server`:

```
cd /opt/spark/sql
. ice_spark-sql_i-cli.sh

#  query:
SELECT
  cust_id,
  last_name,
  city,
  state,
  create_date,
  __op,
  __table,
  __source_ts_ms,
  __db,
  __deleted
FROM icecatalog.icecatalog.cdc_localhost_datagen_customer
ORDER by cust_id;
```
---
#### Expected Sample Output:

```
cust_id last_name       city            state   create_date             __op    __table         __source_ts_ms           __db       __deleted
10      Jackson         North Kimberly  MP      2023-01-20 22:47:05     r       customer        2023-02-22 16:04:34.193 datagen     false
11      Downs           Conwaychester   MD      2022-12-27 23:54:51     r       customer        2023-02-22 16:04:34.193 datagen     false
12      Webster         Phillipmouth    VI      2023-01-17 20:54:46     r       customer        2023-02-22 16:04:34.193 datagen     false
13      Miller          Jessicahaven    OH      2023-01-13 05:03:57     r       customer        2023-02-22 16:04:34.193 datagen     false
Time taken: 0.384 seconds, Fetched 4 row(s)

```
---

#### Add additional rows to our Postgresql table via `datagen`:

```
cd ~/datagen/
python3 pg_upsert_dg.py 12 5
```

---

#### Query our updated Data Lake table that was replicated from updates applied in Postgresql: 

```
cd /opt/spark/sql
. ice_spark-sql_i-cli.sh

#  query:
SELECT
  cust_id,
  last_name,
  city,
  state,
  create_date,
  __op,
  __table,
  __source_ts_ms,
  __db,
  __deleted
FROM icecatalog.icecatalog.cdc_localhost_datagen_customer
ORDER by cust_id;
```
---
#### Expected Sample Output:

```
cust_id last_name           city                  state   create_date             __op    __table         __source_ts_ms          __db    __deleted
10      Jackson             North Kimberly        MP      2023-01-20 22:47:05     r       customer        2023-02-22 16:06:19.9   datagen false
11      Downs               Conwaychester         MD      2022-12-27 23:54:51     r       customer        2023-02-22 16:06:19.9   datagen false
12      Cook                New Catherinemouth    NJ      2023-01-03 18:38:35     u       customer        2023-02-22 19:03:52.62  datagen false
13      Ramos               West Laurabury        NY      2023-01-04 04:48:18     u       customer        2023-02-22 19:03:52.62  datagen false
14      Scott               West Thomastown       AL      2022-12-29 07:21:28     c       customer        2023-02-22 19:03:52.62  datagen false
15      Holden              East Danieltown       MT      2023-01-15 17:17:54     c       customer        2023-02-22 19:03:52.62  datagen false
16      Carpenter           Lake Jamesberg        GU      2023-01-05 22:16:55     c       customer        2023-02-22 19:03:52.62  datagen false
Time taken: 0.318 seconds, Fetched 7 row(s)
```

---
---
---

###  Final Summary:

Integrating a database using Kafka Connect (via Debezium plugins) to stream data to a system like Red Panda and our Iceberg Data Lake can have several benefits:

  1.  **Real-time data streaming:** The integration provides a real-time stream of data from the SQL database to Red Panda and our Iceberg Data Lake, making it easier to analyze and process data in real-time.

  2.  **Scalability:** Kafka Connect or the Debezium Server can handle high volume and velocity of data, allowing for scalability as the data grows.

  3.  **Ease of Use:** Kafka Connect & Debezizum Server simplifies the process of integrating the SQL database and delivering it to other destinations, making it easier for developers to set up and maintain.  

  4.  **Improved data consistency:** The integration helps ensure data consistency by providing a single source of truth for data being streamed to Red Panda or any other downstream consumer like our Iceberg Data Lake.

However, the integration may also have challenges such as data compatibility, security, and performance. It is important to thoroughly assess the requirements and constraints before implementing the integration.

---

If you have made it this far, I want to thank you for spending your time reviewing the materials. Please give me a 'Star' at the top of this page if you found it useful.

---
---

####  Extra Credit

* Interest in exploring the underlying PostgreSQL Database:
[Explore Postgresql Database](./explore_postgresql.md)

---
---

  ![](./images/drunk-cheers.gif)

[Tim Lepple](www.linkedin.com/in/tim-lepple-9141452)

---
---

