CREATE or REPLACE FUNCTION datagen.insert_from_json(json)
    RETURNS void
LANGUAGE 'plpgsql'
COST 100
VOLATILE
AS $BODY$

BEGIN
  INSERT INTO datagen.customer(first_name, last_name, street_address, city, state, zip_code, home_phone, mobile, email, ssn, job_title, create_date, cust_id)
   SELECT
    x.first_name
,x.last_name
,x.street_address
,x.city
,x.state
,x.zip_code
,x.home_phone
,x.mobile
,x.email
,x.ssn
,x.job_title
,x.create_date
,x.cust_id
FROM json_to_record($1) AS x
  (
    first_name text,
last_name text,
street_address text,
city text,
state text,
zip_code text,
home_phone text,
mobile text,
email text,
ssn text,
job_title text,
create_date text,
cust_id int
  )
ON CONFLICT (cust_id) DO UPDATE SET
    first_name = EXCLUDED.first_name
    ,last_name = EXCLUDED.last_name
    ,street_address = EXCLUDED.street_address
    ,city = EXCLUDED.city
    ,state = EXCLUDED.state
    ,zip_code = EXCLUDED.zip_code
    ,home_phone = EXCLUDED.home_phone
    ,mobile = EXCLUDED.mobile
    ,email = EXCLUDED.email
    ,ssn = EXCLUDED.ssn
    ,job_title = EXCLUDED.job_title
    ,create_date = EXCLUDED.create_date;


END;
$BODY$;
