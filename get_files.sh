#!/bin/bash

##########################################################################################
#  load of the utilities functions:
##########################################################################################
. utils.sh

##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
#  Define the files as variables;
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################

##########################################################################################
# SPARK & ICEBERG ITEMS:
##########################################################################################
#SPARK_FILE=https://dlcdn.apache.org/spark/spark-3.3.1/spark-3.3.1-bin-hadoop3.tgz
SPARK_FILE=https://dlcdn.apache.org/spark/spark-3.3.2/spark-3.3.2-bin-hadoop3.tgz  
COMMONS_POOL2_JAR=https://repo1.maven.org/maven2/org/apache/commons/commons-pool2/2.11.1/commons-pool2-2.11.1.jar
KAFKA_CLIENT_JAR=https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.3.1/kafka-clients-3.3.1.jar
SPARK_TOKEN_JAR=https://repo.mavenlibs.com/maven/org/apache/spark/spark-token-provider-kafka-0-10_2.12/3.3.1/spark-token-provider-kafka-0-10_2.12-3.3.1.jar
SPARK_SQL_KAFKA_JAR=https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/3.3.1/spark-sql-kafka-0-10_2.12-3.3.1.jar
ICEBERG_SPARK_JAR=https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.3_2.12/1.1.0/iceberg-spark-runtime-3.3_2.12-1.1.0.jar
URL_CONNECT_JAR=https://repo1.maven.org/maven2/software/amazon/awssdk/url-connection-client/2.19.19/url-connection-client-2.19.19.jar
AWS_BUNDLE_JAR=https://repo1.maven.org/maven2/software/amazon/awssdk/bundle/2.19.19/bundle-2.19.19.jar

##########################################################################################
#  KAKFA CONNECT ITEMS:
##########################################################################################
KCONNECT_FILE=https://dlcdn.apache.org/kafka/3.3.2/kafka_2.13-3.3.2.tgz
KCONNECT_JDBC_JAR=https://jdbc.postgresql.org/download/postgresql-42.5.1.jar
DBZ_CONNECT_FILE=https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/2.1.1.Final/debezium-connector-postgres-2.1.1.Final-plugin.tar.gz

##########################################################################################
#  REDPANDA ITEMS:
##########################################################################################
REDPANDA_REPO_FILE=https://dl.redpanda.com/nzc4ZYQK3WRGd9sy/redpanda/cfg/setup/bash.deb.sh
REDPANDA_FILE=https://github.com/redpanda-data/redpanda/releases/latest/download/rpk-linux-amd64.zip

##########################################################################################
#  POSTGRESQL ITEMS:
##########################################################################################
PSQL_REPO_KEY=https://www.postgresql.org/media/keys/ACCC4CF8.asc
PSQL_JDBC_JAR=https://jdbc.postgresql.org/download/postgresql-42.5.1.jar

##########################################################################################
# MINIO ITEMS:
##########################################################################################
MINIO_CLI_FILE=https://dl.min.io/client/mc/release/linux-amd64/mc
MINIO_PACKAGE=https://dl.min.io/server/minio/release/linux-amd64/archive/minio_20230112020616.0.0_amd64.deb -O minio.deb

##########################################################################################
#  DOCKER ITEMS:
##########################################################################################
DOCKER_KEY_FILE=https://download.docker.com/linux/ubuntu/gpg

##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
#  Get the files from the above variables;
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################

##########################################################################################
#  GET - SPARK & ICEBERG ITEMS:
##########################################################################################
get_valid_url $SPARK_FILE
get_valid_url $COMMONS_POOL2_JAR
get_valid_url $KAFKA_CLIENT_JAR
get_valid_url $SPARK_TOKEN_JAR
get_valid_url $SPARK_SQL_KAFKA_JAR
get_valid_url $ICEBERG_SPARK_JAR
get_valid_url $URL_CONNECT_JAR
get_valid_url $AWS_BUNDLE_JAR

##########################################################################################
#  GET - KAKFA CONNECT ITEMS:
##########################################################################################
get_valid_url $KCONNECT_FILE
get_valid_url $KCONNECT_JDBC_JAR
get_valid_url $DBZ_CONNECT_FILE

##########################################################################################
#  GET - REDPANDA ITEMS:
##########################################################################################
get_valid_url $REDPANDA_REPO_FILE
get_valid_url $REDPANDA_FILE

##########################################################################################
#  GET - POSTGRESQL ITEMS:
##########################################################################################
get_valid_url $PSQL_REPO_KEY
get_valid_url $PSQL_JDBC_JAR

##########################################################################################
# GET - MINIO ITEMS:
##########################################################################################
get_valid_url $MINIO_CLI_FILE
get_valid_url $MINIO_PACKAGE

##########################################################################################
#  GET - DOCKER ITEMS:
##########################################################################################
get_valid_url $DOCKER_KEY_FILE

