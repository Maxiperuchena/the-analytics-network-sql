-- Table: stg.suppliers

-- DROP TABLE IF EXISTS stg.suppliers;

CREATE TABLE IF NOT EXISTS stg.suppliers
(
    product_id character varying(7) COLLATE pg_catalog."default",
    name character varying(255) COLLATE pg_catalog."default",
    is_primary boolean
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS stg.suppliers
    OWNER to postgres;
