eo-- ## Semana 3 - Parte A

-- 1.Crear una vista con el resultado del ejercicio donde unimos la cantidad de gente que ingresa a tienda usando los dos sistemas.(tablas market_count y super_store_count)
-- . Nombrar a la lista `stg.vw_store_traffic`
-- . Las columnas son `store_id`, `date`, `traffic`

create view stg.vw_store_traffic as 
select 
	store_id,
	TO_DATE((date)::text, 'YYYYMMDD') as date,
	traffic
from stg.market_count
union
select 
	store_id,
	TO_DATE((date)::text, 'YYYY-MM-DD') as date,
	traffic
from stg.super_store_count ssc
order by date, store_id


-- 2. Recibimos otro archivo con ingresos a tiendas de meses anteriores. Subir el archivo a stg.super_store_count_aug y agregarlo a la vista del ejercicio anterior. Cual hubiese sido la diferencia si hubiesemos tenido una tabla? (contestar la ultima pregunta con un texto escrito en forma de comentario)

-- Primero creo la tabla:

CREATE TABLE IF NOT EXISTS stg.super_store_count_aug
(
    store_id smallint,
    date character varying(10) COLLATE pg_catalog."default",
    traffic smallint
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS stg.super_store_count_aug
    OWNER to postgres;
-- Luego cargo los datos manualmente desde "import" con el archivo .xls.
-- finalmente modifico la vista:

CREATE OR REPLACE VIEW stg.vw_store_traffic
 AS
 SELECT market_count.store_id,
    to_date(market_count.date::text, 'YYYYMMDD'::text) AS date,
    market_count.traffic
   FROM stg.market_count
UNION ALL
 SELECT ssc.store_id,
    to_date(ssc.date::text, 'YYYY-MM-DD'::text) AS date,
    ssc.traffic
   FROM stg.super_store_count ssc
UNION ALL
 SELECT ssca.store_id,
    to_date(ssca.date::text, 'YYYY-MM-DD'::text) AS date,
    ssca.traffic
   FROM stg.super_store_count_aug ssca
  ORDER BY 2, 1;

-- Si en vez de una vista, hubiese tenido una tabla, hubiera tenido que agregar los datos con un insert into:

select 
	*
into stg.super_store_count
from stg.super_store_count_aug ssca
;

-- 3. Crear una vista con el resultado del ejercicio del ejercicio de la Parte 1 donde calculamos el margen bruto en dolares. Agregarle la columna de ventas, promociones, creditos, impuestos y el costo en dolares para poder reutilizarla en un futuro. Responder con el codigo de creacion de la vista.
-- El nombre de la vista es stg.vw_order_line_sale_usd
-- Los nombres de las nuevas columnas son sale_usd, promotion_usd, credit_usd, tax_usd, y line_cost_usd


create view stg.vw_order_line_sale_usd as

with ventas_usd as (   -- utilizo un cte para crear la tabla ventas_usd y luego calcular el margen de ventas
select
	ols.*,
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
	product_cost_usd as line_cost_USD
from stg.order_line_sale ols
left join stg.monthly_average_fx_rate fx
on date_trunc('month',ols.date) = fx.month
left join stg.cost c
on ols.product = c.product_code
)
select
	ventas_usd.*,
	sale_USD - promotion_USD - line_cost_USD as margin_USD
from ventas_usd


-- 4. Generar una query que me sirva para verificar que el nivel de agregacion de la tabla de ventas (y de la vista) no se haya afectado. Recordas que es el nivel de agregacion/detalle? Lo vimos en la teoria de la parte 1! Nota: La orden M202307319089 parece tener un problema verdad? Lo vamos a solucionar mas adelante.
-- PRIMERA FORMA ( con una particion)

with stg_sales as (
select 
	order_number,
	product, 
	row_number() over(partition by order_number, product, store, date order by date asc, store asc, product asc) as rn
from stg.order_line_sale
)
select 
* 
from stg_sales
where rn > 1

-- SEGUNDA FORMA 

select 
	order_number,
	product,
	store,
	date,
	count(1)
from  stg.vw_order_line_sale_usd
group by order_number, product, store, date
having count(1) > 1

-- 5. Calcular el margen bruto a nivel Subcategoria de producto. Usar la vista creada stg.vw_order_line_sale_usd. La columna de margen se llama margin_usd

-- Primero tengo que modificar la vista para agregar los datos de product_master

drop view if exists stg.vw_order_line_sale_usd ;
create or replace view stg.vw_order_line_sale_usd as

with ventas_usd as (   -- utilizo un cte para crear la tabla ventas_usd y luego calcular el margen de ventas
select
	ols.*,
	pm.*,
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
	product_cost_usd as line_cost_USD
from stg.order_line_sale ols
left join stg.monthly_average_fx_rate fx
on date_trunc('month',ols.date) = fx.month
left join stg.cost c
on ols.product = c.product_code
left join stg.product_master pm
on ols.product = pm.product_code
)
select
	ventas_usd.*,
	sale_USD - promotion_USD - line_cost_USD as margin_USD
from ventas_usd
;

-- Ahora calulo el margen con la vista


select
	vw_order_line_sale_usd.*,
	avg(sale_USD - promotion_USD - line_cost_USD) over (partition by subcategory) as margin_USD_by_subcategory
from stg.vw_order_line_sale_usd

-- 6. Calcular la contribucion de las ventas brutas de cada producto al total de la orden.


with cte_ordenes as (
select 
	order_number,
	sum(sale_usd) as total_sale_usd
from stg.vw_order_line_sale_usd
group by order_number
order by order_number
)
select
	ols.*,
	o.total_sale_usd,
	(ols.sale_USD) / (o.total_sale_usd) as contribution_USD_by_order_line
from stg.vw_order_line_sale_usd ols
left join cte_ordenes o
on ols.order_number = o.order_number

-- 7. Calcular las ventas por proveedor, para eso cargar la tabla de proveedores por producto. Agregar el nombre el proveedor en la vista del punto stg.vw_order_line_sale_usd. El nombre de la nueva tabla es stg.suppliers

drop view if exists stg.vw_order_line_sale_usd ;

create or replace view stg.vw_order_line_sale_usd as

with ventas_usd as (   -- utilizo un cte para crear la tabla ventas_usd
select
	ols.*,
	pm.*,
	sup.name supplier_name,
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
	product_cost_usd as line_cost_USD
from stg.order_line_sale ols
left join stg.monthly_average_fx_rate fx
on date_trunc('month',ols.date) = fx.month
left join stg.cost c
on ols.product = c.product_code
left join stg.product_master pm
on ols.product = pm.product_code
left join stg.suppliers sup
on  ols.product = sup.product_id  
where sup.is_primary = True
)
select
	ventas_usd.*,
	sale_USD - promotion_USD - line_cost_USD as margin_USD
from ventas_usd
;

-- Ahora puedo obtener las ventas por proveedor. Ya que no lo especifica, calculo ventas brutas
select 
	supplier_name,
	sum(sale_USD)
from stg.vw_order_line_sale_usd
group by supplier_name
order by supplier_name

-- 8. Verificar que el nivel de detalle de la vista stg.vw_order_line_sale_usd no se haya modificado, en caso contrario que se deberia ajustar? Que decision tomarias para que no se genereren duplicados?
    -- - Se pide correr la query de validacion.
    -- - Modificar la query de creacion de stg.vw_order_line_sale_usd  para que no genere duplicacion de las filas. 
    -- - Explicar brevemente (con palabras escrito tipo comentario) que es lo que sucedia.

-- Al correr la query de verificacion:
select 
	order_number,
	product,
	store,
	date,
	count(1)
from  stg.vw_order_line_sale_usd
group by order_number, product, store, date
having count(1) > 1
-- Se verifica que NO hay valores duplicados. El unico duplicado es la orden M202307319089 que ya estaba duplicada en la tabla original. 
-- Esto se evito agregando la sentencia " where sup.is_primary = True ". De esta manera no se tienen en cuenta los proveedores secundarios.
-- Vale destacar que puede haber mas de un proveedor por producto, por eso se incrementan al hacer join si no se tiene este cuidado.

-- ## Semana 3 - Parte B

-- 1. Calcular el porcentaje de valores null de la tabla stg.order_line_sale para la columna creditos y descuentos. (porcentaje de nulls en cada columna)

with cuenta_nulos as (
select 
	sum(case when credit is null then 1 else 0 end) credit_null,	
	sum(case when credit is null then 1 else 1 end) credit_total,	
	sum(case when promotion is null then 1 else 0 end) promotion_null,
	sum(case when promotion is null then 1 else 1 end) promotion_total
from stg.order_line_sale
)
select 
	(credit_null*1.00 / credit_total*1.00) * 100  as credit__null ,
	(promotion_null*1.00 / promotion_total*1.00) * 100 as promotion__null
from cuenta_nulos

-- 2. La columna is_walkout se refiere a los clientes que llegaron a la tienda y se fueron con el producto en la mano (es decia habia stock disponible). Responder en una misma query:
   --  - Cuantas ordenes fueron walkout por tienda?
   --  - Cuantas ventas brutas en USD fueron walkout por tienda?
   --  - Cual es el porcentaje de las ventas brutas walkout sobre el total de ventas brutas por tienda?


with cte_sales as (
select 
    olsusd.*,
	row_number() over(partition by order_number) as rn
from stg.vw_order_line_sale_usd olsusd
) 
select 
    store,
    sum(case when is_walkout = true then 1 else 0 end) as walkouttrue,
    sum(case when is_walkout = false then 1 else 0 end) as walkoutfalse
from cte_sales s
where rn = 1
group by store
order by store


-- 3. Siguiendo el nivel de detalle de la tabla ventas, hay una orden que no parece cumplirlo. Como identificarias duplicados utilizando una windows function? 
-- Tenes que generar una forma de excluir los casos duplicados, para este caso particular y a nivel general, si llegan mas ordenes con duplicaciones.
-- Identificar los duplicados.
-- Eliminar las filas duplicadas. Podes usar BEGIN transaction y luego rollback o commit para verificar que se haya hecho correctamente.

with stg_sales as (
select 
	order_number,
	product, 
	row_number() over(partition by order_number, product, store, date order by date asc, store asc, product asc) as rn
from stg.vw_order_line_sale_usd
)
select 
* 
from stg_sales
where rn <= 1


-- 4. Obtener las ventas totales en USD de productos que NO sean de la categoria TV NI esten en tiendas de Argentina. Modificar la vista stg.vw_order_line_sale_usd con todas las columnas necesarias. 


drop view if exists stg.vw_order_line_sale_usd ;

create or replace view stg.vw_order_line_sale_usd as

with ventas_usd as (   -- utilizo un cte para crear la tabla ventas_usd
select
	ols.*,
	pm.*,
	sm.country as store_country,
	sup.name supplier_name,
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
	product_cost_usd as line_cost_USD
from stg.order_line_sale ols
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
where sup.is_primary = True
)
select
	*
from ventas_usd
-- end of view
;

-- Ahora si puedo filtrar lo pedido con la vista modificada:
select
	product,
	sum(sale_usd) sale_USD
from stg.vw_order_line_sale_usd
where ((lower(subcategory)) <> 'tv') and ((lower(store_country) <> 'argentina'))
group by product
order by product
;

-- 5. El gerente de ventas quiere ver el total de unidades vendidas por dia junto con otra columna con la cantidad de unidades vendidas una semana atras y la diferencia entre ambos.Diferencia entre las ventas mas recientes y las mas antiguas para tratar de entender un crecimiento.

with sales as (
select
	date,
	sum(quantity) qty_today
from stg.vw_order_line_sale_usd olsthisweek
group by date
order by date
),
sales_total as (
select
	s1.*,
	s2.date as date_prev_week,
	s2.qty_today as qty_prev_week
from sales s1
inner join sales s2
on s1.date = (s2.date + interval '7 days')
)

select 
	*,
	(qty_today - qty_prev_week) as diff
from sales_total


-- 6. Crear una vista de inventario con la cantidad de inventario promedio por dia, tienda y producto, que ademas va a contar con los siguientes datos:
/* - Nombre y categorias de producto: `product_name`, `category`, `subcategory`, `subsubcategory`
- Pais y nombre de tienda: `country`, `store_name`
- Costo del inventario por linea (recordar que si la linea dice 4 unidades debe reflejar el costo total de esas 4 unidades): `inventory_cost`
- Inventario promedio: `avg_inventory`
- Una columna llamada `is_last_snapshot` para el inventario de la fecha de la ultima fecha disponible. Esta columna es un campo booleano.
- Ademas vamos a querer calcular una metrica llamada "Average days on hand (DOH)" `days_on_hand` que mide cuantos dias de venta nos alcanza el inventario. Para eso DOH = Unidades en Inventario Promedio / Promedio diario Unidades vendidas ultimos 7 dias.
- El nombre de la vista es `stg.vw_inventory`
- Notas:
    - Antes de crear la columna DOH, conviene crear una columna que refleje el Promedio diario Unidades vendidas ultimos 7 dias. `avg_sales_last_7_days`
    - El nivel de agregacion es dia/tienda/sku.
    - El Promedio diario Unidades vendidas ultimos 7 dias tiene que calcularse para cada dia.
*/

-- View: stg.vw_inventory

-- DROP VIEW stg.vw_inventory;

-- View: stg.vw_inventory

DROP VIEW stg.vw_inventory;

CREATE OR REPLACE VIEW stg.vw_inventory
 AS
 WITH cte_inv AS (   -- armo la tabla madre de inventario
         SELECT inv.date,
            inv.store_id,
            inv.item_id,
            inv.initial,
            inv.final,
            pm.name AS product_name,
            pm.category,
            pm.subcategory,
            pm.subsubcategory,
            sm.country,
            sm.name AS store_name,
            c.product_cost_usd
           FROM stg.inventory inv
             LEFT JOIN stg.product_master pm ON inv.item_id::text = pm.product_code::text
             LEFT JOIN stg.store_master sm ON inv.store_id = sm.store_id
             LEFT JOIN stg.cost c ON inv.item_id::text = c.product_code::text
        ), cte_last_snapshot AS (  -- armo la tabla de last snapshot
         SELECT inv.item_id,
            inv.store_id,
            max(inv.date) AS last_snapshot
           FROM cte_inv inv
          GROUP BY inv.item_id, inv.store_id
          ORDER BY inv.item_id, inv.store_id
        ), cte_final_inventory AS ( -- con un join agrego la tabla last snapshot a la de inventario
         SELECT inv.date,
            inv.store_id,
            inv.item_id,
            inv.initial,
            inv.final,
            inv.product_name,
            inv.category,
            inv.subcategory,
            inv.subsubcategory,
            inv.country,
            inv.store_name,
            inv.product_cost_usd,
                CASE
                    WHEN inv.date = ls.last_snapshot THEN true
                    ELSE false
                END AS is_last_snapshot
           FROM cte_inv inv
             LEFT JOIN cte_last_snapshot ls ON inv.item_id::text = ls.item_id::text AND inv.store_id = ls.store_id
        ), cte_avg_sales AS (
		select 
			date,
			store,
			product,
			sum(quantity) quantity
		from stg.vw_order_line_sale_usd
		group by date, store, product
		order by date, store, product
), cte_inv_DOH as ( 

	select 		-- ahora uno todo en uan tabla y calculo el DOH
		i.*,
		s.quantity,
		(i.initial + i.final) / 2 AS avg_inventory,
		avg(s.quantity) over(partition by i.date, i.store_id, i.item_id order by i.date asc rows between 7 preceding and current row) as avg_sales_last_7_days
	from cte_final_inventory i
	left join cte_avg_sales s 
	on s.date = i.date
	and s.store = i.store_id
	and s.product = i.item_id
	)
select
	i.*,
	i.avg_inventory / i.avg_sales_last_7_days as DOH
from cte_inv_DOH i
-- end of view


-- ## Semana 4 - Parte A

-- 1. Calcular la contribucion de las ventas brutas de cada producto al total de la orden utilizando una window function. Mismo objetivo que el ejercicio de la parte A pero con diferente metodologia.

select
	vw_order_line_sale_usd.*,
	((sale_USD) / (sum(sale_USD) over (partition by order_number))) as contribution_USD_by_order_line
from stg.vw_order_line_sale_usd

-- 2. La regla de pareto nos dice que aproximadamente un 20% de los productos generan un 80% de las ventas. Armar una vista a nivel sku donde se pueda identificar por orden de contribucion, ese 20% aproximado de SKU mas importantes. Nota: En este ejercicios estamos construyendo una tabla que muestra la regla de Pareto. 
-- El nombre de la vista es `stg.vw_pareto`. Las columnas son, `product_code`, `product_name`, `quantity_sold`, `cumulative_contribution_percentage`

with cte as(
select 
	product,
	sum(quantity) as qty_sold
from stg.order_line_sale ols
group by product
order by product desc)
, cte2 as (
select 
	product,
	qty_sold,
	sum(qty_sold) over() as total_qty,
	sum(qty_sold) over(order by qty_sold) as total_qty_running_sum
from cte)

select 
	*,
	(total_qty_running_sum)*1.00/(total_qty)*1.00 as accum_contribution
from cte2


-- 3. Calcular el crecimiento de ventas por tienda mes a mes, con el valor nominal y el valor % de crecimiento.
with cte_sales as(
select 
	store,
	cast(date_trunc('month', ols.date) as date) mes,
	sum(sale_usd) gross_sales_usd
from stg.vw_order_line_sale_usd ols
group by store, mes
order by store, mes
), 
cte_sales2 as (
select 
	s.*, 
	s2.mes as prev_month,
	s2.gross_sales_usd as gross_sales_usd_prev_month
from cte_sales s
inner join cte_sales s2
on (s.store = s2.store) and (s.mes = s2.mes + interval '1 month')
)
-- select * from cte_sales2

select 
	s.*,
	(gross_sales_usd  - gross_sales_usd_prev_month) as absolute_growth, 
	(((gross_sales_usd  - gross_sales_usd_prev_month)*1.00/(gross_sales_usd*1.00)))*100 as relative_growth 
from cte_sales2 s


-- 4. Crear una vista a partir de la tabla return_movements que este a nivel Orden de venta, item y que contenga las siguientes columnas:
/* - Orden `order_number`
- Sku `item`
- Cantidad unidated retornadas `quantity`
- Fecha: `date` Se considera la fecha de retorno aquella el cual el cliente la ingresa a nuestro deposito/tienda.
- Valor USD retornado (resulta de la cantidad retornada * valor USD del precio unitario bruto con que se hizo la venta) `sale_returned_usd`
- Features de producto `product_name`, `category`, `subcategory`
- `first_location` (primer lugar registrado, de la columna `from_location`, para la orden/producto)
- `last_location` (el ultimo lugar donde se registro, de la columna `to_location` el producto/orden)
- El nombre de la vista es `stg.vw_returns`*/


drop view if exists stg.vw_returns;

create or replace view stg.vw_returns as

with cte_ret as (
select 
	r.*,
	first_value (r.date) over (partition by return_id order by movement_id desc) as date_ret,
	first_value (from_location) over (partition by return_id order by movement_id asc) as first_location,
	last_value (to_location) over (partition by return_id order by movement_id asc rows between unbounded preceding and unbounded following) as last_location
from stg.return_movements r
order by return_id, movement_id 
)
select 
	r.order_id,
	r.item,
	r.date_ret,
	r.first_location,
	r.last_location,
	pm.name,
	pm.category,
	pm.subcategory,
	pm.subsubcategory,
	avg(r.quantity) as quantity_returned,
	avg(s.line_cost_usd * r.quantity) as sale_returned_usd
from cte_ret r
left join stg.product_master pm
on r.item = pm.product_code
left join stg.vw_order_line_sale_usd s
on ( s.order_number = r.order_id ) and ( s.product = r.item )
group by 1,2,3,4,5,6,7,8,9
order by order_id, item
-- end of view


-- 5. Crear una tabla calendario llamada stg.date con las fechas del 2022 incluyendo el año fiscal y trimestre fiscal (en ingles Quarter). El año fiscal de la empresa comienza el primero Febrero de cada año y dura 12 meses. Realizar la tabla para 2022 y 2023. La tabla debe contener:
/* - Fecha (date) `date`
- Mes (date) `month`
- Año (date) `year`
- Dia de la semana (text, ejemplo: "Monday") `weekday`
- `is_weekend` (boolean, indicando si es Sabado o Domingo)
- Mes (text, ejemplo: June) `month_label`
- Año fiscal (date) `fiscal_year`
- Año fiscal (text, ejemplo: "FY2022") `fiscal_year_label`
- Trimestre fiscal (text, ejemplo: Q1) `fiscal_quarter_label`
- Fecha del año anterior (date, ejemplo: 2021-01-01 para la fecha 2022-01-01) `date_ly`
- Nota: En general una tabla date es creada para muchos años mas (minimo 10), en este caso vamos a realizarla para el 2022 y 2023 nada mas.. 
*/

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
			Else
				False
			End as is_weekend,
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
		CAST( date - interval '1 year' AS date)::date AS date_ly,
			
from 	
	(select 	
	 	cast ('2022-01-01' as date) + (n || 'day') :: interval as date
	from generate_series(0,729) n ) dd;  -- 365dias/anio * 2anios - 1 = 729dias (le resto 1 porque arranca de 0)



-- ## Semana 4 - Parte B

-- 1. Calcular el crecimiento de ventas por tienda mes a mes, con el valor nominal y el valor % de crecimiento. Utilizar self join.

with cte_sales as(
select 
	store,
	cast(date_trunc('month', ols.date) as date) mes,
	sum(sale_usd) gross_sales_usd
from stg.vw_order_line_sale_usd ols
group by store, mes
order by store, mes
), 
cte_sales2 as (
select 
	s.*, 
	s2.mes as prev_month,
	s2.gross_sales_usd as gross_sales_usd_prev_month
from cte_sales s
inner join cte_sales s2
on (s.store = s2.store) and (s.mes = s2.mes + interval '1 month')
)
-- select * from cte_sales2

select 
	s.*,
	(gross_sales_usd  - gross_sales_usd_prev_month) as absolute_growth, 
	(((gross_sales_usd  - gross_sales_usd_prev_month)*1.00/(gross_sales_usd*1.00)))*100 as relative_growth 
from cte_sales2 s

-- 2. Hacer un update a la tabla de stg.product_master agregando una columna llamada brand, con la marca de cada producto con la primer letra en mayuscula. Sabemos que las marcas que tenemos son: Levi's, Tommy Hilfiger, Samsung, Phillips, Acer, JBL y Motorola. En caso de no encontrarse en la lista usar Unknown.

alter table stg.product_master
add brand varchar(255)

update stg.product_master
set brand = 
	case		
		when lower(name) like '%levi''s%' then 'Levi''s'
		when lower(name) like '%tommy hilfiger%' then 'Tommy Hilfiger'
  		when lower(name) like '%samsung%' then 'Samsung'
  		when lower(name) like '%philips%' then 'Phillips'
  		when lower(name) like '%acer%' then 'Acer'
  		when lower(name) like '%jbl%' then 'JBL'
  		when lower(name) like '%motorola%' then 'Motorola'
  	else 'Unknown'
	end

-- 3. Un jefe de area tiene una tabla que contiene datos sobre las principales empresas de distintas industrias en rubros que pueden ser competencia y nos manda por mail la siguiente informacion: (ver informacion en md file)




