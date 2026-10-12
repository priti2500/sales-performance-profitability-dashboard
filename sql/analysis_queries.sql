-- Business analysis on the cleaned table: sales_clean
-- One row in sales_clean = one product in an order.
--
--   psql -d sales_db -f sql/analysis_queries.sql


-- A. Overall KPIs

-- 1. Overall KPIs: sales, profit, margin, orders, customers, quantity, average order value
SELECT
    SUM(sales)                                         AS total_sales,
    SUM(profit)                                        AS total_profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1)         AS profit_margin_pct,
    COUNT(DISTINCT order_id)                           AS total_orders,
    COUNT(DISTINCT customer_id)                        AS unique_customers,
    SUM(quantity)                                      AS total_quantity,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2)    AS avg_order_value
FROM sales_clean;

-- 2. Same KPIs by year (2024 vs 2025)
SELECT
    EXTRACT(YEAR FROM order_date)::INT                 AS order_year,
    SUM(sales)                                         AS total_sales,
    SUM(profit)                                        AS total_profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1)         AS profit_margin_pct,
    COUNT(DISTINCT order_id)                           AS total_orders,
    COUNT(DISTINCT customer_id)                        AS unique_customers,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2)    AS avg_order_value
FROM sales_clean
GROUP BY order_year
ORDER BY order_year;


-- B. Monthly trends

-- 3. Monthly sales and profit trend
SELECT
    DATE_TRUNC('month', order_date)::DATE              AS order_month,
    SUM(sales)                                         AS sales,
    SUM(profit)                                        AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1)         AS margin_pct,
    COUNT(DISTINCT order_id)                           AS orders
FROM sales_clean
GROUP BY order_month
ORDER BY order_month;

-- 4. Month-over-month sales growth (LAG gets the previous month's value)
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', order_date)::DATE AS order_month,
        SUM(sales)                            AS sales
    FROM sales_clean
    GROUP BY order_month
)
SELECT
    order_month,
    sales,
    LAG(sales) OVER (ORDER BY order_month)    AS previous_month_sales,
    ROUND(100.0 * (sales - LAG(sales) OVER (ORDER BY order_month))
          / LAG(sales) OVER (ORDER BY order_month), 1) AS mom_growth_pct
FROM monthly
ORDER BY order_month;

-- 5. Highest sales months (top 3)
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', order_date)::DATE AS order_month,
        SUM(sales)                            AS sales
    FROM sales_clean
    GROUP BY order_month
)
SELECT *
FROM (
    SELECT order_month, sales, RANK() OVER (ORDER BY sales DESC) AS sales_rank
    FROM monthly
) ranked
WHERE sales_rank <= 3
ORDER BY sales_rank;

-- 6. Lowest profit months (bottom 3)
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', order_date)::DATE      AS order_month,
        SUM(sales)                                 AS sales,
        SUM(profit)                                AS profit,
        ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct
    FROM sales_clean
    GROUP BY order_month
)
SELECT *
FROM (
    SELECT order_month, sales, profit, margin_pct, RANK() OVER (ORDER BY profit) AS profit_rank
    FROM monthly
) ranked
WHERE profit_rank <= 3
ORDER BY profit_rank;


-- C. Region and state

-- 7. Sales and profit by region
SELECT
    region,
    SUM(sales)                                              AS sales,
    SUM(profit)                                             AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1)              AS margin_pct,
    ROUND(100.0 * SUM(sales) / SUM(SUM(sales)) OVER (), 1)  AS pct_of_total_sales,
    COUNT(DISTINCT customer_id)                             AS customers
FROM sales_clean
GROUP BY region
ORDER BY sales DESC;

-- 8. Best and weakest states by profit (top 3 and bottom 3)
WITH state_summary AS (
    SELECT
        state,
        region,
        SUM(sales)                                 AS sales,
        SUM(profit)                                AS profit,
        ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct
    FROM sales_clean
    GROUP BY state, region
),
ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY profit DESC) AS best_rank,
        RANK() OVER (ORDER BY profit ASC)  AS weak_rank
    FROM state_summary
)
SELECT
    CASE WHEN best_rank <= 3 THEN 'Best' ELSE 'Weakest' END AS state_group,
    state, region, sales, profit, margin_pct
