# DAX Measures

The model has two main tables:

- `sales`: loaded from `data/cleaned_sales_data.csv` (one row per product in an order)
- `Date`: a calendar table made with DAX (below), joined to `sales[order_date]`

Create an empty table called `_Measures` (Home > Enter Data > Load) and put all measures there so they are easy to find.

## Date table

Modeling > New Table:

```dax
Date =
ADDCOLUMNS (
    CALENDAR ( DATE ( 2024, 1, 1 ), DATE ( 2025, 12, 31 ) ),
    "Year", YEAR ( [Date] ),
    "Month No", MONTH ( [Date] ),
    "Month", FORMAT ( [Date], "MMM" ),
    "Year Month", FORMAT ( [Date], "YYYY-MM" ),
    "Quarter", "Q" & QUARTER ( [Date] )
)
```

- Table tools > **Mark as date table** > Date column.
- Select `Month` > **Sort by column** > Month No.
- Model view: drag `Date[Date]` to `sales[order_date]` (one to many, single direction).

## Measures

### 1. Total Sales

```dax
Total Sales = SUM ( sales[sales] )
```
- **Explanation:** Adds up the sales amount of all rows in the current filter (sales are already after discount).
- **Table / column:** `sales[sales]`

### 2. Total Profit

```dax
Total Profit = SUM ( sales[profit] )
```
- **Explanation:** Adds up profit (sales - cost) for all rows in the current filter.
- **Table / column:** `sales[profit]`

### 3. Profit Margin %

```dax
Profit Margin % = DIVIDE ( [Total Profit], [Total Sales] )
```
- **Explanation:** Profit as a share of sales. DIVIDE returns blank instead of an error if sales is 0. Format as percentage.
- **Table / column:** uses the two measures above (`sales[profit]`, `sales[sales]`)

### 4. Total Orders

```dax
Total Orders = DISTINCTCOUNT ( sales[order_id] )
```
- **Explanation:** One order can have several product rows, so we count unique order IDs, not rows.
- **Table / column:** `sales[order_id]`

### 5. Total Customers

```dax
Total Customers = DISTINCTCOUNT ( sales[customer_id] )
```
- **Explanation:** Number of unique customers who bought something in the current filter.
- **Table / column:** `sales[customer_id]`

### 6. Average Order Value

```dax
Average Order Value = DIVIDE ( [Total Sales], [Total Orders] )
```
- **Explanation:** Average amount spent per order.
- **Table / column:** `sales[sales]`, `sales[order_id]` (through the measures)

### 7. Previous Month Sales

```dax
Previous Month Sales =
CALCULATE ( [Total Sales], DATEADD ( 'Date'[Date], -1, MONTH ) )
```
- **Explanation:** Moves the date filter back by one month and calculates sales for that month. Needs the Date table and the relationship.
- **Table / column:** `Date[Date]`, `sales[sales]`

### 8. MoM Growth %

```dax
MoM Growth % =
DIVIDE ( [Total Sales] - [Previous Month Sales], [Previous Month Sales] )
```
- **Explanation:** Change in sales compared to the previous month. Blank for the first month because there is no previous month. Format as percentage.
- **Table / column:** uses Total Sales and Previous Month Sales

### 9. Total Quantity

```dax
Total Quantity = SUM ( sales[quantity] )
```
- **Explanation:** Total units sold.
- **Table / column:** `sales[quantity]`

### 10. Average Discount

```dax
Average Discount = AVERAGE ( sales[discount] )
```
- **Explanation:** Average discount per order line. 18 rows have no discount recorded. AVERAGE skips blanks, so they are not counted as 0. Format as percentage.
- **Table / column:** `sales[discount]`

## Optional measure for the card on page 1

The MoM Growth % card on its own has no month in its filter, so it would show blank. This version always shows the latest month:

```dax
MoM Growth % (Latest Month) =
VAR LastDate = MAX ( sales[order_date] )
RETURN
    CALCULATE (
        [MoM Growth %],
        'Date'[Date] > EOMONTH ( LastDate, -1 ),
        'Date'[Date] <= EOMONTH ( LastDate, 0 )
    )
```
- **Explanation:** Finds the last month in the current filter and calculates MoM growth for that month only.
- **Table / column:** `sales[order_date]`, `Date[Date]`

## Extra measures and tables for pages 2 and 3

