# Dashboard Design

Three report pages built on `data/cleaned_sales_data.csv`. Measures are in `dax_measures.md`.

## Loading the data

**Option 1 (simple):** Get Data > Text/CSV > `data/cleaned_sales_data.csv`. Rename the query to `sales`.

**Option 2 (Power Query practice):** load `data/raw_sales_data.csv` and clean it in Power Query. These steps do the same cleaning as `sql/data_cleaning_queries.sql` and should give 3,739 rows:

| # | Step | How |
|---|---|---|
| 1 | Remove duplicate rows | Select all columns > Home > Remove Rows > Remove Duplicates |
| 2 | Clean text | Select category, region, state, customer_name > Transform > Format > Trim, then Capitalize Each Word. For product_name and sub_category use Trim only |
| 3 | Fix dates | Add a custom column (code below), set its type to Date, then delete the old order_date column |
| 4 | Change types | quantity = Whole Number; sales, cost, profit, discount = Decimal Number |
| 5 | Remove test rows | Filter quantity > 0 |
| 6 | Fill missing sales / cost | Custom columns (code below) |
| 7 | Recalculate profit | Custom column: `[sales] - [cost]` |
| 8 | Fill missing customer_name and state | Group/merge by customer_id, or sort by customer_id and use Fill Down / Fill Up |
| 9 | Fill missing region | Merge with a state-region list (each state is in one region) |

Custom column for the date (handles both YYYY-MM-DD and DD/MM/YYYY):

```m
if Text.Contains([order_date], "/")
then Date.FromText([order_date], [Format = "dd/MM/yyyy", Culture = "en-US"])
else Date.FromText([order_date], [Format = "yyyy-MM-dd", Culture = "en-US"])
```

Custom columns for missing numbers:

```m
// sales_fixed
if [sales] = null then [cost] + [profit] else [sales]

// cost_fixed
if [cost] = null then [sales] - [profit] else [cost]
```

Missing discount values are left blank because they cannot be worked out from the other columns.

Note on step 8: Fill Down / Fill Up only works correctly after sorting by customer_id so the blank sits next to a row of the same customer. Check a few customers after doing it.

## Model

```
Date (1) ──── (*) sales
 Date            order_date
```

- `Date` table from `dax_measures.md`, marked as date table.
- One relationship: `Date[Date]` to `sales[order_date]`.
- Use `Date[Year]`, `Date[Month]`, `Date[Year Month]` on charts instead of the order_date column.

## Slicers (on every page)

Order Date (`Date[Date]`, between), Region (`sales[region]`) and Category (`sales[category]`). Use View > Sync slicers so the selection carries across pages.

## Page 1: Executive Overview

How is the business doing overall?

| Area | Visual | Fields |
|---|---|---|
| Top row | 7 cards | Total Sales, Total Profit, Profit Margin %, Total Orders, Total Customers, Average Order Value, MoM Growth % (Latest Month) |
| Middle left | Line chart | X: Date[Year Month], Y: Total Sales |
| Middle right | Line chart | X: Date[Year Month], Y: Total Profit |
| Bottom left | Bar chart | Y: region, X: Total Sales |
| Bottom middle | Bar chart | Y: category, X: Total Profit |
| Bottom right | Bar chart | Top 5 product_name by Total Sales (Filters pane > Top N = 5) |

## Page 2: Product & Regional Analysis

Which products and regions make or lose money?

| Area | Visual | Fields |
|---|---|---|
| Top row | 4 bar charts | Sales by Category, Profit by Category, Sales by Region, Profit by Region |
| Left | Table | category, sub_category, Total Sales, Total Profit, Profit Margin % (lowest margin first, red font for negative values) |
| Middle top | Bar chart | Top 5 product_name by Total Sales |
| Middle bottom | Bar chart | Bottom 5 product_name by Total Profit (Top N = 5, Bottom) |
| Right top | Table | state, region, Total Sales, Total Profit, Profit Margin % (sorted by profit) |
| Right bottom | Table | product_name, category, Total Sales, Total Profit, Profit Margin %, filtered on High Sales Low Profit Flag = 1 |

## Page 3: Customer Analysis

Who are the customers and how much do they bring in?

| Area | Visual | Fields |
|---|---|---|
| Top row | 5 cards | Total Customers, Repeat Customers, One-Time Customers, Average Order Value, Orders per Customer |
| Left | Table | Top 10 customers by Total Sales: customer_name, state, Total Orders, Total Sales, Total Profit. Use Top N on customer_id, because some customer names are shared by different customers |
| Middle top | Stacked bar or 2 donut charts | Customer Type: share of customers and share of sales |
| Right top | Column chart | X: Customer Summary[Customer Group], Y: % of Customer Sales |
| Bottom | 3 charts | Total Customers by region, Average Order Value by region, customers by Customer Summary[Order Bucket] |

The extra measures, the Customer Type column and the Customer Summary table used on pages 2 and 3 are in `dax_measures.md`.

## Design notes

- One color for sales and another for profit on every page.
- Red only for negative values (loss, negative growth).
- Currency as ₹ with no decimals, percentages with 1 decimal.
