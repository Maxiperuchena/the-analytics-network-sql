---- SP DIM - EMPLOYEES
create or replace procedure etl.sp_dim_employees()
language plpgsql as $$
DECLARE
  usuario varchar(10) := current_user ;
BEGIN
  usuario := current_user; 
  
  with stg_employees as (
  select 
	    employee_id,
    	name,
    	surname,
   	 	start_date,
    	end_date,
    	case
	  	when end_date is null 
	  		then true
	  		else false 
	  	end as is_active,
    	phone,
    	country,
    	province,
    	store_id,
    	position,
		case
	  	when end_date is null 
	  		then current_date - start_date
	  		else end_date - start_date 
	  	end as duration	
  from stg.employees e
  )
insert into dim.employees(employee_id, employee_name, employee_surname,start_date, end_date, is_active, phone, country, province, store_id, position, duration)
select 

	employee_id, employee_name, employee_surname,start_date, end_date, is_active, phone, country, province, store_id, position, duration
from stg_employees
  on conflict (product_id) do update
  	set supplier_name = excluded.supplier_name;
call etl.log('suppliers', current_date,'sp_dim_suppliers' ,'usuario'); -- SP dentro del SP para dejar log
END;
$$;
-- end of SP
-- select * from dim.suppliers
 call etl.sp_dim_suppliers()
