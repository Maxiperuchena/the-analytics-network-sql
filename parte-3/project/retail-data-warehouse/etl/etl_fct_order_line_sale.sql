-- Modifico la tabla OLS antes de hacer el SP
-- Agrego columna line_key
alter table fct.order_line_sale
add line_key VARCHAR(255);
--agrego constante de unicidad en line_key para que me funcione el "on conflict do nothing"
alter table fct.order_line_sale
add unique (line_key);

-- SP FCT - Order Line Sale
create or replace procedure etl.sp_fct_order_line_sale() 
language plpgsql as $$

-- declaracion de variables
DECLARE username varchar(10) := current_user;
BEGIN username := current_user;

--transformacion
with stg_ols as (
select 
	order_number,
	product,
	store,
	date,
	quantity,
	sale,
	promotion,
	tax,
	credit,
	currency,
	pos,
	is_walkout,
	concat( order_number, '-', product) as line_key
from stg.order_line_sale
)

--insert
insert into fct.order_line_sale
select
  	order_number,
	product,
	store,
	date,
	quantity,
	sale,
	promotion,
	tax,
	credit,
	currency,
	pos,
	is_walkout,
	line_key
from
  stg_ols 
on conflict(line_key) do nothing;

--sp de log
call etl.log('fct.order_line_sale', current_date, 'sp_fct_order_line_sale',username);
END;
$$;
-- end of SP
select * from fct.order_line_sale
call etl.sp_fct_order_line_sale()
