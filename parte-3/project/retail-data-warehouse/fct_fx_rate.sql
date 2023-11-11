DROP TABLE IF EXISTS fct.fx_rate;

CREATE TABLE IF NOT EXISTS fct.fx_rate
(
	month date,
    fx_rate_usd_peso numeric,
    fx_rate_usd_eur numeric,
    fx_rate_usd_uru numeric,
		
	-- declaro las foreign keys y las relaciono con las dim
	constraint fk_date
		foreign key (month)
		references dim.date(date)
);
