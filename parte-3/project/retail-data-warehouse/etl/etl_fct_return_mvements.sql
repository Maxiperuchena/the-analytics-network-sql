-- Modifico la tabla return_movements antes de hacer el SP
--agrego constante de unicidad en para que me funcione el "on conflict do nothing"
alter table if exists fct.return_movements
add unique (return_id,movement_id);


-- SP FCT - Return movements
create or replace procedure etl.sp_fct_return_movements() 
language plpgsql as $$

-- declaracion de variables
DECLARE username varchar(10) := current_user;
BEGIN username := current_user;

--transformacion
with stg_ret as (
select 
	order_id,
	return_id,
	item,
	quantity,
	movement_id,
	from_location,
	to_location,
	received_by,
	date
from stg.return_movements
)

--insert
insert into fct.return_movements
select
  	order_id,
	return_id,
	item,
	quantity,
	movement_id,
	from_location,
	to_location,
	received_by,
	date
from
  stg_ret 
on conflict(return_id,movement_id) do nothing;

--sp de log
call etl.log('fct.return_movements', current_date, 'sp_fct_return_movements',username);
END;
$$;
-- end of SP
select * from fct.return_movements
call etl.sp_fct_return_movements()
