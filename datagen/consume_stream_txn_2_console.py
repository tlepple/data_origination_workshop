from pyspark.sql import SparkSession
from pyspark.sql.types import *
from pyspark.sql.functions import *
from pyspark.sql.functions import udf
from pyspark.streaming import StreamingContext
import json
import uuid

#######################################################################################
#  define schema for a DF with data json data from Kafka msgs
#######################################################################################
txn_schema = StructType() \
               .add("amount", DoubleType()) \
               .add("barcode", StringType()) \
               .add("category", StringType()) \
               .add("cust_id", StringType()) \
               .add("item_desc", StringType()) \
               .add("transact_id", StringType()) \
               .add("transaction_date", StringType())



spark = SparkSession \
    .builder \
    .appName("redpanda") \
    .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.3.1") \
    .config("groupId", "org.apache.spark") \
    .config("artifactId", "spark-sql-kafka-0-10_2.12") \
    .config("version", "3.3.1") \
    .config("spark.eventLog.enabled", "true") \
    .config("spark.eventLog.dir", "/opt/spark/spark-events") \
    .config("spark.history.fs.logDirectory", "/opt/spark/spark-events") \
    .config("spark.sql.streaming.forceDeleteTempCheckpointLocation", "true") \
    .config("spark.sql.adaptive", "true") \
    .getOrCreate()

#######################################################################################
# Create DataFrame representing the stream of msgs from kafka (unbounded table)
#######################################################################################

parsed  = spark \
  .readStream \
  .format("kafka") \
  .option("kafka.bootstrap.servers", "192.168.1.119:9092") \
  .option("subscribe", "dgTxn") \
  .option("startingOffsets", "earliest") \
  .option("kafka.session.timeout.ms", "10000") \
  .load() \
  .select( \
  from_json(col("value").cast("string"), txn_schema).alias("parsed_value"))

##########################################################################################
#  project the kafka 'value' column into a new data frame:
##########################################################################################

projected = parsed \
     .select("parsed_value.*")


##########################################################################################
#       write to console
##########################################################################################

query = projected \
    .writeStream.outputMode("append") \
    .format("console") \
    .trigger(processingTime='6 seconds') \
    .start() \
    .awaitTermination()
