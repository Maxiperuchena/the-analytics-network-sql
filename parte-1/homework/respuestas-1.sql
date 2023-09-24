-- ## Semana 1 - Parte A
-- Alumno = Maximiliano Peruchena

-- 1. Mostrar todos los productos dentro de la categoria electro junto con todos los detalles.

select 	* 
from stg.product_master 
where category = 'Electro'

-- 2. Cuales son los producto producidos en China?

select 	* 
from stg.product_master 
where origin = 'China'

-- 3. Mostrar todos los productos de Electro ordenados por nombre.

select 	* 
from stg.product_master 
where category = 'Electro' 
order by name asc

-- 4. Cuales son las TV que se encuentran activas para la venta?

select 	* 
from stg.product_master
where subcategory = 'TV' and is_active = TRUE 

-- 5. Mostrar todas las tiendas de Argentina ordenadas por fecha de apertura de las mas antigua a la mas nueva.

select 	* 
from stg.store_master
where country = 'Argentina'
order by start_date asc

-- 6. Cuales fueron las ultimas 5 ordenes de ventas?

select 
	order_number,
	date
from stg.order_line_sale
order by date desc
limit 5

-- 7. Mostrar los primeros 10 registros del conteo de trafico por Super store ordenados por fecha.

select 
	*
from stg.super_store_count
order by date desc
limit 10

-- 8. Cuales son los producto de electro que no son Soporte de TV ni control remoto.

select 	* 
from stg.product_master 
where category = 'Electro' and subsubcategory <> 'Soporte' and subsubcategory <> 'Control remoto'

-- 9. Mostrar todas las lineas de venta donde el monto sea mayor a $100.000 solo para transacciones en pesos.

select 
	*
from stg.order_line_sale
where sale > 100000 and currency = 'ARS'

-- 10. Mostrar todas las lineas de ventas de Octubre 2022.

select 
	*
from stg.order_line_sale
where date >= '2022-10-01' AND date <= '2022-10-31'
order by date asc

-- 11. Mostrar todos los productos que tengan EAN.

select 	* 
from stg.product_master
where ean is not null

-- 12. Mostrar todas las lineas de venta que que hayan sido vendidas entre 1 de Octubre de 2022 y 10 de Noviembre de 2022.

select 
	order_number,
	date
from stg.order_line_sale
where date >= '2022-10-01' AND date <= '2022-11-10'
order by date asc

-- otra forma:
select 
	order_number,
	date
from stg.order_line_sale
where date between '2022-10-01' AND '2022-11-10'
order by date asc

-- ## Semana 1 - Parte B

-- 1. Cuales son los paises donde la empresa tiene tiendas?

select 
distinct(country)
from stg.store_master

-- 2. Cuantos productos por subcategoria tiene disponible para la venta?

select distinct 
	 subcategory,
	 count (product_code)
from stg.product_master
where is_active = 'true'
group by subcategory


-- 3. Cuales son las ordenes de venta de Argentina de mayor a $100.000?

select 
	*
from stg.order_line_sale s
left join stg.store_master sm 
on s.store = sm.store_id
where sale > 100000 and country = 'Argentina'


-- 4. Obtener los decuentos otorgados durante Noviembre de 2022 en cada una de las monedas?

select 
	currency,
	sum(promotion) descuentos
from stg.order_line_sale
where date >= '2022-11-01' AND date <= '2022-11-30'
group by currency

-- 5. Obtener los impuestos pagados en Europa durante el 2022.

select 
	sum(tax)
from stg.order_line_sale s
left join stg.store_master sm
on s.store = sm.store_id
where date >= '2022-01-01' AND date <= '2022-12-31' and country = 'Spain'

-- 6. En cuantas ordenes se utilizaron creditos?

select distinct count(order_number)
from stg.order_line_sale
where credit is not null

-- 7. Cual es el % de descuentos otorgados (sobre las ventas) por tienda?

select store, avg((promotion / sale)*100)
from stg.order_line_sale
group by store 

-- 8. Cual es el inventario promedio por dia que tiene cada tienda? 

select store_id, date,item_id, ((final + initial)/2) as inv_promedio
from stg.inventory

-- 9. Obtener las ventas netas y el porcentaje de descuento otorgado por producto en Argentina.