FROM ranked
WHERE best_rank <= 3 OR weak_rank <= 3
ORDER BY profit DESC;

-- 9. All states sorted by margin (to spot low-margin states)
SELECT
    state,
    region,
    SUM(sales)                                 AS sales,
    SUM(profit)                                AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct
FROM sales_clean
GROUP BY state, region
ORDER BY margin_pct;


-- D. Category and products

-- 10. Sales, profit and profit margin by category
SELECT
    category,
    SUM(sales)                                               AS sales,
    SUM(profit)                                              AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1)               AS profit_margin_pct,
    ROUND(100.0 * SUM(sales)  / SUM(SUM(sales))  OVER (), 1) AS pct_of_sales,
    ROUND(100.0 * SUM(profit) / SUM(SUM(profit)) OVER (), 1) AS pct_of_profit
FROM sales_clean
GROUP BY category
ORDER BY sales DESC;

-- 11. Sub-category margin (lowest first)
SELECT
    category,
    sub_category,
    SUM(sales)                                 AS sales,
    SUM(profit)                                AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS profit_margin_pct
FROM sales_clean
GROUP BY category, sub_category
ORDER BY profit_margin_pct;

-- 12. Top 5 products by sales
WITH product_sales AS (
    SELECT
        product_name,
        category,
        SUM(quantity) AS units,
        SUM(sales)    AS sales,
        SUM(profit)   AS profit
    FROM sales_clean
    GROUP BY product_name, category
)
SELECT *
FROM (
    SELECT *, DENSE_RANK() OVER (ORDER BY sales DESC) AS sales_rank
    FROM product_sales
) ranked
WHERE sales_rank <= 5
ORDER BY sales_rank;

-- 13. Top 5 products by profit
WITH product_profit AS (
    SELECT
        product_name,
        category,
        SUM(sales)                                 AS sales,
        SUM(profit)                                AS profit,
        ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct
    FROM sales_clean
    GROUP BY product_name, category
)
SELECT *
FROM (
    SELECT *, DENSE_RANK() OVER (ORDER BY profit DESC) AS profit_rank
    FROM product_profit
) ranked
WHERE profit_rank <= 5
ORDER BY profit_rank;

-- 14. Bottom 5 products by profit
SELECT
    product_name,
    category,
    SUM(sales)                                 AS sales,
    SUM(profit)                                AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct,
    ROUND(100.0 * AVG(discount), 1)            AS avg_discount_pct
FROM sales_clean
GROUP BY product_name, category
ORDER BY profit
LIMIT 5;

-- 15. High-sales but low-profit products
--     sales above the average product sales, but margin below 10%
WITH product_summary AS (
    SELECT
        product_name,
        category,
        SUM(sales)  AS sales,
        SUM(profit) AS profit
    FROM sales_clean
    GROUP BY product_name, category
)
SELECT
    product_name,
    category,
    sales,
    profit,
    ROUND(100.0 * profit / sales, 1) AS margin_pct
FROM product_summary
WHERE sales > (SELECT AVG(sales) FROM product_summary)
  AND profit / sales < 0.10
ORDER BY sales DESC;

-- 16. Loss-making order lines: total, then by category
SELECT
    COUNT(*) FILTER (WHERE profit < 0)                              AS loss_lines,
    COUNT(*)                                                        AS all_lines,
    ROUND(100.0 * COUNT(*) FILTER (WHERE profit < 0) / COUNT(*), 1) AS pct_loss_lines
FROM sales_clean;

