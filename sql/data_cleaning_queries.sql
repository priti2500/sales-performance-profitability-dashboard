-- 1. Check the raw data for problems
-- 2. Create the cleaned table: sales_clean
-- 3. Validate the cleaned table
-- 4. Export it to data/cleaned_sales_data.csv
--
-- Run after create_table.sql:
--   psql -d sales_db -f sql/data_cleaning_queries.sql


-- 1. Data quality checks on raw_sales

-- 1.1 Exact duplicate rows
SELECT COUNT(*) - COUNT(DISTINCT raw_sales.*) AS duplicate_rows
FROM raw_sales;

-- 1.2 Missing values per column (empty cells load as NULL)
SELECT
    COUNT(*) FILTER (WHERE customer_name IS NULL) AS missing_customer_name,
    COUNT(*) FILTER (WHERE region IS NULL)        AS missing_region,
    COUNT(*) FILTER (WHERE state IS NULL)         AS missing_state,
    COUNT(*) FILTER (WHERE sales IS NULL)         AS missing_sales,
    COUNT(*) FILTER (WHERE cost IS NULL)          AS missing_cost,
    COUNT(*) FILTER (WHERE profit IS NULL)        AS missing_profit,
    COUNT(*) FILTER (WHERE discount IS NULL)      AS missing_discount
FROM raw_sales;

-- 1.3 Two date formats: YYYY-MM-DD and DD/MM/YYYY
SELECT
    CASE
        WHEN order_date ~ '^\d{4}-\d{2}-\d{2}$' THEN 'YYYY-MM-DD'
        WHEN order_date ~ '^\d{2}/\d{2}/\d{4}$' THEN 'DD/MM/YYYY'
        ELSE 'Other'
    END      AS date_format,
    COUNT(*) AS row_count
FROM raw_sales
GROUP BY 1;

-- 1.4 Inconsistent text (case and extra spaces)
SELECT category, COUNT(*) AS row_count FROM raw_sales GROUP BY category ORDER BY category;
SELECT region,   COUNT(*) AS row_count FROM raw_sales GROUP BY region   ORDER BY region;

SELECT COUNT(*) AS messy_state_values
FROM raw_sales
WHERE state <> INITCAP(TRIM(state));

-- 1.5 Test rows with zero quantity
SELECT COUNT(*) AS zero_quantity_rows
FROM raw_sales
WHERE quantity::INT <= 0;

-- 1.6 Rows where profit does not equal sales - cost
SELECT COUNT(*) AS wrong_profit_rows
FROM raw_sales
WHERE sales IS NOT NULL AND cost IS NOT NULL AND profit IS NOT NULL
  AND ABS(sales::NUMERIC - cost::NUMERIC - profit::NUMERIC) > 0.01;


-- 2. Create the cleaned table
DROP TABLE IF EXISTS sales_clean;

