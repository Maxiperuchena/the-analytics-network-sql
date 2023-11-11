DROP TABLE IF EXISTS fct.inventory;

CREATE TABLE IF NOT EXISTS fct.inventory
(
    date date,
    store_id smallint,
    product_id character varying(10) COLLATE pg_catalog."default",
    initial smallint,
    final smallint,
	-- declaro las foreign keys y las relaciono con las dim
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
