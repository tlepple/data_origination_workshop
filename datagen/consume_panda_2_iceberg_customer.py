from pyspark.sql import SparkSession
from pyspark.sql.types import *
from pyspark.sql.functions import *
from pyspark.sql.functions import udf
from pyspark.streaming import StreamingContext
#from pyspark.streaming.kafka import KafkaUtils
import json
import uuid


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
    .appName("cust_panda_2_ice") \
    .config("spark.jars.packages", "org.apache.iceberg:iceberg-spark-runtime-3.3_2.12:1.1.0,software.amazon.awssdk:bundle:2.19.19,software.amazon.awssdk:url-connection-client:2.19.19,org.apache.spark:spark-sql-kafka-0-10_2.12:3.3.1") \
    .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
    .config("spark.sql.catalog.icecatalog", "org.apache.iceberg.spark.SparkCatalog") \
    .config("spark.sql.catalog.icecatalog.catalog-impl", "org.apache.iceberg.jdbc.JdbcCatalog") \
    .config("spark.sql.catalog.icecatalog.uri", "jdbc:postgresql://127.0.0.1:5432/icecatalog") \
    .config("spark.sql.catalog.icecatalog.jdbc.user", "icecatalog") \
    .config("spark.sql.catalog.icecatalog.jdbc.password", "supersecret1") \
    .config("spark.sql.catalog.icecatalog.warehouse", "s3://iceberg-data") \
    .config("spark.sql.catalog.icecatalog.io-impl", "org.apache.iceberg.aws.s3.S3FileIO") \
    .config("spark.sql.catalog.icecatalog.s3.endpoint", "http://127.0.0.1:9000") \
    .config("spark.sql.catalog.sparkcatalog", "icecatalog") \
    .config("spark.eventLog.enabled", "true") \
    .config("spark.eventLog.dir", "/opt/spark/spark-events") \
    .config("spark.history.fs.logDirectory", "/opt/spark/spark-events") \
    .config("spark.sql.catalogImplementation", "in-memory") \
    .config("groupId", "org.apache.spark") \
    .config("artifactId", "spark-sql-kafka-0-10_2.12") \
    .config("version", "3.3.1") \
    .config("spark.sql.streaming.forceDeleteTempCheckpointLocation", "true") \
    .config("spark.sql.adaptive", "true") \
    .getOrCreate()

#######################################################################################
# Create DataFrame representing the stream of msgs from kafka (unbounded table)
#######################################################################################

parsed  = spark \
  .readStream \
  .format("kafka") \
  .option("kafka.bootstrap.servers", "<private_ip>:9092") \
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

query = projected.writeStream \
    .outputMode("append") \
    .format("iceberg") \
    .trigger(processingTime='30 seconds') \
    .option("path", "icecatalog.icecatalog.stream_customer") \
    .option("checkpointLocation", "/opt/spark/checkpoint") \
    .start() \
    .awaitTermination()

spark.stop()

#     .trigger(Trigger.ProcessingTime(60, TimeUnit.SECONDS)) \
