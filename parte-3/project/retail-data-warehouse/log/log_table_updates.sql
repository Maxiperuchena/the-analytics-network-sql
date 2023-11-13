-- Creo tabla de Logs

CREATE TABLE log.table_updates (
	table_name VARCHAR(10),
	date date,
	stored_procedure VARCHAR(255),
    username VARCHAR(255)
					 )
-- pruebo la tabla:			
-- select * from log.table_updates
