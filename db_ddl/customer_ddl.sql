CREATE schema datagen;
CREATE TABLE datagen.customer
(
    first_name character varying(50) COLLATE pg_catalog."default",
    last_name character varying(50) COLLATE pg_catalog."default",
    street_address character varying(100) COLLATE pg_catalog."default",
    city character varying(50) COLLATE pg_catalog."default",
    state character varying(50) COLLATE pg_catalog."default",
    zip_code character varying(50) COLLATE pg_catalog."default",
    home_phone character varying(50) COLLATE pg_catalog."default",
    mobile character varying(50) COLLATE pg_catalog."default",
    email character varying(50) COLLATE pg_catalog."default",
    ssn character varying(25) COLLATE pg_catalog."default",
    job_title character varying(50) COLLATE pg_catalog."default",
    create_date character varying(50) COLLATE pg_catalog."default",
        cust_id integer NOT NULL,
    CONSTRAINT customer_pkey PRIMARY KEY (cust_id)
);
