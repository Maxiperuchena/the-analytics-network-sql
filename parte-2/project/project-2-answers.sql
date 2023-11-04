-- Proyecto 2 - Maxi Peruchena
/*
DATOS AGM:
de:	Agus Velazquez <hola@theanalyticsnetwork.tech>
para:	
fecha:	4 sept 2023, 20:41
asunto:	sql de cero a messi
enviado por:	gmail.com

--------------------------------------------

Hola!  

Para los AGM del periodo solo tenemos esto:

- Philips nos regalo una TV valuada en 20.000 USD para todo el periodo 2022 y 5.000 USD para lo que van del 2023.

Aplicarlo a todos los productos de Philips porque no tenemos el código de producto. 

Saludos,
Agustin
*/

-- creo la nueva tabla

drop table if exists stg.shrinkage ;

create table if not exists stg.shrinkage (
	year numeric,
	store_id smallint,
	item_id character varying(255),
	quantity integer
)

-- Ahora si armo la vista

create schema if not exists viz

create view viz.order_sale_line as

with cte_products_sold as (  
select 
	extract(year from ols.date) as year,
	ols.store as store,
	ols.product as product,
	sum(quantity) as qty_sold
from stg.order_line_sale ols
group by extract(year from ols.date), ols.store, ols.product
order by extract(year from ols.date), ols.store, ols.product
),
cte_shrinkage as (
select 
	s.year,
	s.store_id,
	s.item_id,
	s.quantity,
	s.quantity * c.product_cost_usd as total_cost,
	ps.qty_sold,
	( s.quantity * c.product_cost_usd / ps.qty_sold ) as losts_per_item 
from stg.shrinkage s
left join stg.cost c
on s.item_id = c.product_code
left join cte_products_sold ps
on (s.year = ps.year) and (s.store_id = ps.store) and (s.item_id = ps.product)
order by s.year, s.store_id, s.item_id
),	
--select * 

--from cte_shrinkage
	
ventas_usd as (   
select
	ols.*,
	pm.*,
	sm.country as store_country,
	sm.province as store_province,
	sm.name as store_name,
	sup.name as supplier_name,
	d.month, 
	d.month_label,
	d.year,
	d.fiscal_year,
	d.fiscal_quarter_label,
	case
		when currency = 'ARS' then (coalesce(sale,0) / fx_rate_usd_peso)
		when currency = 'EUR' then (coalesce(sale,0) / fx_rate_usd_eur) 
		when currency = 'URU' then (coalesce(sale,0) / fx_rate_usd_uru)
		else sale 
	end gross_sale_USD,
	case
		when currency = 'ARS' then (coalesce(promotion,0) / fx_rate_usd_peso)
		when currency = 'EUR' then (coalesce(promotion,0) / fx_rate_usd_eur)
		when currency = 'URU' then (coalesce(promotion,0) / fx_rate_usd_uru)
		else promotion 
	end promotion_USD,
	case
		when currency = 'ARS' then (coalesce(credit,0) / fx_rate_usd_peso)
		when currency = 'EUR' then (coalesce(credit,0) / fx_rate_usd_eur) 
		when currency = 'URU' then (coalesce(credit,0) / fx_rate_usd_uru)
		else credit 
	end credit_USD,
	case
		when currency = 'ARS' then (coalesce(tax,0) / fx_rate_usd_peso)
		when currency = 'EUR' then (coalesce(tax,0) / fx_rate_usd_eur) 
		when currency = 'URU' then (coalesce(tax,0) / fx_rate_usd_uru)
		else tax
	end tax_USD,
	(product_cost_usd * ols.quantity) as line_cost_USD,
	ret.quantity as quantity_returned,
	first_value (from_location) over(partition by ret.return_id order by movement_id asc) as first_location,
	last_value (to_location) over(partition by ret.return_id) as last_location, 
	sh.losts_per_item
from stg.order_line_sale ols

-- joins
left join stg.monthly_average_fx_rate fx
	on date_trunc('month',ols.date) = fx.month
left join stg.cost c
	on ols.product = c.product_code
left join stg.product_master pm
	on ols.product = pm.product_code
left join stg.suppliers sup
	on  ols.product = sup.product_id  
left join stg.store_master sm
	on ols.store = sm.store_id
left join stg.date d
	on ols.date = d.date
left join stg.return_movements ret
	on (ols.order_number = ret.order_id) and (ols.product = ret.item) and (	ret.movement_id = 2)
left join cte_shrinkage sh
	on ( extract(year from ols.date) = sh.year ) and (ols.store = sh.store_id) and (ols.product = sh.item_id)
where sup.is_primary = True
),
--select *
--from ventas_usd

adjusted_ventas_usd as (
	
select
	s.*,
	sale - promotion as net_sales,
	gross_sale_usd - promotion_usd as net_sales_usd,
	sale - promotion - tax - credit as amount_paid,
	gross_sale_usd - promotion_usd - tax_usd - credit_usd as amount_paid_usd,
	s.line_cost_USD as sale_line_cost_usd,
	gross_sale_usd - promotion_usd - s.line_cost_USD as gross_margin_usd,
	case
		when brand like 'Philips' and extract(year from s.date) = 2022 then 	
				gross_sale_usd - s.line_cost_USD + (20000 / 
												    (select 
														sum (quantity)
												    from stg.order_line_sale ol
													left join stg.suppliers s
													on ol.product = s.product_id
													where 
														1=1 and
														s.is_primary = true and
														s.name like 'Philips' and
														extract(year from date) = 2022 )) - losts_per_item 
		when brand like 'Philips' and extract(year from s.date) = 2023 then 	
				gross_sale_usd - s.line_cost_USD + (5000 / 
												    (select 
														sum (quantity)
												    from stg.order_line_sale ol
													left join stg.suppliers s
													on ol.product = s.product_id
													where 
														1=1 and
														s.is_primary = true and
														s.name like 'Philips' and
														extract(year from date) = 2023 )) - losts_per_item 
		else
			gross_sale_usd - s.line_cost_USD - losts_per_item
	end as adjusted_gross_margin_usd						   
												   
from ventas_usd s
)
select
	*
from adjusted_ventas_usd
-- end of view
