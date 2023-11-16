DROP TABLE IF EXISTS fct.order_line_sale;

CREATE TABLE IF NOT EXISTS fct.order_line_sale
(
    order_number character varying(255) PRIMARY KEY COLLATE pg_catalog."default",
    product_id VARCHAR(10) COLLATE pg_catalog."default",
    store_id smallint,
    date date,
    quantity integer,
    sale numeric(18,5),
    promotion numeric(18,5),
    tax numeric(18,5),
    credit numeric(18,5),
    currency character varying(3) COLLATE pg_catalog."default",
    pos smallint,
    is_walkout boolean,
    line_key VARCHAR(255),
	
	-- declaro las foreign keys y las relaciono con las dim
	CONSTRAINT order_line_sale_line_key UNIQUE (line_key),
	constraint fk_store_id
		foreign key (store_id)
		references dim.store_master(store_id),
	constraint fk_product_id
		foreign key (product_id)
		references dim.product_master(product_id),
	constraint fk_date
		foreign key (date)
		references dim.date(date)
	
);
