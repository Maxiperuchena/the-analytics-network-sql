DROP TABLE IF EXISTS fct.return_movements;

CREATE TABLE IF NOT EXISTS fct.return_movements
(
   	order_id character varying(255) COLLATE pg_catalog."default",
    return_id character varying(255) PRIMARY KEY COLLATE pg_catalog."default",
    product_id VARCHAR(10) COLLATE pg_catalog."default",
    quantity integer,
    movement_id integer,
    from_location character varying(20) COLLATE pg_catalog."default",
    to_location character varying(20) COLLATE pg_catalog."default",
    received_by character varying(30) COLLATE pg_catalog."default",
    date date,	
	
	-- declaro las foreign keys y las relaciono con las dim
	constraint fk_product_id
		foreign key (product_id)
		references dim.product_master(product_id),
	constraint fk_date
		foreign key (date)
		references dim.date(date)
	
);
