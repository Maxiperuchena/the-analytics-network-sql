DROP TABLE IF EXISTS dim.employees;

CREATE TABLE IF NOT EXISTS dim.employees
(
    employee_id serial PRIMARY KEY,    --'nextval('dim.employees_employee_id_seq'::regclass)',
    employee_name character varying(255) COLLATE pg_catalog."default",
    employee_surname character varying(255) COLLATE pg_catalog."default",
    start_date date,
    end_date date,
    is_active boolean,
    phone character varying(20) COLLATE pg_catalog."default",
    country character varying(50) COLLATE pg_catalog."default",
    province character varying(50) COLLATE pg_catalog."default",
    store_id smallint,
    position character varying(255) COLLATE pg_catalog."default",
	constraint fk_store_id
		foreign key (store_id)
		references dim.store_master(store_id)	
	
);

