-- Table: stg.employees

-- DROP TABLE IF EXISTS stg.employees;

CREATE TABLE IF NOT EXISTS stg.employees
(
    employee_id integer NOT NULL DEFAULT 'nextval('stg.employees_employee_id_seq'::regclass)',
    name character varying(255) COLLATE pg_catalog."default",
    surname character varying(255) COLLATE pg_catalog."default",
    start_date date,
    end_date date,
    phone character varying(20) COLLATE pg_catalog."default",
    country character varying(255) COLLATE pg_catalog."default",
    province character varying(255) COLLATE pg_catalog."default",
    store_id smallint,
    "position" character varying(255) COLLATE pg_catalog."default",
    CONSTRAINT employees_pkey PRIMARY KEY (employee_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS stg.employees
    OWNER to postgres;
