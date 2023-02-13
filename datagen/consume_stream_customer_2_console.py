from pyspark.sql import SparkSession
from pyspark.sql.types import *
from pyspark.sql.functions import *
from pyspark.sql.functions import udf
from pyspark.streaming import StreamingContext
#from pyspark.streaming.kafka import KafkaUtils
import json
import uuid


#######################################################################################
# define a uuid function for the kafka key
#######################################################################################
uuidUdf = udf(lambda : str(uuid.uuid4()),StringType())
nowUdf = udf(lambda : now(),TimestampType())

#######################################################################################
#  define schema for a DF with data json data from Kafka msgs
#######################################################################################
customer_schema = StructType() \
               .add("first_name", StringType()) \
               .add("last_name", StringType()) \
               .add("street_address", StringType()) \
               .add("city", StringType()) \
               .add("state", StringType()) \
               .add("zip_code", StringType()) \
               .add("home_phone", StringType()) \
               .add("mobile", StringType()) \
               .add("email", StringType()) \
               .add("ssn", StringType()) \
               .add("job_title", StringType()) \
               .add("create_date", StringType()) \
               .add("cust_id", IntegerType())


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
  .option("kafka.bootstrap.servers", "127.0.0.1:9092") \
  .option("subscribe", "dgCustomer") \
  .option("startingOffsets", "earliest") \
  .option("kafka.session.timeout.ms", "10000") \
  .load() \
  .select( \
  from_json(col("value").cast("string"), customer_schema).alias("parsed_value"))

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
