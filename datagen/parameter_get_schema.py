import argparse
import sys
import json
import re
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

spark = SparkSession \
    .builder \
    .appName("pg_cust_from_connect_schema") \
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


##########################################################################################
#  Defines some variables
##########################################################################################
parser = argparse.ArgumentParser()

# define our required arguments to pass in:
parser.add_argument("--p_broker", help="Enter the ip address and port of kakfa broker", required=True, type=str)
parser.add_argument("--p_topic", help="Enter the topic name for needed schema", required=True, type=str)

# parse these args
args = parser.parse_args()


kafka_broker = str(args.p_broker)
kafka_topic = str(args.p_topic)

print(kafka_broker)
print(kafka_topic)
##########################################################################################
#  function to get the json value from a kafka topic
##########################################################################################
def read_kafka_topic(topic):

    df_json = (spark.read
               .format("kafka")
               .option("kafka.bootstrap.servers", kafka_broker)
               .option("subscribe", topic)
               .option("startingOffsets", "earliest")
               .option("endingOffsets", "latest")
               .option("failOnDataLoss", "false")
               .load()
               # filter out empty values
               .withColumn("value", expr("string(value)"))
               .filter(col("value").isNotNull())
               # get latest version of each record
               .select("key", expr("struct(offset, value) r"))
               .groupBy("key").agg(expr("max(r) r"))
               .select("r.value"))

    # decode the json values
    df_read = spark.read.json(
      df_json.rdd.map(lambda x: x.value), multiLine=True)

    # drop corrupt records
    if "_corrupt_record" in df_read.columns:
        df_read = (df_read
                   .filter(col("_corrupt_record").isNotNull())
                   .drop("_corrupt_record"))

    return df_read

##########################################################################################
#   function to cleanup schema for humans to read:
##########################################################################################

def prettify_spark_schema_json(json: str):

  import re, json

  parsed = json.loads(json_schema)
  raw = json.dumps(parsed, indent=1, sort_keys=False)

  str1 = raw

  # replace empty meta data
  str1 = re.sub('"metadata": {},\n +', '', str1)

  # replace enters between properties
  str1 = re.sub('",\n +"', '", "', str1)
  str1 = re.sub('e,\n +"', 'e, "', str1)

  # replace endings and beginnings of simple objects
  str1 = re.sub('"\n +},', '" },', str1)
  str1 = re.sub('{\n +"', '{ "', str1)

  # replace end of complex objects
  str1 = re.sub('"\n +}', '" }', str1)
  str1 = re.sub('e\n +}', 'e }', str1)

  # introduce the meta data on a different place
  str1 = re.sub('(, "type": "[^"]+")', '\\1, "metadata": {}', str1)
  str1 = re.sub('(, "type": {)', ', "metadata": {}\\1', str1)

  # make sure nested ending is not on a single line
  str1 = re.sub('}\n\s+},', '} },', str1)

  return str1

##########################################################################################
#  call the function to get the schema
##########################################################################################

df = read_kafka_topic(kafka_topic)
json_schema = df.schema.json()

##########################################################################################
#  read the JSON into a schema
##########################################################################################

obj = json.loads(json_schema)
topic_schema = StructType.fromJson(obj)

##########################################################################################
#  print raw schema suitable for performant code
##########################################################################################

print('\n')
print('------------------------------------------SparkStreaming  Schema------------------------------------------\n')
print(topic_schema)
print('\n')

##########################################################################################
#  make the schema readable and print to screen.
##########################################################################################

#pretty_json_schema = prettify_spark_schema_json(json_schema)

##########################################################################################
#  read the JSON into a schema
##########################################################################################

#prettyObj = json.loads(pretty_json_schema)
#pretty_topic_schema = StructType.fromJson(prettyObj)



#print('\n')
#print('------------------------------------------Pretty  Schema------------------------------------------\n')
#print(pretty_topic_schema)
#print('\n')

