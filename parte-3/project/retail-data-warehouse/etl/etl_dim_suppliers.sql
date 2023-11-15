---- SP DIM - SUPPLIER
create or replace procedure etl.sp_dim_suppliers()
language plpgsql as $$
DECLARE
  usuario varchar(10) := current_user ;
BEGIN
  usuario := current_user; 
  with stg_suppliers as (
  select 
	  	s.product_id,
	  	s.name,
	  	s.is_primary
  from stg.suppliers s
  inner join dim.product_master pm
  on s.product_id = pm.product_id
  where is_primary = 'true'
  )
insert into dim.suppliers(product_id, supplier_name, is_primary)
select 
	product_id,
	name,
	is_primary
from stg_suppliers
  on conflict (product_id) do update
  	set supplier_name = excluded.supplier_name;
call etl.log('suppliers', current_date,'sp_dim_suppliers' ,'usuario'); -- SP dentro del SP para dejar log
END;
$$;
-- end of SP
-- select * from dim.suppliers
 -- call etl.sp_dim_suppliers()
