create or replace procedure etl.log(parametro_tabla varchar(255), parametro_fecha date, parametro_sp varchar(255), parametro_usuario varchar(255))
language sql as $$

insert into log.table_updates (tabla, fecha, sp, usuario) 
select parametro_tabla, parametro_fecha, parametro_sp, parametro_usuario ; 

$$;

/* Prueba
call etl.log('dim.cost','2023-10-31','sp.etl_cost','MPERUCH')
select * from etl.log
*/
