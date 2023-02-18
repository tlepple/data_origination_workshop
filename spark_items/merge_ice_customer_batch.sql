CREATE TEMPORARY VIEW mergeCustomerView
  USING org.apache.spark.sql.json
  OPTIONS (
    path "/opt/spark/input/update_customers.json"
  );
  MERGE INTO icecatalog.icecatalog.customer c
USING (SELECT
             first_name,
             last_name,
             street_address,
             city,
             state,
             zip_code,
             home_phone,
             mobile,
             email,
             ssn,
             job_title,
             create_date,
             cust_id
       FROM mergeCustomerView) j
ON c.cust_id = j.cust_id
WHEN MATCHED THEN UPDATE SET
             c.first_name = j.first_name,
             c.last_name = j.last_name,
             c.street_address = j.street_address,
             c.city = j.city,
             c.state = j.state,
             c.zip_code = j.zip_code,
             c.home_phone = j.home_phone,
             c.mobile = j.mobile,
             c.email = j.email,
             c.ssn = j.ssn,
             c.job_title = j.job_title,
             c.create_date = j.create_date
WHEN NOT MATCHED THEN INSERT *;