-- by category
SELECT
    category,
    COUNT(*)                                             AS order_lines,
    COUNT(*) FILTER (WHERE profit < 0)                   AS loss_lines,
    ROUND(100.0 * COUNT(*) FILTER (WHERE profit < 0) / COUNT(*), 1) AS pct_loss_lines,
    COALESCE(SUM(profit) FILTER (WHERE profit < 0), 0)   AS total_loss
FROM sales_clean
GROUP BY category
ORDER BY pct_loss_lines DESC, category;


-- E. Customers

-- 17. Top 10 customers by sales
SELECT
    customer_id,
    customer_name,
    state,
    COUNT(DISTINCT order_id) AS orders,
    SUM(sales)               AS sales,
    SUM(profit)              AS profit
FROM sales_clean
GROUP BY customer_id, customer_name, state
ORDER BY sales DESC
LIMIT 10;

-- 18. Repeat vs one-time customers
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS orders,
        SUM(sales)               AS sales
    FROM sales_clean
    GROUP BY customer_id
)
SELECT
    CASE WHEN orders > 1 THEN 'Repeat' ELSE 'One-time' END     AS customer_type,
    COUNT(*)                                                   AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)         AS pct_of_customers,
    SUM(sales)                                                 AS sales,
    ROUND(100.0 * SUM(sales) / SUM(SUM(sales)) OVER (), 1)     AS pct_of_sales
FROM customer_orders
GROUP BY customer_type;

-- 19. Most loyal customers: 15 or more orders (HAVING example)
SELECT
    customer_id,
    customer_name,
    COUNT(DISTINCT order_id) AS orders,
    SUM(sales)               AS sales
FROM sales_clean
GROUP BY customer_id, customer_name
HAVING COUNT(DISTINCT order_id) >= 15
ORDER BY orders DESC, sales DESC;

-- 20. Share of sales from the top 20% of customers
WITH customer_sales AS (
    SELECT customer_id, SUM(sales) AS sales
    FROM sales_clean
    GROUP BY customer_id
),
ranked AS (
    SELECT sales, NTILE(5) OVER (ORDER BY sales DESC) AS customer_group   -- 1 = top 20%
    FROM customer_sales
)
SELECT
    customer_group,
    COUNT(*)                                                AS customers,
    SUM(sales)                                              AS sales,
    ROUND(100.0 * SUM(sales) / SUM(SUM(sales)) OVER (), 1)  AS pct_of_sales
FROM ranked
GROUP BY customer_group
ORDER BY customer_group;


-- F. Discount impact

-- 21. Profit margin at each discount level
SELECT
    CASE
        WHEN discount IS NULL   THEN 'Not recorded'
        WHEN discount = 0       THEN '0%'
        WHEN discount <= 0.10   THEN '1-10%'
        WHEN discount <= 0.20   THEN '11-20%'
        ELSE 'Above 20%'
    END                                            AS discount_band,
    COUNT(*)                                       AS order_lines,
    SUM(sales)                                     AS sales,
    SUM(profit)                                    AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1)     AS margin_pct,
    COUNT(*) FILTER (WHERE profit < 0)             AS loss_lines
FROM sales_clean
GROUP BY discount_band
ORDER BY MIN(discount) NULLS LAST;

-- 22. Discount impact by category (above 20% vs 20% or less)
SELECT
    category,
    ROUND(100.0 * SUM(profit) FILTER (WHERE discount <= 0.20) / SUM(sales) FILTER (WHERE discount <= 0.20), 1) AS margin_upto_20_pct,
    ROUND(100.0 * SUM(profit) FILTER (WHERE discount >  0.20) / SUM(sales) FILTER (WHERE discount >  0.20), 1) AS margin_above_20_pct
FROM sales_clean
GROUP BY category
ORDER BY margin_above_20_pct;

-- 23. Average discount and margin in Oct-Nov (festive sale) vs other months
SELECT
    CASE WHEN EXTRACT(MONTH FROM order_date) IN (10, 11) THEN 'Oct-Nov' ELSE 'Other months' END AS period,
    ROUND(100.0 * AVG(discount), 1)                AS avg_discount_pct,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1)     AS margin_pct,
    COUNT(DISTINCT order_id)                       AS orders,
    COUNT(DISTINCT DATE_TRUNC('month', order_date)) AS months,
    ROUND(COUNT(DISTINCT order_id)::NUMERIC
          / COUNT(DISTINCT DATE_TRUNC('month', order_date)), 0) AS avg_orders_per_month