select 
	product,
	sum((sale - promotion - tax - credit)) as ventas_netas,
	avg((promotion / sale)*100) as porc_descuento
from stg.order_line_sale ols
left join stg.store_master sm
on ols.store = sm.store_id
where country = 'Argentina'
group by product


-- 10. Las tablas "market_count" y "super_store_count" representan dos sistemas distintos que usa la empresa para contar la cantidad de gente que ingresa a tienda, uno para las tiendas de Latinoamerica y otro para Europa. Obtener en una unica tabla, las entradas a tienda de ambos sistemas.
/VERIFICAR/
select 
	store_id,
	TO_DATE((date)::text, 'YYYYMMDD') as fecha,
	traffic
from stg.market_count
union
select 
	store_id,
	TO_DATE((date)::text, 'YYYY-MM-DD') as fecha,
	traffic
from stg.super_store_count ssc
order by fecha, store_id

-- 11. Cuales son los productos disponibles para la venta (activos) de la marca Phillips?

select 
	*
from stg.product_master
where is_active = 'true'
and name like '%PHILIPS%'


-- 12. Obtener el monto vendido por tienda y moneda y ordenarlo de mayor a menor por valor nominal de las ventas (sin importar la moneda).

select 
	store,
	sum(sale),
	currency
from stg.order_line_sale
group by store, currency
order by sum(sale) desc

-- 13. Cual es el precio promedio de venta de cada producto en las distintas monedas? Recorda que los valores de venta, impuesto, descuentos y creditos es por el total de la linea.

select 
	product,
	currency,
	avg( ( sale + coalesce( promotion , 0 ) - coalesce( tax , 0 ) + coalesce( credit, 0 ) ) / quantity ) as precio_prom_vta
from stg.order_line_sale
group by product, currency
order by product asc , currency asc


-- 14. Cual es la tasa de impuestos que se pago por cada orden de venta?


select 
	order_number,
	((sum( coalesce( tax , 0 ) ) / sum ( sale )) * 100) as tasa_impuesto
from stg.order_line_sale
group by order_number

-- ## Semana 2 - Parte A

-- 1. Mostrar nombre y codigo de producto, categoria y color para todos los productos de la marca Philips y Samsung, mostrando la leyenda "Unknown" cuando no hay un color disponible


select 
	name,
	product_code,
	category,
	coalesce(color, 'Unknown') 
from stg.product_master
where upper(name) like '%PHILIPS%' or upper(name) like '%SAMSUNG%'  

-- 2. Calcular las ventas brutas y los impuestos pagados por pais y provincia en la moneda correspondiente.

select 
	country,
	province,
	sum(sale) as Ventas_Brutas,
	sum(tax) as Impuestos,
	currency
from stg.order_line_sale ols
left join stg.product_master pm
on ols.product = pm.product_code
left join stg.store_master sm
on ols.store = sm.store_id
group by country , province, currency
order by country desc, province desc, currency desc


-- 3. Calcular las ventas totales por subcategoria de producto para cada moneda ordenados por subcategoria y moneda.

select 
	subcategory,
	sum(sale) as Ventas,
	currency
from stg.order_line_sale ols
left join stg.product_master pm
on ols.product = pm.product_code
left join stg.store_master sm
on ols.store = sm.store_id
group by subcategory , currency
order by subcategory desc, currency desc

  
-- 4. Calcular las unidades vendidas por subcategoria de producto y la concatenacion de pais, provincia; usar guion como separador y usarla para ordernar el resultado.

select 
	CONCAT(country, ' - ', province) as codigo_regional,	
	subcategory,
	sum(quantity) as Unidades_vendidas
from stg.order_line_sale ols
left join stg.product_master pm
on ols.product = pm.product_code
left join stg.store_master sm
on ols.store = sm.store_id
group by codigo_regional, subcategory
order by codigo_regional desc, subcategory desc

-- 5. Mostrar una vista donde sea vea el nombre de tienda y la cantidad de entradas de personas que hubo desde la fecha de apertura para el sistema "super_store".

create or replace view stg.vw_trafico as
select 
	name,
	sum(traffic)
