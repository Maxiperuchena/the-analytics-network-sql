---- SP DIM - COST
create or replace procedure etl.sp_dim_cost()
language plpgsql as $$
DECLARE
  usuario varchar(10) := current_user ;
BEGIN
  usuario := current_user; 
  with stg_cost as (
  select 
	  	c.product_code,
	  	c.product_cost_usd
  from stg.cost c
  inner join dim.product_master pm
  on c.product_code = pm.product_id
  )
insert into dim.cost(product_id, cost_usd)
select 
	product_code, 
	product_cost_usd 
from stg_cost
  on conflict (product_id) do update
  	set cost_usd = excluded.cost_usd;
call etl.log('cost', current_date,'sp_dim_cost' ,'usuario'); -- SP dentro del SP para dejar log
END;
$$;
-- end of SP
-- select * from dim.cost
-- call etl.sp_dim_cost()
 