```dax
Repeat Customers =
COUNTROWS ( FILTER ( VALUES ( sales[customer_id] ), [Total Orders] > 1 ) )

One-Time Customers = [Total Customers] - [Repeat Customers]

Orders per Customer = DIVIDE ( [Total Orders], [Total Customers] )

High Sales Low Profit Flag =
VAR AvgProductSales = AVERAGEX ( ALL ( sales[product_name] ), [Total Sales] )
RETURN
    IF ( [Total Sales] > AvgProductSales && [Profit Margin %] < 0.10, 1, 0 )
```

- **Repeat Customers:** customers with more than one order. Same rule as SQL query 18.
- **High Sales Low Profit Flag:** products with above-average sales and less than 10% margin. Same rule as SQL query 15.

Calculated column on `sales`, used to split customers into repeat and one-time:

```dax
Customer Type =
VAR CustomerOrders =
    CALCULATE ( DISTINCTCOUNT ( sales[order_id] ), ALLEXCEPT ( sales, sales[customer_id] ) )
RETURN
    IF ( CustomerOrders > 1, "Repeat", "One-time" )
```

Calculated table with one row per customer, used for the customer group and order count charts:

```dax
Customer Summary =
ADDCOLUMNS (
    VALUES ( sales[customer_id] ),
    "Customer Sales", CALCULATE ( SUM ( sales[sales] ) ),
    "Customer Orders", CALCULATE ( DISTINCTCOUNT ( sales[order_id] ) )
)
```

Columns on `Customer Summary`:

```dax
Sales Rank = RANKX ( 'Customer Summary', 'Customer Summary'[Customer Sales] )

-- 686 customers split into 5 groups of 138, 137, 137, 137, 137 (same as NTILE(5) in SQL query 20)
Customer Group =
SWITCH (
    TRUE (),
    'Customer Summary'[Sales Rank] <= 138, "Top 20%",
    'Customer Summary'[Sales Rank] <= 275, "20-40%",
    'Customer Summary'[Sales Rank] <= 412, "40-60%",
    'Customer Summary'[Sales Rank] <= 549, "60-80%",
    "Bottom 20%"
)

-- same buckets as SQL query 28
Order Bucket =
SWITCH (
    TRUE (),
    'Customer Summary'[Customer Orders] = 1, "1",
    'Customer Summary'[Customer Orders] <= 3, "2-3",
    'Customer Summary'[Customer Orders] <= 6, "4-6",
    'Customer Summary'[Customer Orders] <= 10, "7-10",
    "11+"
)

-- sort columns, so the charts don't sort the labels alphabetically
Group Order = SWITCH ( 'Customer Summary'[Customer Group], "Top 20%", 1, "20-40%", 2, "40-60%", 3, "60-80%", 4, 5 )

Bucket Order = SWITCH ( 'Customer Summary'[Order Bucket], "1", 1, "2-3", 2, "4-6", 3, "7-10", 4, 5 )
```

Select Customer Group > Sort by column > Group Order, and Order Bucket > Sort by column > Bucket Order.

Measure for the customer group chart:

```dax
% of Customer Sales =
DIVIDE (
    SUM ( 'Customer Summary'[Customer Sales] ),
    CALCULATE ( SUM ( 'Customer Summary'[Customer Sales] ), ALL ( 'Customer Summary' ) )
)
```

`Customer Summary` is calculated once for all customers, so the slicers don't change those two charts.

## Expected values (check your report against these)

These come from the SQL queries and `scripts/validate_data.py`. With no slicers selected:

| Measure | Expected value |
|---|---|
| Total Sales | ₹14,738,904 |
| Total Profit | ₹2,871,113 |
| Profit Margin % | 19.5% |
| Total Orders | 2,569 |
| Total Customers | 686 |
| Average Order Value | ₹5,737 |
| Total Quantity | 6,046 |
| Average Discount | 11.5% |
| Previous Month Sales (Dec 2025) | ₹714,300 |
| MoM Growth % (Dec 2025) | 13.4% |
| Total Sales, Year = 2025 | ₹7,894,832 |
| Total Profit, Year = 2025 | ₹1,468,746 |
| Repeat Customers | 480 |
| One-Time Customers | 206 |
| Orders per Customer | 3.74 |

If something doesn't match, check that the Date relationship is active and that the columns loaded with the right data types (sales, cost, profit, discount = Decimal number; quantity = Whole number; order_date = Date).
