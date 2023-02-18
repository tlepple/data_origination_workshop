#!/bin/bash


. ~/minio-output.properties

export AWS_ACCESS_KEY_ID=$access_key
export AWS_SECRET_ACCESS_KEY=$secret_key
export AWS_S3_ENDPOINT=127.0.0.1:9000
export AWS_REGION=us-east-1
export MINIO_REGION=us-east-1
export AWS_SDK_VERSION=2.19.19
export AWS_MAVEN_GROUP=software.amazon.awssdk

spark-sql --packages \
  org.apache.iceberg:iceberg-spark-runtime-3.3_2.12:1.1.0, \
  software.amazon.awssdk:bundle:2.19.19, \
  software.amazon.awssdk:url-connection-client:2.19.19 \
--properties-file /opt/spark/sql/conf.properties \
-i