FROM sales_clean
GROUP BY period;


-- G. 2025 vs 2024

-- 24. Year-over-year growth in sales, profit and orders
WITH yearly AS (
    SELECT
        EXTRACT(YEAR FROM order_date)::INT AS order_year,
        SUM(sales)                         AS sales,
        SUM(profit)                        AS profit,
        COUNT(DISTINCT order_id)           AS orders
    FROM sales_clean
    GROUP BY order_year
)
SELECT
    order_year,
    sales,
    profit,
    orders,
    ROUND(100.0 * (sales  - LAG(sales)  OVER (ORDER BY order_year)) / LAG(sales)  OVER (ORDER BY order_year), 1) AS sales_growth_pct,
    ROUND(100.0 * (profit - LAG(profit) OVER (ORDER BY order_year)) / LAG(profit) OVER (ORDER BY order_year), 1) AS profit_growth_pct,
    ROUND(100.0 * (orders - LAG(orders) OVER (ORDER BY order_year)) / LAG(orders) OVER (ORDER BY order_year), 1) AS orders_growth_pct
FROM yearly
ORDER BY order_year;

-- 25. Category sales and margin by year (what changed in 2025?)
SELECT
    category,
    SUM(sales) FILTER (WHERE EXTRACT(YEAR FROM order_date) = 2024)  AS sales_2024,
    SUM(sales) FILTER (WHERE EXTRACT(YEAR FROM order_date) = 2025)  AS sales_2025,
    ROUND(100.0 * (SUM(sales) FILTER (WHERE EXTRACT(YEAR FROM order_date) = 2025)
                 - SUM(sales) FILTER (WHERE EXTRACT(YEAR FROM order_date) = 2024))
                 / SUM(sales) FILTER (WHERE EXTRACT(YEAR FROM order_date) = 2024), 1) AS sales_growth_pct,
    ROUND(100.0 * SUM(profit) FILTER (WHERE EXTRACT(YEAR FROM order_date) = 2024)
          / SUM(sales) FILTER (WHERE EXTRACT(YEAR FROM order_date) = 2024), 1) AS margin_2024_pct,
    ROUND(100.0 * SUM(profit) FILTER (WHERE EXTRACT(YEAR FROM order_date) = 2025)
          / SUM(sales) FILTER (WHERE EXTRACT(YEAR FROM order_date) = 2025), 1) AS margin_2025_pct
FROM sales_clean
GROUP BY category
ORDER BY sales_2025 DESC;

-- 26. Average discount by year
SELECT
    EXTRACT(YEAR FROM order_date)::INT AS order_year,
    ROUND(100.0 * AVG(discount), 1)    AS avg_discount_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE discount > 0.20) / COUNT(*), 1) AS pct_lines_above_20_discount
FROM sales_clean
GROUP BY order_year
ORDER BY order_year;


-- H. Order value and order frequency

-- 27. Average order value by region
SELECT
    region,
    COUNT(DISTINCT order_id)                         AS orders,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2)  AS avg_order_value
FROM sales_clean
GROUP BY region
ORDER BY avg_order_value DESC;

-- 28. Customers grouped by number of orders
WITH customer_orders AS (
    SELECT customer_id, COUNT(DISTINCT order_id) AS orders
    FROM sales_clean
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN orders = 1   THEN '1'
        WHEN orders <= 3  THEN '2-3'
        WHEN orders <= 6  THEN '4-6'
        WHEN orders <= 10 THEN '7-10'
        ELSE '11+'
    END      AS orders_placed,
    COUNT(*) AS customers
FROM customer_orders
GROUP BY orders_placed
ORDER BY MIN(orders);
