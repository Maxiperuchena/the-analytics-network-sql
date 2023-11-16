-- Modifico la tabla inventory antes de hacer el SP
--agrego constante de unicidad en line_key para que me funcione el "on conflict do nothing"
alter table fct.inventory
add unique (date,store_id,product_id);


-- SP FCT - Inventory
create or replace procedure etl.sp_fct_inventory() 
language plpgsql as $$

-- declaracion de variables
DECLARE username varchar(10) := current_user;
BEGIN username := current_user;

--transformacion
with stg_inv as (
select 
	date,
	store_id,
	item_id,
	initial,
	final
from stg.inventory
)

--insert
insert into fct.inventory
select
  	date,
	store_id,
	item_id,
	initial,
	final
from
  stg_inv 
on conflict(date,store_id,product_id) do nothing;

--sp de log
call etl.log('fct.inventory', current_date, 'sp_fct_inventory',username);
END;
$$;
-- end of SP
select * from fct.inventory
call etl.sp_fct_inventory()
