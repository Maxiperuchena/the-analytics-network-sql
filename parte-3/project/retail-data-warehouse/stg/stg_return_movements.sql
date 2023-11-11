-- Table: stg.return_movements

-- DROP TABLE IF EXISTS stg.return_movements;

CREATE TABLE IF NOT EXISTS stg.return_movements
(
    order_id character varying(255) COLLATE pg_catalog."default",
    return_id character varying(255) COLLATE pg_catalog."default",
    item character varying(255) COLLATE pg_catalog."default",
    quantity integer,
    movement_id integer,
    from_location character varying(255) COLLATE pg_catalog."default",
    to_location character varying(255) COLLATE pg_catalog."default",
    received_by character varying(255) COLLATE pg_catalog."default",
    date date
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS stg.return_movements
    OWNER to postgres;
