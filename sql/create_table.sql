-- Creates the raw table and loads data/raw_sales_data.csv
--
-- Run from the project folder:
--   psql -d sales_db -f sql/create_table.sql

-- All columns are TEXT in the raw table so the file loads even with bad values.
-- Data types are fixed in data_cleaning_queries.sql.
DROP TABLE IF EXISTS raw_sales;

CREATE TABLE raw_sales (
    order_id        TEXT,
    order_date      TEXT,
    customer_id     TEXT,
    customer_name   TEXT,
    product_id      TEXT,
    product_name    TEXT,
    category        TEXT,
    sub_category    TEXT,
    region          TEXT,
    state           TEXT,
    quantity        TEXT,
    sales           TEXT,
    discount        TEXT,
    cost            TEXT,
    profit          TEXT
);

-- \copy is a psql command. In pgAdmin use right click on the table > Import/Export Data.
\copy raw_sales FROM 'data/raw_sales_data.csv' WITH (FORMAT csv, HEADER true)

SELECT COUNT(*) AS raw_rows FROM raw_sales;
