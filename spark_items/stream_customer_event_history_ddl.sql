CREATE TABLE icecatalog.icecatalog.stream_customer_event_history (
    type STRING,
    event_ts LONG,
    tx_id STRING,
    first_name STRING,
    last_name STRING,
    street_address STRING,
    city STRING,
    state STRING,
    zip_code STRING,
    home_phone STRING,
    mobile STRING,
    email STRING,
    ssn STRING,
    job_title STRING,
    create_date STRING,
    cust_id BIGINT)
USING iceberg
OPTIONS (
    'write.object-storage.enabled'=true,
    'write.data.path'='s3://iceberg-data');
