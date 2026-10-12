# Interview Explanation

Notes to help me explain this project in interviews. All numbers here come from the SQL results.

## 30-second explanation

I analyzed two years of sales data for an online retail store using PostgreSQL and Power BI. I cleaned the raw data in SQL, wrote queries for sales, profit, products, regions, customers and discounts, and designed a 3-page Power BI report. The main finding was that sales grew 15.4% in 2025 but profit grew only 4.7%, because most of the growth came from low-margin Electronics and Furniture, and discounts above 20% were making those categories lose money.

## 60-second explanation

The goal was to find out whether the store's sales growth was actually profitable. I didn't have real company data, so I generated a realistic dataset of about 3,800 order lines for 2024 and 2025, with common problems like duplicates, missing values, two date formats and messy text.

I loaded the raw CSV into PostgreSQL as text, then cleaned it: removed duplicates, converted dates, standardised text, filled missing values where they could be worked out, and recalculated profit as sales minus cost. Then I wrote SQL queries for KPIs, monthly trends, MoM growth, category and product performance, states, customers and discount impact.

I found that Electronics brings 47% of sales but only 25% of profit, that discounts above 20% give a negative margin, and that Oct-Nov has the most orders but the lowest margin. For Power BI, I designed a 3-page report and created DAX measures like Profit Margin % and MoM Growth %.

## 2-minute explanation

**Problem:** The store's sales were growing, and the question was whether profit was growing too, and which products, regions and customers were actually making money.

**Data:** I generated a dataset for a fictional Indian online store with 3,787 raw rows from January 2024 to December 2025. Each row is one product in an order, with sales, discount, cost and profit. I added problems on purpose: 40 duplicate rows, 172 dates in a different format, inconsistent text like "NORTH" and " North", missing values in 7 columns, 15 rows where profit was wrong, and 8 test rows with zero quantity.

**Cleaning:** In PostgreSQL I loaded the raw file into a text table, so the load would not fail on bad values. Then I built a cleaned table using CTEs, step by step: remove duplicates, fix data types and dates, trim and standardise text, fill missing names and states from the same customer's other rows, fill region from state, rebuild missing sales or cost from the other two numbers, and recalculate profit. I ended with 3,739 clean rows. I validated it with SQL checks and also with a small Python script that recalculates the KPIs.

**Analysis:** I wrote 28 queries. Overall sales were ₹1.47 crore with a 19.5% margin. In 2025, sales grew 15.4% but profit only 4.7%. When I broke it down by category, Furniture grew 40.2% and Electronics 12.6%, and these have low margins, while the average discount stayed almost the same. So the problem was the product mix, not more discounting. I also found that order lines with more than 20% discount had a -7.0% margin, and Electronics and Furniture lose money above 20% discount, while Fashion and Beauty stay profitable.

**Power BI:** I designed three report pages: Executive Overview, Product & Regional Analysis, and Customer Analysis. The model uses a DAX Date table, and the measures include Total Sales, Profit Margin %, Previous Month Sales (with DATEADD) and MoM Growth %.

**Recommendations:** Review discounts above 20% on Electronics and Furniture, use Fashion and Beauty for big promotions, review laptop pricing, and report profit together with sales.

## Why I chose this project

Sales and profit analysis is a common task for a data analyst. This project let me practise cleaning messy data, writing SQL for business questions, calculating KPIs and explaining the results. I also wanted a case where the answer isn't obvious, like sales growing much faster than profit.

## Cleaning process

1. Loaded the raw CSV into `raw_sales` with every column as TEXT.
2. Checked problems first: duplicates, missing values per column, date formats, text variations, zero quantity, wrong profit.
3. Removed exact duplicates with `SELECT DISTINCT *`.
4. Converted dates: used a regex to detect `DD/MM/YYYY` and `TO_DATE` with the right format.
5. Standardised text with `TRIM` and `INITCAP`. I did not use `INITCAP` on product names because it would break names like "iQOO Z9".
6. Filled missing customer name and state using `MAX() OVER (PARTITION BY customer_id)`, because a customer always has the same name and state.
7. Filled missing region from a state-to-region list.
8. Rebuilt missing sales or cost from the other two values, and recalculated profit for every row.
9. Kept missing discounts as NULL because they can't be worked out.
10. Removed test rows with quantity 0.
11. Validated: profit = sales - cost, no missing values, one region per state, one unit cost and list price per product.

## How I used SQL

- Aggregations (SUM, COUNT DISTINCT, AVG) for KPIs.
- `GROUP BY` for region, state, category, product and customer summaries.
- `CASE WHEN` to make discount bands and label customers as repeat or one-time.
- `HAVING` to find customers with 15 or more orders.
- CTEs to keep longer queries readable.
- `LAG` for month-over-month and year-over-year growth.
- `RANK` and `DENSE_RANK` for top and bottom months, states and products.
- `NTILE(5)` to split customers into 5 groups by sales.
- `SUM(...) OVER ()` to get each group's share of the total.
- `FILTER` to calculate 2024 and 2025 values side by side.

## How I used Power BI

- Loaded the cleaned CSV. The raw file can also be cleaned with Power Query (steps are in `powerbi/dashboard_design.md`).
- Created a Date table with DAX, marked it as a date table and joined it to order_date.
- Wrote measures for the KPIs, Previous Month Sales (DATEADD) and MoM Growth %.
- Designed 3 pages with slicers for order date, region and category.