CREATE TABLE sales_clean AS
WITH dedup AS (
    -- remove exact duplicate rows
    SELECT DISTINCT * FROM raw_sales
),
standardized AS (
    -- fix data types, date formats and text
    SELECT
        TRIM(order_id)                              AS order_id,
        CASE
            WHEN order_date ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(order_date, 'DD/MM/YYYY')
            ELSE TO_DATE(order_date, 'YYYY-MM-DD')
        END                                         AS order_date,
        TRIM(customer_id)                           AS customer_id,
        INITCAP(TRIM(customer_name))                AS customer_name,
        TRIM(product_id)                            AS product_id,
        TRIM(product_name)                          AS product_name,
        INITCAP(TRIM(category))                     AS category,
        TRIM(sub_category)                          AS sub_category,
        INITCAP(TRIM(region))                       AS region,
        INITCAP(TRIM(state))                        AS state,
        quantity::INT                               AS quantity,
        sales::NUMERIC(12, 2)                       AS sales,
        discount::NUMERIC(4, 2)                     AS discount,
        cost::NUMERIC(12, 2)                        AS cost,
        profit::NUMERIC(12, 2)                      AS profit
    FROM dedup
),
filled_customer AS (
    -- a customer always has the same name and state, so fill blanks from their other rows.
    -- if the customer has no other row with a name, use 'Unknown'
    SELECT
        order_id, order_date, customer_id,
        COALESCE(customer_name, MAX(customer_name) OVER (PARTITION BY customer_id), 'Unknown') AS customer_name,
        product_id, product_name, category, sub_category,
        region,
        COALESCE(state, MAX(state) OVER (PARTITION BY customer_id))                 AS state,
        quantity, sales, discount, cost, profit
    FROM standardized
),
state_region AS (
    -- each state belongs to one region
    SELECT DISTINCT state, region
    FROM filled_customer
    WHERE state IS NOT NULL AND region IS NOT NULL
),
filled_numbers AS (
    SELECT
        f.order_id, f.order_date, f.customer_id, f.customer_name,
        f.product_id, f.product_name, f.category, f.sub_category,
        COALESCE(f.region, sr.region)                AS region,
        f.state,
        f.quantity,
        COALESCE(f.sales, f.cost + f.profit)         AS sales,    -- missing sales = cost + profit
        f.discount,                                               -- missing discount is left as NULL
        COALESCE(f.cost, f.sales - f.profit)         AS cost      -- missing cost = sales - profit
    FROM filled_customer f
    LEFT JOIN state_region sr ON f.state = sr.state
    WHERE f.quantity > 0                                          -- remove test rows
)
SELECT
    *,
    sales - cost AS profit                                        -- recalculate profit for every row
FROM filled_numbers;

ALTER TABLE sales_clean ALTER COLUMN profit TYPE NUMERIC(12, 2);


-- 3. Validate the cleaned table

-- 3.1 Row counts before and after
SELECT
    (SELECT COUNT(*) FROM raw_sales)   AS raw_rows,
    (SELECT COUNT(*) FROM sales_clean) AS clean_rows;

-- 3.2 No missing values left (discount is allowed to be NULL)
SELECT
    COUNT(*) FILTER (WHERE customer_name IS NULL) AS missing_customer_name,
    COUNT(*) FILTER (WHERE region IS NULL)        AS missing_region,
    COUNT(*) FILTER (WHERE state IS NULL)         AS missing_state,
    COUNT(*) FILTER (WHERE sales IS NULL)         AS missing_sales,
    COUNT(*) FILTER (WHERE cost IS NULL)          AS missing_cost,
    COUNT(*) FILTER (WHERE discount IS NULL)      AS missing_discount
FROM sales_clean;

-- 3.3 Every state should map to one region only (should return 0 rows)
SELECT state, COUNT(DISTINCT region) AS regions
FROM sales_clean
GROUP BY state
HAVING COUNT(DISTINCT region) > 1;

-- 3.4 Profit = sales - cost, no negative sales or quantity, valid discount (should be 0)
SELECT COUNT(*) AS invalid_rows
FROM sales_clean
WHERE profit <> sales - cost
   OR sales <= 0
   OR quantity <= 0
   OR discount NOT BETWEEN 0 AND 1;

-- 3.5 Each product should have one unit cost and one list price (should return 0 rows)
--     This also checks that sales, cost and discount agree with each other.
SELECT
    product_id,
    COUNT(DISTINCT ROUND(cost / quantity, 2))                       AS unit_costs,
    COUNT(DISTINCT ROUND(sales / (quantity * (1 - discount)), 0))   AS list_prices
FROM sales_clean
GROUP BY product_id
HAVING COUNT(DISTINCT ROUND(cost / quantity, 2)) > 1
    OR COUNT(DISTINCT ROUND(sales / (quantity * (1 - discount)), 0)) > 1;

-- 3.6 Clean text values
SELECT DISTINCT category FROM sales_clean ORDER BY category;
SELECT DISTINCT region   FROM sales_clean ORDER BY region;

-- 3.7 Date range
SELECT MIN(order_date) AS first_date, MAX(order_date) AS last_date FROM sales_clean;


-- 4. Export the cleaned data
\copy (SELECT * FROM sales_clean ORDER BY order_id, product_id) TO 'data/cleaned_sales_data.csv' WITH (FORMAT csv, HEADER true)
