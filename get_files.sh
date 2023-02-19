#!/bin/bash

##########################################################################################
#  load of the utilities functions:
##########################################################################################
echo "load utils"
echo
. ~/data_origination_workshop/utils.sh

##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
#  Define the files as variables;
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
echo "defining vars"
echo
##########################################################################################
# SPARK & ICEBERG ITEMS: 
##########################################################################################
#SPARK_FILE=https://dlcdn.apache.org/spark/spark-3.3.1/spark-3.3.1-bin-hadoop3.tgz
SPARK_FILE=https://dlcdn.apache.org/spark/spark-3.3.2/spark-3.3.2-bin-hadoop3.tgz; echo "SPARK_STANDALONE_FILE=${SPARK_FILE##*/}" >> ~/file_variables.output
COMMONS_POOL2_JAR=https://repo1.maven.org/maven2/org/apache/commons/commons-pool2/2.11.1/commons-pool2-2.11.1.jar; echo "COMMONS_POOL2_FILE=${COMMONS_POOL2_JAR##*/}" >> ~/file_variables.output 
KAFKA_CLIENT_JAR=https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.3.1/kafka-clients-3.3.1.jar; echo "KAFKA_CLIENT_FILE=${KAFKA_CLIENT_JAR##*/}" >> ~/file_variables.output
SPARK_TOKEN_JAR=https://repo.mavenlibs.com/maven/org/apache/spark/spark-token-provider-kafka-0-10_2.12/3.3.1/spark-token-provider-kafka-0-10_2.12-3.3.1.jar; echo "SPARK_TOKEN_FILE=${SPARK_TOKEN_JAR##*/}" >> ~/file_variables.output
SPARK_SQL_KAFKA_JAR=https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/3.3.1/spark-sql-kafka-0-10_2.12-3.3.1.jar; echo "SPARK_SQL_KAFKA_FILE=${SPARK_SQL_KAFKA_JAR##*/}" >> ~/file_variables.output
ICEBERG_SPARK_JAR=https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.3_2.12/1.1.0/iceberg-spark-runtime-3.3_2.12-1.1.0.jar; echo "SPARK_ICEBERG_FILE=${ICEBERG_SPARK_JAR##*/}" >> ~/file_variables.output
URL_CONNECT_JAR=https://repo1.maven.org/maven2/software/amazon/awssdk/url-connection-client/2.19.19/url-connection-client-2.19.19.jar; echo "URL_CONNECT_FILE=${URL_CONNECT_JAR##*/}" >> ~/file_variables.output
AWS_BUNDLE_JAR=https://repo1.maven.org/maven2/software/amazon/awssdk/bundle/2.19.19/bundle-2.19.19.jar; echo "AWS_BUNDLE_FILE=${AWS_BUNDLE_JAR##*/}" >> ~/file_variables.output


##########################################################################################
#  KAKFA CONNECT ITEMS:
##########################################################################################
KCONNECT_FILE=https://dlcdn.apache.org/kafka/3.3.2/kafka_2.13-3.3.2.tgz; echo "KAFKA_CONNECT_FILE=${KCONNECT_FILE##*/}" >> ~/file_variables.output
KCONNECT_JDBC_JAR=https://jdbc.postgresql.org/download/postgresql-42.5.1.jar; echo "KCONNECT_JDBC_FILE=${KCONNECT_JDBC_JAR##*/}" >> ~/file_variables.output
DBZ_CONNECT_FILE=https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/2.1.1.Final/debezium-connector-postgres-2.1.1.Final-plugin.tar.gz; echo "DEBEZIUM_CONNECT_FILE=${DBZ_CONNECT_FILE##*/}" >> ~/file_variables.output

##########################################################################################
#  REDPANDA ITEMS:
##########################################################################################
REDPANDA_REPO_FILE=https://dl.redpanda.com/nzc4ZYQK3WRGd9sy/redpanda/cfg/setup/bash.deb.sh; echo "PANDA_REPO_FILE=${REDPANDA_REPO_FILE##*/}" >> ~/file_variables.output
REDPANDA_FILE=https://github.com/redpanda-data/redpanda/releases/latest/download/rpk-linux-amd64.zip; echo "PANDA_FILE=${REDPANDA_FILE##*/}" >> ~/file_variables.output

##########################################################################################
#  POSTGRESQL ITEMS:
##########################################################################################
PSQL_REPO_KEY=https://www.postgresql.org/media/keys/ACCC4CF8.asc; echo "POSTGRESQL_KEY_FILE=${PSQL_REPO_KEY##*/}" >> ~/file_variables.output
PSQL_JDBC_JAR=https://jdbc.postgresql.org/download/postgresql-42.5.1.jar; echo "POSTGRESQL_FILE=${KCONNECT_JDBC_JAR##*/}" >> ~/file_variables.output

##########################################################################################
# MINIO ITEMS:
##########################################################################################
MINIO_CLI_FILE=https://dl.min.io/client/mc/release/linux-amd64/mc; echo "MINIO_FILE=${MINIO_CLI_FILE##*/}" >> ~/file_variables.output
MINIO_PACKAGE=https://dl.min.io/server/minio/release/linux-amd64/archive/minio_20230112020616.0.0_amd64.deb; echo "MINIO_PACKAGE_FILE=${MINIO_PACKAGE##*/}" >> ~/file_variables.output

##########################################################################################
#  DOCKER ITEMS:
##########################################################################################
DOCKER_KEY_FILE=https://download.docker.com/linux/ubuntu/gpg; echo "DOCKER_REPO_KEY_FILE=${DOCKER_KEY_FILE##*/}" >> ~/file_variables.output

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
echo "calling get_valid_urls"
echo
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
