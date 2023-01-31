---
Title:  Data Origination Workshop 
Author:  Tim Lepple
Last Updated:  1.30.2023
Comments:  This repo will evolve over time with new items.
Tags:  Red Panda | PostgreSQL | Kafka Connect | Python
---

# Data Origination Workshop (WIP)
---
---

## Objective:
  *  To evaluate Red Panda and Kafka Connect and setup a data origination system that streams events to this platform.  In an upcoming workshop we will integrate this data and stream to Apache Iceberg.   Check out my [Apache Iceberg Workshop](https://github.com/tlepple/iceberg-intro-workshop) for more details on that.

My goal in this workshop was to go a little deeper than your typical `How To` guide that uses docker to spin up an enviroment. It has been my experience that to truely understand how some technologies work you need to know how they are wired together. I took the time to install all the components manually and then I built the setup script in this repo so others could try it out too. Please take the time to review that script `setup_data_origination_apps.sh`. Hopefully it becomes a reference for you one day.

---
---

# Highlights:

---

The setup script will build and install our `Data Origination Platform` onto a single linux instances.  It installs a data generating application, a local SQL database (PostgreSQL), a Red Panda instance and a stand-alone Kafka Connect instance and configures them all to work together.   
 
---
---

###  Pre-Requisites:

---

 * I built this on a new install of Ubuntu Server
 * Version: 20.04.5 LTS 
 * Instance Specs: (min 4 core w/ 8 GB ram & 30 GB of disk) -- add more RAM if you have it to spare.

---
###  Install Git tools and pull this repo.
*  ssh into your new Ubuntu 20.04 instance and run the below command:

---

```
sudo apt-get install git-all -y

cd ~
git clone https://github.com/tlepple/data_origination_workshop.git
```

---

### Start the build:

---

```
#  run it:
chmod +x ~/data_origination_workshop/setup_data_origination_apps.sh
. ~/data_origination_workshop/setup_data_origination_apps.sh
```
---
---
###  What is Redpanda?
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
Redpanda is less complex and less costly than any other commericial mission-critical event streaming platform. It's fast, it's easy, and it keeps your data safe.

  *  Redpanda is designed for maximum performance on any data streaming workload.

  *  It can scale up to use all available resources on a single machine and scale out to distribute performance across multiple nodes. Built on C++, Redpanda delivers greater throughput and up to 10x lower p99 latencies than other platforms. This enables previously-unimaginable use cases that require high throughput, low latency, and a minimal hardware footprint.

  *  Redpanda is packaged as a single binary: it doesn't rely on any external systems.

  *  It's compatible with the Kafka API, so it works with the full ecosystem of tools and integrations built on Kafka. Redpanda can be deployed on bare metal, containers, or virtual machines in a data center or in the cloud. And Redpanda Console makes it easy to set up, manage, and monitor your clusters. Additionally, Tiered Storage lets you offload log segments to cloud storage in near real time, providing infinite data retention and topic recovery.

  *  Redpanda uses the Raft consensus algorithm throughout the platform to coordinate writing data to log files and replicating that data across multiple servers.

  *  Raft facilitates communication between the nodes in a Redpanda cluster to make sure that they agree on changes and remain in sync, even if a minority of them are in a failure state. This allows Redpanda to tolerate partial environmental failures and deliver predictable performance, even at high loads.

  *  Redpanda provides data sovereignty.

---
---
###  Hands On Workshop begins here:
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
####  Start a Redpanda `Producer` to add messages:
  *  this will open a producer session and await your input until you close it with `<ctrl> + d`
```
rpk topic produce movie_list
```

####  Add some messages to the `movie_list` topic:

```
#  Entry 1:
Top Gun Maverick

#  Entry 2:
Star Wars - Return of the Jedi
```

  *  exit producer:  `<ctrl> + d`



#### Output:
```
Produced to partition 0 at offset 0 with timestamp 1675085635701.
Star Wars - Return of the Jedi
Produced to partition 0 at offset 1 with timestamp 1675085644895.

```

####  View these messages from CLI with the `Consumer`:

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

####  Delete this topic from the CLI:

```
rpk topic delete movie_list
```

---
---

##  Explore the Red Panda GUI:
  *  Open a browswer and navigate to your host ip address:  `http:\\<your ip address>:8080`  This will open the Red Panda GUI

---
---
  
  ![](./images/panda_view_topics.png)
  
---

####  Stream some data to our topics:

---

We will switch to a different OS user `datagen` (password for user: `supersecret1` where some data generation tools were installed during setup.  From a terminal window run:

##### Command:
```
su - datagen
```
---

#####  Let's create some topics for our data generator using the CLI:

```
rpk topic create dgCustomer
rpk topic create dgTxn
```
---
##### Console view of our new `Topics`:
  ![](./images/panda_view__dg_load_topics.png)
---

---
---

### Data Generator:

I have written a data generator CLI application and included it in this workshop to simplify creating some realistic data for us to explore.  We will use this data generator application to stream some data directly to our 2 new topics.

---
---

#####  Data Generator Notes:   

The data generator is written in python and accepts 3 integer arguments:  
  *  An integer value for the `customer key`.
  *  An integer value for the N number of groups to produce in small batches.
  *  An integer value for N number of times to loop until it will exit the script.

#####  Call the Data Generator:

```
cd ~/datagen

#  start the script:
python3 redpanda_dg.py 10 3 2
```

##### Sample Output:

This will load sample json data into our two new topics and write out those records to your terminal that looks something like this:

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

####  Explore Data in the Red Panda Console from a browser
  * `http:\\<your ip address>:8080`  Make sure to click the `Topics` tab in the left side of our Console Application:
---
##### Click on the topic `dgCustomer` from the list.

---

 ![](./images/topic_customer_view.png)
 
---

##### Click on the topic '+' icon under the `Value` column to see the record details a message.

---

 ![](./images/detail_view_of_cust_msg.png)
 
---
---
## Explore Change Data Capture (CDC) via `Kafka Connect`

---

##### Define Change Data Capture (CDC):

Change Data Capture (CDC) is a database technique used to track and record changes made to data in a database. The changes are captured as soon as they occur and stored in a separate log or table, allowing applications to access the most up-to-date information without having to perform a full database query. CDC is often used for real-time data integration and data replication, enabling organizations to maintain a consistent view of their data across multiple systems.

---

##### Define `Kafka Connect`:

Kafka Connect is a tool for scalable and reliable data import/export between Apache Kafka and other data systems. It allows you to integrate Kafka or Red Panda with sources such as databases, key-value stores, and file systems, as well as with sinks such as data warehouses and NoSQL databases. Kafka Connect provides pre-built connectors for popular data sources, and also supports custom connectors developed by users. It uses the publish-subscribe model of Kafka to ensure that data is transported between systems in a fault-tolerant and scalable manner.

---

##### Why use these tools together?

By combining CDC with Kafa Connect we easily roll out a new system that could elimate expensive legacy solutions for extracting data from databases and replicating them to a modern `Data Lake`. For more information on that see my [Apache Iceberg Workshop](https://github.com/tlepple/iceberg-intro-workshop) where we explore one of these new data lakes.  This approach requires very little configuration and will have a minimal performance impact our your legacy databases.   It will also allow you harness data in your legacy applications and implement new real-time streaming applications to gather insights that were previously very difficult and expensive to get at.

---
---

#### Integrate PostgreSQL with Kafka Connect:

In these next few exercises we will load data into a sql database and configure Kafka Connect to extract the CDC records and stream them to a new topic in Red Panda.

---
---

#### Data Generator to load data into PostgreSQL:

There is a second data generator application that will stream json record and load them directly into a Postgresql database.

---
---

#####  Data Generator Notes:   

The data generator is written in python and accepts 2 integer arguments:  
  *  An integer value for the `customer key`.
  *  An integer value for N number of records to produce and load to the database.

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

####  Kafka Connect Setup:

In the setup scipt, we downloaded and installed all the components and needed jar files that Kafka Connect will use.  Please review that setup file again if you want a refresher.  The script also configured the settings for our integration of PostgreSQL with Red Panda.   Let's review the configuration files that make it all work.

---

#####  The  property file that will link Kafka Connect to Red Panda is located here:
  * make sure you are logged into OS as user `datagen` with a password of `supersecret1`
  
```
su - datagen

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
