DROP TABLE IF EXISTS dim.date;

CREATE TABLE IF NOT EXISTS dim.date
(
    date_id integer,
    date date PRIMARY KEY,
    month smallint,
    year smallint,
    day smallint,
    weekday text COLLATE pg_catalog."default",
    weekday_number text COLLATE pg_catalog."default",
    month_label text COLLATE pg_catalog."default",
    is_weekend boolean,
    fiscal_year date,
    fiscal_year_label text COLLATE pg_catalog."default",
    fiscal_quarter_label text COLLATE pg_catalog."default",
    date_ly date
	
);



