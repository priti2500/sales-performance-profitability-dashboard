"""
Checks data/cleaned_sales_data.csv and recalculates the main KPIs with pandas,
so they can be compared with the SQL results and the Power BI cards.

Run from the project folder:  python scripts/validate_data.py
"""

from pathlib import Path

import pandas as pd

DATA = Path(__file__).resolve().parent.parent / "data"

raw = pd.read_csv(DATA / "raw_sales_data.csv")
df = pd.read_csv(DATA / "cleaned_sales_data.csv", parse_dates=["order_date"])

print("Raw rows:", len(raw), "| Cleaned rows:", len(df))

# Data checks
checks = {
    "duplicate rows": df.duplicated().sum(),
    "missing values (except discount)": df.drop(columns="discount").isna().sum().sum(),
    "rows where profit != sales - cost": ((df["sales"] - df["cost"] - df["profit"]).abs() > 0.01).sum(),
    "rows with quantity <= 0": (df["quantity"] <= 0).sum(),
    "rows with sales <= 0": (df["sales"] <= 0).sum(),
    "states mapped to more than one region": (df.groupby("state")["region"].nunique() > 1).sum(),
}
for name, value in checks.items():
    print(f"{'OK  ' if value == 0 else 'FAIL'} {name}: {value}")
print("rows with missing discount (kept on purpose):", df["discount"].isna().sum())

# KPIs
total_sales = df["sales"].sum()
total_profit = df["profit"].sum()
orders = df["order_id"].nunique()

monthly = df.groupby(df["order_date"].dt.to_period("M"))["sales"].sum()
last_month, prev_month = monthly.iloc[-1], monthly.iloc[-2]

print("\nKPIs")
print(f"Total Sales        : {total_sales:,.2f}")
print(f"Total Profit       : {total_profit:,.2f}")
print(f"Profit Margin %    : {100 * total_profit / total_sales:.1f}")
print(f"Total Orders       : {orders:,}")
print(f"Total Customers    : {df['customer_id'].nunique():,}")
print(f"Average Order Value: {total_sales / orders:,.2f}")
print(f"Total Quantity     : {df['quantity'].sum():,}")
print(f"Average Discount % : {100 * df['discount'].mean():.1f}")
print(f"Sales {monthly.index[-1]}      : {last_month:,.2f}")
print(f"Sales {monthly.index[-2]}      : {prev_month:,.2f}")
print(f"MoM Growth % (last month): {100 * (last_month - prev_month) / prev_month:.1f}")
