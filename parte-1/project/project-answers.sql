
-- Proyecto parte 1 - Maximiliano Peruchena

with stg_sales as (
select 
	s.*,
	prd.*,
	case
		when currency = 'ARS' then (coalesce(sale,0) / fx_rate_usd_peso)
		when currency = 'EUR' then (coalesce(sale,0) / fx_rate_usd_eur) 
		when currency = 'URU' then (coalesce(sale,0) / fx_rate_usd_uru)
		else sale 
	end sale_USD,
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
	product_cost_usd,
	initial,
	final
from stg.order_line_sale s 
left join stg.store_master store 
on s.store = store.store_id
left join stg.product_master prd
on s.product = prd.product_code
left join stg.monthly_average_fx_rate fx
on date_trunc('month', s.date) = fx.month
left join stg.cost c
on s.product = c.product_code
left join stg.inventory inv
on (s.date = inv. date) and (s.store = inv.store_id) and (s.product = inv.item_id) 
left join stg.suppliers sup
on s.product = sup.product_id
where sup.is_primary = true
)

-- Ventas brutas
select 	
	cast(date_trunc('month', s.date) as date) mes,
	sum( sale_USD ) as Ventas_Brutas
from stg_sales s
group by mes
order by mes
	
-- Ventas netas = Ventas - descuentos y devoluciones

select 	
	cast(date_trunc('month', s.date) as date) mes,
	sum( sale_USD ) - sum( promotion_USD ) as Ventas_Netas
from stg_sales s
group by mes
order by mes

-- Margen (USD) = ventas - descuentos - costo

select
	cast(date_trunc('month', s.date) as date) mes,
	sum(sale_USD) - sum(promotion_USD) - sum(product_cost_USD) as margin_USD
from stg_sales s
group by mes
order by mes

-- Margen por categoria (USD) = ventas - descuentos - costo

select 	
	category,
	cast(date_trunc('month', s.date) as date) mes,
	sum(sale_USD) - sum(promotion_USD) - sum(product_cost_USD) as margin_USD
from stg_sales s
group by category, mes
order by category, mes

-- - ROI por categoria de producto. ROI = ventas netas / Valor promedio de inventario (USD)

select 	
	category,
	cast(date_trunc('month', s.date) as date) mes,
	( sum( sale_USD ) - sum( promotion_USD )) / sum(((initial + final)*1.00/2) * product_cost_usd ) as ROI
from stg_sales s
group by category, mes
order by category, mes
  
-- - AOV (Average order value), valor promedio de la orden. (USD)

select 	
	cast(date_trunc('month', s.date) as date) mes,
	sum( sale_USD ) / count( distinct order_number ) as AOV
from stg_sales s
group by mes
order by mes

-- Contabilidad (USD)
-- - Impuestos pagados

select 
	cast(date_trunc('month', s.date) as date) mes,
	sum( tax_USD ) as tax
from stg_sales s
group by mes
order by mes
 
-- - Tasa de impuesto. Impuestos / Ventas netas 

select 	
	cast(date_trunc('month', s.date) as date) mes,
	(sum( tax_USD )) / ( sum( sale_USD ) - sum( promotion_USD )) as tax_rate
from stg_sales s
group by mes
order by mes

-- - Cantidad de creditos otorgados

  
select 	
	cast(date_trunc('month', s.date) as date) mes,
	sum( case when credit_USD != 0 then 1 else 0 end )  as credits
from stg_sales s
group by mes
order by mes

-- - Valor pagado final por orden de linea. Valor pagado: Venta - descuento + impuesto - credito

select 	
	cast(date_trunc('month', s.date) as date) mes,
	sum( sale_USD ) - sum( promotion_USD ) + sum( tax_USD ) - sum( credit_USD ) as VPF
from stg_sales s
group by mes
order by mes
  

-- Supply Chain (USD)
-- - Costo de inventario promedio por tienda

-- creo una nueva CTE para este calculo ya que la tabla principal ahora no es ventas, sino inventario
with stg_inventory as (
select 
	inv.*,
	product_cost_usd,
	(((initial + final)*1.00/2)  * product_cost_usd ) as avg_inventory_cost,
	((final*1.00)  * product_cost_usd ) as inventory_cost
from stg.inventory inv
left join stg.cost c
on inv.item_id = c.product_code
order by date, store_id, item_id
)

-- - Costo de inventario promedio por tienda

select 	
	cast(date_trunc('month', inv.date) as date) mes, 
	store_id store,
	avg(avg_inventory_cost)	avg_inventory_cost
from stg_inventory inv
group by 
	mes,
	store
order by 
	mes,
	store
  

-- - Costo del stock de productos que no se vendieron por tienda

  select 	
	cast(date_trunc('month', inv.date) as date) mes, 
	store_id store,
	avg(inventory_cost)	unsold_inventory_cost
from stg_inventory inv
group by 
	mes,
	store
order by 
	mes,
	store

  
-- - Cantidad y costo de devoluciones

  with stg_returns as (
select 
	r.date,
	r.return_id,
	avg(c.product_cost_usd) return_cost
from stg.return_movements r
left join stg.cost c
on r.item = c.product_code
group by date, return_id
order by date, return_id
) 

select
	cast(date_trunc('month', ret.date) as date) mes, 
	count(distinct ret.return_id) returns,
	sum(ret.return_cost) returns_costs
from stg_returns ret
group by mes
order by mes

-- Tiendas
-- - Ratio de conversion. Cantidad de ordenes generadas / Cantidad de gente que entra

-- CVR -- Cantidad de ordenes generadas / Cantidad de gente que entra

with stg_sales as (
select 
	store,
	store.country as country,
	date,
	count(distinct order_number) as qty_orders
from stg.order_line_sale s 
left join stg.store_master store 
on s.store = store.store_id
left join stg.product_master prd
on s.product = prd.product_code
left join stg.monthly_average_fx_rate fx
on date_trunc('month', s.date) = fx.month
left join stg.cost c
on s.product = c.product_code
left join stg.suppliers sup
on s.product = sup.product_id
where sup.is_primary = True
group by 
	store,
	date,
	store.country
)

, stg_traffic as (
select * 
	from stg.vw_store_traffic
)

-- CVR -- Cantidad de ordenes generadas / Cantidad de gente que entra

select 
	cast(date_trunc('month', s.date) as date) mes, 
	sum(qty_orders*1.00)/sum(traffic*1.00) as cvr
from stg_sales s
left join stg_traffic t
on s.store = t.store_id
and s.date = t.date
group by 
	date_trunc('month', s.date)
	order by 1 desc
;
