DROP TABLE IF EXISTS dim.store_master;

CREATE TABLE IF NOT EXISTS dim.store_master
(
              store_id  SMALLINT PRIMARY KEY
                            , country      VARCHAR(50)
                            , province     VARCHAR(50)
                            , city         VARCHAR(50)
                            , address      VARCHAR(255)
                            , store_name   VARCHAR(255)
                            , type         VARCHAR(50)
                            , start_date   DATE
                            , latitude     DECIMAL(10, 8)
                            , longitude    DECIMAL(11, 8)
	
);
