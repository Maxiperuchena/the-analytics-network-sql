 -- SP FCT - FX Rate
create or replace procedure etl.sp_fct_fx_rate() 
language plpgsql as $$

-- declaracion de variables
DECLARE username varchar(10) := current_user;
BEGIN username := current_user;

--transformacion
with stg_fx as (
select 
	month, 
	fx_rate_usd_peso, 
	fx_rate_usd_eur, 
	fx_rate_usd_uru 
from stg.monthly_average_fx_rate
)

--insert
insert into fct.fx_rate
select
  	month, 
	fx_rate_usd_peso, 
	fx_rate_usd_eur, 
	fx_rate_usd_uru 
from
  stg_fx 
on conflict(month) do nothing;

--sp de log
call etl.log('fct.fx_rate', current_date, 'sp_fct_fx_rate',username);
END;
$$;
-- end of SP
select * from fct.fx_rate
call etl.sp_fct_fx_rate()