from stg.store_master sm 
inner join stg.super_store_count ssc
on (sm.store_id = ssc.store_id) and (sm.start_date <= cast(ssc.date as date))
group by name
order by name


-- 6. Cual es el nivel de inventario promedio en cada mes a nivel de codigo de producto y tienda; mostrar el resultado con el nombre de la tienda.

select 
	name,
	item_id,
	to_char(date, 'MM') Mes,
	avg((initial + final)/2)
from stg.inventory i
left join stg.store_master sm
on i.store_id = sm.store_id
group by name, item_id, Mes
order by name,item_id,  Mes
  
-- 7. Calcular la cantidad de unidades vendidas por material. Para los productos que no tengan material usar 'Unknown', homogeneizar los textos si es necesario.
PREGUNTAR
select
	trim(upper(coalesce(pm.material,'Unknown'))) as Material,
  	sum(quantity)
from stg.order_line_sale ols
left join stg.product_master pm
on ols.product = pm.product_code
group by Material

-- 8. Mostrar la tabla order_line_sales agregando una columna que represente el valor de venta bruta en cada linea convertido a dolares usando la tabla de tipo de cambio.

select
	ols.*,
	case
		when currency = 'ARS' then (sale * fx_rate_usd_peso)
		when currency = 'EUR' then (sale * fx_rate_usd_eur) 
		else sale 
	end VentaUSD
from stg.order_line_sale ols
left join stg.monthly_average_fx_rate fx
on date_trunc('month',ols.date) = fx.month

-- 9. Calcular cantidad de ventas totales de la empresa en dolares.

select
	ols.*,
	case
		when currency = 'ARS' then (sale * fx_rate_usd_peso)
		when currency = 'EUR' then (sale * fx_rate_usd_eur) 
		else sale 
	end VentaUSD
from stg.order_line_sale ols
left join stg.monthly_average_fx_rate fx
on date_trunc('month',ols.date) = fx.month

  
-- 10. Mostrar en la tabla de ventas el margen de venta por cada linea. Siendo margen = (venta - descuento) - costo expresado en dolares.

with ventas_usd as (   -- utilizo un cte para crear la tabla ventas_usd y luego calcular el margen de ventas
select
	ols.*,
	case
		when currency = 'ARS' then (coalesce(sale,0) * fx_rate_usd_peso)
		when currency = 'EUR' then (coalesce(sale,0) * fx_rate_usd_eur) 
		else sale 
	end VentaUSD,
	case
		when currency = 'ARS' then (coalesce(promotion,0) * fx_rate_usd_peso)
		when currency = 'EUR' then (coalesce(promotion,0) * fx_rate_usd_eur) 
		else promotion 
	end DescuentoUSD,
	product_cost_usd
from stg.order_line_sale ols
left join stg.monthly_average_fx_rate fx
on date_trunc('month',ols.date) = fx.month
left join stg.cost c
on ols.product = c.product_code
)
select
	ventas_usd.*,
	ventaUSD - DescuentoUSD - product_cost_usd as MargenVentaUSD
from ventas_usd

-- 11. Calcular la cantidad de items distintos de cada subsubcategoria que se llevan por numero de orden.
--CONSULTAR. VALORES REPETIDOS! en order "M202307319089" hay 2 productos "p200089"

select 
	order_number,
	sum(case when subcategory = 'Accesorios' then 1 else 0 end) as qty_Accesorios,
	sum(case when subcategory = 'Computadoras' then 1 else 0 end) as qty_Computadoras,
	sum(case when subcategory = 'Audio' then 1 else 0 end) as qty_Audio,
	sum(case when subcategory = 'Gaming' then 1 else 0 end) as qty_Gaming,
	sum(case when subcategory = 'Hombre' then 1 else 0 end) as qty_Hombre,
	sum(case when subcategory = 'Informatica' then 1 else 0 end) as qty_Informatica,
	sum(case when subcategory = 'TV' then 1 else 0 end) as qty_TV
from stg.order_line_sale ols
left join stg.product_master pm
on ols.product = pm.product_code
group by order_number
order by order_number

-- ## Semana 2 - Parte B

-- 1. Crear un backup de la tabla product_master. Utilizar un esquema llamada "bkp" y agregar un prefijo al nombre de la tabla con la fecha del backup en forma de numero entero.

