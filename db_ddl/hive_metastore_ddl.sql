CREATE USER hive;
ALTER ROLE hive WITH PASSWORD 'supersecret1';
CREATE DATABASE hive_metastore;
GRANT ALL PRIVILEGES ON DATABASE hive_metastore TO hive;
