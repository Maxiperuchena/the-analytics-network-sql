DROP TABLE IF EXISTS dim.product_master;

CREATE TABLE IF NOT EXISTS dim.product_master
(
      product_id    VARCHAR(10) PRIMARY KEY
                            , name            VARCHAR(255)
                            , category        VARCHAR(50)
                            , subcategory     VARCHAR(50)
                            , subsubcategory  VARCHAR(50)
                            , material        VARCHAR(20)
                            , color           VARCHAR(20)
                            , origin          VARCHAR(50)
                            , ean             bigint
                            , is_active       boolean
                            , has_bluetooth   boolean
                            , size            VARCHAR(20)
);
