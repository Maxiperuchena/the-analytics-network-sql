---- SP DIM - DATE
create or replace procedure etl.sp_dim_date()
language plpgsql as $$
DECLARE
  usuario varchar(10) := current_user ;
BEGIN
  usuario := current_user; 
 
 select
		to_char (date, 'yyyymmdd'):: INT as date_id,
		cast(date as date) as date,
		extract(month from date) as month,
		extract(year from date) as year,
		extract(day from date) as day,
		to_char(date, 'Day') as weekday,
		to_char(date, 'D') as weekday_number,
		to_char(date, 'Month') as month_label,
		case when
			to_char(date, 'D') = '1' or -- Sunday
			to_char(date, 'D') = '7'  -- Saturday
			then
				True
			else
				False
			end as is_weekend,
			(CASE 
            WHEN EXTRACT(MONTH FROM date) < 2 THEN EXTRACT(YEAR FROM date) - 1 
            ELSE EXTRACT(YEAR FROM date) END || '-02-01')::date AS fiscal_year,
		CONCAT('FY',CASE 
            WHEN EXTRACT(MONTH FROM date) < 2 THEN EXTRACT(YEAR FROM date) - 1 
            ELSE EXTRACT(YEAR FROM date) END) AS fiscal_year_label,
		CASE 
          WHEN EXTRACT(MONTH FROM date) BETWEEN 2 AND 4 THEN 'Q1'
          WHEN EXTRACT(MONTH FROM date) BETWEEN 5 AND 7 THEN 'Q2'
          WHEN EXTRACT(MONTH FROM date) BETWEEN 8 AND 10 THEN 'Q3'
          ELSE 'Q4'	
		END AS fiscal_quarter_label,
		CAST( date - interval '1 year' AS date)::date AS date_ly
		
into	
	dim.date
			
from 	
	(select 	
	 	cast (current_date as date) + (n || 'day') :: interval as date
	from generate_series(0,2554) n ) dd;  -- 365dias/anio * 7anios - 1 = 2554dias (le resto 1 porque arranca de 0)

call etl.log('date', current_date,'sp_dim_date' ,'usuario'); -- SP dentro del SP para dejar log
END;
$$;
