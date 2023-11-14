---- SP DIM - PRODUCT MASTER
create or replace procedure etl.sp_dim_product_master()
language plpgsql as $$
DECLARE
  usuario varchar(10) := current_user ;
BEGIN
  usuario := current_user; 
  with cte as (
  select 
	  	product_code, name, category, subcategory, subsubcategory, 
	  	coalesce(lower(material),'unknown'),
	  	coalesce(lower(color),'unknown'), 
	  	origin, ean, is_active, has_bluetooth, size,
	    CASE 
        	WHEN lower(name) LIKE '%samsung%' THEN 'Samsung'
        	WHEN lower(name) LIKE '%philips%' THEN 'Phillips'
        	WHEN lower(name) LIKE '%levi%' THEN 'Levis'
        	WHEN lower(name) LIKE '%jbl%' THEN 'JBL'
        	WHEN lower(name) LIKE '%motorola%' THEN 'Motorola'
        	WHEN lower(name) LIKE '%tommy%' THEN 'TH'
        ELSE 'Unknown' end as brand
  from stg.product_master
  )
insert into dim.product_master(product_id, name, category, subcategory, subsubcategory, material, color, origin, ean, is_active, has_bluetooth, size, brand)
select * from cte
  on conflict (product_id) do update
  set product_id = excluded.product_id;
  call etl.log('product_master', current_date,'sp_dim_product_master' ,'usuario'); -- SP dentro del SP product_master para dejar log
END;
$$;
-- end of SP
-- select * from dim.product_master
-- call etl.sp_dim_product_master()
