-- SP FCT - STORE TRAFFIC
create or replace procedure etl.sp_fct_store_traffic() 
language plpgsql as $$

-- declaracion de variables
DECLARE username varchar(10) := current_user;
BEGIN username := current_user;

--transformacion
with stg_traffic as (
select 
	store_id, 
	cast(cast(date as text) as date) as date, 
	traffic 
from stg.market_count
union all
select 
	store_id, 
	cast(date as date) as date, 
	traffic 
from stg.super_store_count	
)

--insert
insert into fct.store_traffic
select
  store_id,
  date,
  traffic
from
  stg_traffic 
on conflict(store_id, date) do nothing;

--sp de log
call etl.log('fct.store_traffic', current_date, 'sp_fct_store_traffic',username);
END;
$$;
-- end of SP
select * from fct.store_traffic
call etl.sp_fct_store_traffic()