## KPIs and what they mean

| KPI | Meaning | Value |
|---|---|---|
| Total Sales | Revenue after discount | ₹14,738,904 |
| Total Profit | Sales minus product cost | ₹2,871,113 |
| Profit Margin % | Profit / Sales | 19.5% |
| Total Orders | Unique order IDs | 2,569 |
| Total Customers | Unique customers | 686 |
| Average Order Value | Sales / Orders | ₹5,737 |
| MoM Growth % | Change vs previous month | 13.4% in Dec 2025 |

## Challenges

- **Two date formats:** a direct cast would fail, so I checked the pattern with a regex first.
- **Missing numbers:** I didn't want to fill them with 0 or the average, because that would change totals. Since profit = sales - cost, I could rebuild sales or cost exactly when the other two were present.
- **Missing discount:** it can't be calculated from the other columns, so I kept it as NULL and showed it separately instead of guessing.
- **Counting orders:** one order can have several rows, so I used `COUNT(DISTINCT order_id)` and `DISTINCTCOUNT` instead of counting rows.
- **Monthly numbers jump around:** a few big laptop or furniture orders can change a month a lot, so I looked at the trend and yearly comparison too, not only MoM.

## Validation

- Raw rows (3,787) minus duplicates (40) minus test rows (8) = 3,739 clean rows.
- SQL checks: profit = sales - cost on every row, no missing values except discount, each state has one region, each product has one unit cost and one list price.
- `scripts/validate_data.py` recalculated the KPIs from the cleaned CSV with pandas, and they matched the SQL results.
- `powerbi/dax_measures.md` lists the expected values so the Power BI cards can be checked against SQL.

## 20 interview questions

**1. Why did you load all columns as TEXT first?**
So the load doesn't fail if a value is in the wrong format, like a date in DD/MM/YYYY. I fix the types later in the cleaning step where I can control it.

**2. How did you find duplicates?**
I compared `COUNT(*)` with `COUNT(DISTINCT raw_sales.*)`. The difference (40) is the number of exact duplicate rows.

**3. What is the difference between WHERE and HAVING?**
WHERE filters rows before grouping. HAVING filters groups after aggregation, like customers with `COUNT(DISTINCT order_id) >= 15`.

**4. Why COUNT(DISTINCT order_id) instead of COUNT(*)?**
One order can contain several products, so it has several rows. COUNT(*) would count products, not orders.

**5. How did you handle missing values?**
It depends on the column. Name and state were filled from the same customer's other rows. Region was filled from state. Sales and cost were rebuilt from the other two numbers. Discount was left as NULL because it can't be calculated.

**6. Why not fill missing discount with 0?**
That would say there was no discount when we don't know. It would also change the discount analysis. It's only 18 rows, so I kept them and labelled them "Not recorded".

**7. What does LAG do?**
It returns a value from the previous row in a given order. I used it to get the previous month's sales and calculate MoM growth.

**8. RANK vs DENSE_RANK vs ROW_NUMBER?**
ROW_NUMBER gives every row a different number. RANK gives ties the same rank and skips the next number (1, 1, 3). DENSE_RANK gives ties the same rank without skipping (1, 1, 2).

**9. What is a CTE and why use it?**
A CTE is a named temporary result defined with `WITH`. It splits a long query into steps, which makes it easier to read and debug.

**10. What did NTILE show you?**
`NTILE(5)` split customers into 5 equal groups by sales. The top 20% brought 61.4% of sales.

**11. How did you calculate profit margin?**
Total profit divided by total sales. I calculate it on the totals, not as an average of each row's margin, because the average of row margins gives small orders too much weight.

**12. Why did profit grow slower than sales in 2025?**
Sales grew 15.4%, profit 4.7%. Furniture (+40.2%) and Electronics (+12.6%) grew fastest, and they have low margins. The average discount was almost the same, so it was the product mix.

**13. Which products would you look at first?**
Laptops. Three laptop models lost money overall, and the top 5 products by sales (phones and laptops) all have margins of 7% or less.

**14. What does your discount analysis show?**
Margin falls as discount rises: 29.2% with no discount, 13.9% at 11-20%, and -7.0% above 20%. Electronics and Furniture lose money above 20%, but Fashion and Beauty don't.

**15. Why do you need a Date table in Power BI?**
Time intelligence functions like DATEADD need a continuous date table marked as a date table. It also gives Year and Month columns for slicers and charts.

**16. Explain your MoM Growth % measure.**
Previous Month Sales uses `CALCULATE([Total Sales], DATEADD('Date'[Date], -1, MONTH))`. MoM Growth % is `DIVIDE([Total Sales] - [Previous Month Sales], [Previous Month Sales])`.

**17. Why use DIVIDE instead of the / operator?**
DIVIDE returns blank instead of an error when the denominator is 0 or blank, for example in the first month where there is no previous month.

**18. What is the difference between a measure and a calculated column?**
A calculated column is computed for each row when data is loaded and stored in the table. A measure is calculated when it's used in a visual, based on the current filters. KPIs like Total Sales should be measures.

**19. How did you make sure your numbers were correct?**
I checked row counts before and after cleaning, ran validation queries on the cleaned table, recalculated the KPIs in Python and compared them to SQL, and listed expected values to check the Power BI cards.

**20. What would you add with more time or real data?**
Shipping and marketing costs to get net profit, returns data, a customer retention analysis by month, and a check on why Rajasthan's margin is so low.
