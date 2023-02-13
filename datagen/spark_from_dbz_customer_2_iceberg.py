from pyspark.sql import SparkSession
from pyspark.sql.types import *
from pyspark.sql.functions import col, udf
from pyspark.sql.functions import *
from pyspark.sql import *
from pyspark.streaming import StreamingContext
import json
import uuid
import re


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
    .config("spark.sql.adaptive.enabled", "true") \
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


##########################################################################################
#  debezium schema
##########################################################################################
dbz_schema_value = StructType([StructField('payload', StructType([StructField('after', StructType([StructField('city', StringType(), True), StructField('create_date', StringType(), True), StructField('cust_id', LongType(), True), StructField('email', StringType(), True), StructField('first_name', StringType(), True), StructField('home_phone', StringType(), True), StructField('job_title', StringType(), True), StructField('last_name', StringType(), True), StructField('mobile', StringType(), True), StructField('ssn', StringType(), True), StructField('state', StringType(), True), StructField('street_address', StringType(), True), StructField('zip_code', StringType(), True)]), True), StructField('before', StructType([StructField('city', StringType(), True), StructField('create_date', StringType(), True), StructField('cust_id', LongType(), True), StructField('email', StringType(), True), StructField('first_name', StringType(), True), StructField('home_phone', StringType(), True), StructField('job_title', StringType(), True), StructField('last_name', StringType(), True), StructField('mobile', StringType(), True), StructField('ssn', StringType(), True), StructField('state', StringType(), True), StructField('street_address', StringType(), True), StructField('zip_code', StringType(), True)]), True), StructField('op', StringType(), True), StructField('source', StructType([StructField('connector', StringType(), True), StructField('db', StringType(), True), StructField('lsn', LongType(), True), StructField('name', StringType(), True), StructField('schema', StringType(), True), StructField('sequence', StringType(), True), StructField('snapshot', StringType(), True), StructField('table', StringType(), True), StructField('ts_ms', LongType(), True), StructField('txId', LongType(), True), StructField('version', StringType(), True), StructField('xmin', StringType(), True)]), True), StructField('transaction', StringType(), True), StructField('ts_ms', LongType(), True)]), True), StructField('schema', StructType([StructField('fields', ArrayType(StructType([StructField('field', StringType(), True), StructField('fields', ArrayType(StructType([StructField('default', StringType(), True), StructField('field', StringType(), True), StructField('name', StringType(), True), StructField('optional', BooleanType(), True), StructField('parameters', StructType([StructField('allowed', StringType(), True)]), True), StructField('type', StringType(), True), StructField('version', LongType(), True)]), True), True), StructField('name', StringType(), True), StructField('optional', BooleanType(), True), StructField('type', StringType(), True), StructField('version', LongType(), True)]), True), True), StructField('name', StringType(), True), StructField('optional', BooleanType(), True), StructField('type', StringType(), True), StructField('version', LongType(), True)]), True)])





##########################################################################################
#  read from topic
##########################################################################################
connectCustTopicDF = spark \
    .readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "127.0.0.1:9092") \
    .option("subscribe", "pg_datagen2panda.datagen.customer") \
    .option("startingOffsets", "earliest") \
    .option("kafka.session.timeout.ms", "10000") \
    .load() \
    .select( \
        from_json(col("value").cast("string"), dbz_schema_value).alias("parsed_value"))


##########################################################################################
#  get just the payload from 'connectCustTopicDF'
##########################################################################################

payloadDF = connectCustTopicDF \
     .select("parsed_value.payload.*")

##########################################################################################
#  This worked in the define of our function for each batch  for the future ...  the function stuff goes here:
##########################################################################################

# create a unique Id for the row... ideally this should already have been in the payload (and is available if I took the time to load the msg correctly ;)  )
#uuidUDF = udf(lambda : str(uuid.uuid4()),StringType())


df = payloadDF
#        .withColumn("row_key", uuidUDF())


def foreach_batch_function(microdf, batchId):
    print(f"inside forEachBatch for batchid:{batchId}. Rows in passed dataframe:{microdf.count()}")
    microdf.show()
#    microdf.printSchema()
    microdf.filter((microdf.op == "c") | (microdf.op == "u")) \
        .select(microdf.op.alias("type"), \
        microdf.ts_ms.alias("event_ts"), \
        microdf.source.txId.alias("tx_id"), \
        microdf.after.first_name.alias("first_name"), \
        microdf.after.last_name.alias("last_name"), \
        microdf.after.street_address.alias("street_address"), \
        microdf.after.city.alias("city"), \
        microdf.after.state.alias("state"), \
        microdf.after.zip_code.alias("zip_code"), \
        microdf.after.home_phone.alias("home_phone"), \
        microdf.after.mobile.alias("mobile"), \
        microdf.after.email.alias("email"), \
        microdf.after.ssn.alias("ssn"), \
        microdf.after.job_title.alias("job_title"), \
        microdf.after.create_date.alias("create_date"), \
        microdf.after.cust_id.alias("cust_id")).createOrReplaceGlobalTempView("tmp_merge")
    mergeCount=microdf.sql_ctx.sparkSession.sql("SELECT * FROM global_temp.tmp_merge").count()
    print(f"mergeCount= {mergeCount} for batch: {batchId}")
    showMergeDF=microdf.sql_ctx.sparkSession.sql("SELECT * FROM global_temp.tmp_merge").show()
    mergeDF=(microdf.sql_ctx.sparkSession.sql("SELECT * FROM global_temp.tmp_merge"))
    mergeDF.writeTo("icecatalog.icecatalog.stream_customer_event_history").append()
    microdf.filter(microdf.op =="d") \
        .select(microdf.op.alias("type"), \
        microdf.ts_ms.alias("event_ts"), \
        microdf.source.txId.alias("tx_id"), \
        microdf.before.first_name.alias("first_name"), \
        microdf.before.last_name.alias("last_name"), \
        microdf.before.street_address.alias("street_address"), \
        microdf.before.city.alias("city"), \
        microdf.before.state.alias("state"), \
        microdf.before.zip_code.alias("zip_code"), \
        microdf.before.home_phone.alias("home_phone"), \
        microdf.before.mobile.alias("mobile"), \
        microdf.before.email.alias("email"), \
        microdf.before.ssn.alias("ssn"), \
        microdf.before.job_title.alias("job_title"), \
        microdf.before.create_date.alias("create_date"), \
        microdf.before.cust_id.alias("cust_id")).createOrReplaceGlobalTempView("tmp_delete")
    deleteCount=microdf.sql_ctx.sparkSession.sql("SELECT * FROM global_temp.tmp_delete").count()
    print(f"deleteCount= {deleteCount} for batch: {batchId}")
    showDeleteDF=microdf.sql_ctx.sparkSession.sql("SELECT * FROM global_temp.tmp_delete").show()
    deleteDF=(microdf.sql_ctx.sparkSession.sql("SELECT * FROM global_temp.tmp_delete"))
#    deleteDF.printSchema()
    deleteDF.writeTo("icecatalog.icecatalog.stream_customer_event_history").append()

##########################################################################################
#       send stream into foreachBatch
##########################################################################################

streamQuery = (df.writeStream \
    .option("checkpointLocation", "/opt/spark/checkpoint") \
    .foreachBatch(foreach_batch_function) \
    .trigger(processingTime='60 seconds') \
    .start() \
    .awaitTermination())

spark.stop()