create schema bkp
;
select 
	*
into bkp.product_master_09_23_2023
from stg.product_master
  
-- 2. Hacer un update a la nueva tabla (creada en el punto anterior) de product_master agregando la leyendo "N/A" para los valores null de material y color. Pueden utilizarse dos sentencias.

update bkp.product_master_09_23_2023 
set color = 'N/A' 
where color is null 
update bkp.product_master_09_23_2023 
set material = 'N/A' 
where material is null 
  
-- 3. Hacer un update a la tabla del punto anterior, actualizando la columa "is_active", desactivando todos los productos en la subsubcategoria "Control Remoto".

update bkp.product_master_09_23_2023 
set is_active = false 
where subsubcategory = 'Control remoto'

-- 4. Agregar una nueva columna a la tabla anterior llamada "is_local" indicando los productos producidos en Argentina y fuera de Argentina.

alter table bkp.product_master_09_23_2023 
add is_local boolean
;
update bkp.product_master_09_23_2023 
set is_local = true
where upper(origin) = 'ARGENTINA';
update bkp.product_master_09_23_2023 
set is_local = false
where upper(origin) <> 'ARGENTINA';

  
-- 5. Agregar una nueva columna a la tabla de ventas llamada "line_key" que resulte ser la concatenacion de el numero de orden y el codigo de producto.

drop table if exists bkp.order_line_sale_09_23_2023 ;

select 
	*
into bkp.order_line_sale_09_23_2023
from stg.order_line_sale 
;
alter table bkp.order_line_sale_09_23_2023
add line_key character varying(265)  -- 255 + 10
;
update bkp.order_line_sale_09_23_2023
set line_key = concat( order_number, '-', product);

-- 6. Crear una tabla llamada "employees" (por el momento vacia) que tenga un id (creado de forma incremental), name, surname, start_date, end_name, phone, country, province, store_id, position. Decidir cual es el tipo de dato mas acorde.

drop table if exists stg.employees;
CREATE TABLE IF NOT EXISTS stg.employees
(
    	employee_id serial primary key,
	name varchar (255),
	surname varchar (255),
	start_date date,
	end_date date,
    	phone character varying(20),
	country varchar (255),
	province varchar (255),
    	store_id smallint,
    	position varchar (255)
);

-- 7. Insertar nuevos valores a la tabla "employees" para los siguientes 4 empleados:
    -- Juan Perez, 2022-01-01, telefono +541113869867, Argentina, Santa Fe, tienda 2, Vendedor.
    -- Catalina Garcia, 2022-03-01, Argentina, Buenos Aires, tienda 2, Representante Comercial
    -- Ana Valdez, desde 2020-02-21 hasta 2022-03-01, España, Madrid, tienda 8, Jefe Logistica
    -- Fernando Moralez, 2022-04-04, España, Valencia, tienda 9, Vendedor.

insert into stg.employees values (default,'Juan','Perez', '2022-01-01',null,'+541113869867', 'Argentina', 'Santa Fe', 2, 'Vendedor')
insert into stg.employees values (default,'Catalina','Garcia', '2022-03-01',null, null, 'Argentina', 'Buenos Aires', 2, 'Representante Comercial')
insert into stg.employees values (default,'Ana','Valdez', '2020-02-21','2022-03-01', null, 'España', 'Madrid', 8, 'Jefe Logistica')
insert into stg.employees values (default,'Fernando','Moralez', '2022-04-04',null, null, 'España', 'Valencia', 9, 'Vendedor')

-- 8. Crear un backup de la tabla "cost" agregandole una columna que se llame "last_updated_ts" que sea el momento exacto en el cual estemos realizando el backup en formato datetime.

select 
	*
into bkp.cost_09_23_2023
from stg.cost
;
alter table bkp.cost_09_23_2023
add last_updated_ts timestamp default current_timestamp

-- 9. En caso de hacer un cambio que deba revertirse en la tabla "order_line_sale" y debemos volver la tabla a su estado original, como lo harias?

-- utilizaria el backup para volver la tabal a su estado original:
drop table if exists stg.order_line_sale ;

select 
	*
into stg.order_line_sale
from bkp.order_line_sale_09_23_2023 ;
