
DROP TABLE IF EXISTS dim.suppliers;

CREATE TABLE IF NOT EXISTS dim.suppliers
(
    product_id VARCHAR(10) PRIMARY KEY,
    supplier_name character varying(255),
    is_primary boolean,
	
	constraint fk_product_id_suppliers
		foreign key (product_id)
		references dim.product_master(product_id)
	
);
