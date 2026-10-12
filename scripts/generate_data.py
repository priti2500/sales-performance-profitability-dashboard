"""
Generates data/raw_sales_data.csv for this project.

I did not have real company data, so this script creates sales for a fictional
Indian online store from Jan 2024 to Dec 2025. Some problems are added on purpose
(duplicates, missing values, mixed date formats, messy text, wrong profit values)
so the data can be cleaned in SQL / Power Query.

Run from the project folder:  python scripts/generate_data.py
"""

import random
from datetime import date, timedelta
from pathlib import Path

import numpy as np
import pandas as pd

random.seed(7)
np.random.seed(7)

OUT_FILE = Path(__file__).resolve().parent.parent / "data" / "raw_sales_data.csv"

# Products
# category, sub_category, product names, price range (Rs), cost as % of price
catalog = [
    ("Electronics", "Mobiles", ["Galaxy M15 5G", "Redmi Note 13", "Realme Narzo 70", "iQOO Z9", "Moto G64"], (10999, 24999), (0.84, 0.90)),
    ("Electronics", "Laptops", ["IdeaPad Slim 3", "Vivobook 15", "HP 15s Ryzen 5", "Inspiron 3520"], (34999, 56999), (0.86, 0.91)),
    ("Electronics", "Audio", ["boAt Rockerz 450", "Noise Buds VS104", "JBL Tune 520BT", "Sony WH-CH520"], (999, 4999), (0.55, 0.68)),
    ("Electronics", "Accessories", ["20W USB-C Charger", "10000mAh Power Bank", "Wireless Mouse", "Laptop Sleeve 15.6"], (299, 1499), (0.40, 0.55)),
    ("Fashion", "Men's Clothing", ["Cotton Round Neck T-Shirt", "Slim Fit Jeans", "Casual Linen Shirt", "Polo T-Shirt"], (399, 2499), (0.40, 0.52)),
    ("Fashion", "Women's Clothing", ["Printed Kurta", "Rayon Anarkali Set", "Cotton Saree", "Palazzo Pants"], (499, 2999), (0.40, 0.52)),
    ("Fashion", "Footwear", ["Running Shoes", "Casual Sneakers", "Leather Formal Shoes", "Flip Flops"], (299, 3499), (0.45, 0.58)),
    ("Home & Kitchen", "Cookware", ["Non-Stick Tawa", "Pressure Cooker 5L", "Stainless Steel Cookware Set"], (499, 3499), (0.58, 0.70)),
    ("Home & Kitchen", "Appliances", ["Mixer Grinder 750W", "Electric Kettle 1.5L", "Air Fryer 4L", "Steam Iron"], (899, 6999), (0.70, 0.80)),
    ("Home & Kitchen", "Home Decor", ["Wall Clock", "Cushion Covers Set of 5", "Table Lamp"], (299, 1999), (0.40, 0.55)),
    ("Furniture", "Chairs", ["Ergonomic Office Chair", "Gaming Chair", "Study Chair"], (1999, 12999), (0.70, 0.80)),
    ("Furniture", "Tables", ["Study Table", "Coffee Table", "4 Seater Dining Table"], (1999, 17999), (0.70, 0.80)),
    ("Furniture", "Storage", ["3 Door Wardrobe", "Shoe Rack", "Bookshelf 5 Tier"], (999, 14999), (0.70, 0.80)),
    ("Beauty", "Skincare", ["Vitamin C Face Serum", "Sunscreen SPF 50", "Face Wash 100ml"], (199, 699), (0.35, 0.48)),
    ("Beauty", "Haircare", ["Onion Hair Oil", "Anti-Dandruff Shampoo", "Hair Dryer"], (249, 1999), (0.40, 0.55)),
]

products = []
pid = 1
for cat, sub, names, (pmin, pmax), (cmin, cmax) in catalog:
    for name in names:
        price = int(round(random.uniform(pmin, pmax) / 100.0) * 100 - 1)  # prices like 1499
        unit_cost = round(price * random.uniform(cmin, cmax), 2)
        products.append(dict(product_id=f"P{pid:03d}", product_name=name, category=cat,
                             sub_category=sub, price=price, unit_cost=unit_cost))
        pid += 1
prod = pd.DataFrame(products)
# cheaper products sell more often
prod["weight"] = 1 / np.sqrt(prod["price"]) * np.random.uniform(0.6, 1.4, len(prod))

# Customers
states = {
    "North": ["Delhi", "Haryana", "Uttar Pradesh", "Rajasthan", "Punjab"],
    "South": ["Karnataka", "Tamil Nadu", "Telangana", "Kerala"],
    "West": ["Maharashtra", "Gujarat", "Madhya Pradesh"],
    "East": ["West Bengal", "Odisha", "Bihar", "Assam"],
}
region_weight = {"North": 0.28, "South": 0.29, "West": 0.29, "East": 0.14}
first_names = ["Aarav", "Aditya", "Arjun", "Rohan", "Karan", "Rahul", "Amit", "Vikram", "Nikhil", "Saurabh",
               "Manish", "Deepak", "Suresh", "Ankit", "Harsh", "Yash", "Kunal", "Priya", "Ananya", "Sneha",
               "Pooja", "Neha", "Riya", "Kavya", "Divya", "Shreya", "Meera", "Nisha", "Swati", "Anjali",
               "Tanvi", "Sakshi", "Ritu", "Lakshmi", "Farhan", "Imran", "Sameer", "Sana", "Joseph", "Simran"]
last_names = ["Sharma", "Verma", "Gupta", "Singh", "Kumar", "Patel", "Shah", "Mehta", "Reddy", "Nair",
              "Iyer", "Rao", "Das", "Banerjee", "Joshi", "Kulkarni", "Desai", "Pillai", "Menon", "Agarwal",
              "Jain", "Malhotra", "Kapoor", "Khan", "Fernandes", "Gill"]

N_CUST = 1100
cust_rows = []
for i in range(1, N_CUST + 1):
    region = np.random.choice(list(region_weight), p=list(region_weight.values()))
    cust_rows.append(dict(customer_id=f"C{i:04d}",
                          customer_name=f"{random.choice(first_names)} {random.choice(last_names)}",
                          region=region, state=random.choice(states[region])))
cust = pd.DataFrame(cust_rows)
cust["weight"] = np.random.gamma(shape=0.6, scale=1.0, size=N_CUST)  # some customers buy much more

# Orders
month_factor = {1: 0.85, 2: 0.82, 3: 0.90, 4: 0.88, 5: 0.92, 6: 0.90,
                7: 0.95, 8: 1.00, 9: 1.05, 10: 1.40, 11: 1.35, 12: 1.10}  # Oct-Nov festive season
rows = []
oid = 10001
day = date(2024, 1, 1)
while day <= date(2025, 12, 31):
    growth = 1.0 if day.year == 2024 else 1.10
    n_orders = np.random.poisson(3.3 * month_factor[day.month] * growth)
    festive = day.month in (10, 11)
    for _ in range(n_orders):
        c = cust.sample(1, weights="weight").iloc[0]
        n_items = np.random.choice([1, 2, 3], p=[0.66, 0.25, 0.09])
        for _, p in prod.sample(n_items, weights="weight").iterrows():
            qty = int(np.random.choice([1, 2, 3, 4, 5], p=[0.62, 0.22, 0.09, 0.05, 0.02]))
            if p["category"] in ("Fashion", "Furniture"):
                probs = [0.20, 0.12, 0.18, 0.14, 0.16, 0.12, 0.08]
            else:
                probs = [0.36, 0.20, 0.20, 0.11, 0.08, 0.04, 0.01]
            if festive:
                probs = [0.10, 0.10, 0.18, 0.18, 0.20, 0.15, 0.09]
            disc = float(np.random.choice([0, 0.05, 0.10, 0.15, 0.20, 0.30, 0.40], p=probs))
            sales = round(qty * p["price"] * (1 - disc), 2)
            cost = round(qty * p["unit_cost"], 2)
            rows.append(dict(order_id=f"ORD{oid}", order_date=day,
                             customer_id=c["customer_id"], customer_name=c["customer_name"],
                             product_id=p["product_id"], product_name=p["product_name"],
                             category=p["category"], sub_category=p["sub_category"],
                             region=c["region"], state=c["state"], quantity=qty,
                             sales=sales, discount=disc, cost=cost, profit=round(sales - cost, 2)))
        oid += 1
    day += timedelta(days=1)

df = pd.DataFrame(rows).astype({"sales": object, "cost": object, "profit": object,
                                "discount": object, "quantity": object})
print("clean rows generated:", len(df))

# Add data problems
# pick separate rows for each numeric problem so they don't overlap
idx = np.random.permutation(df.index)
missing_sales, missing_cost, missing_profit, missing_disc, wrong_profit, zero_qty = (
    idx[0:12], idx[12:22], idx[22:42], idx[42:60], idx[60:75], idx[75:83])
df.loc[missing_sales, "sales"] = None                 # can be rebuilt as cost + profit
df.loc[missing_cost, "cost"] = None                   # can be rebuilt as sales - profit
df.loc[missing_profit, "profit"] = None               # can be rebuilt as sales - cost
df.loc[missing_disc, "discount"] = None               # cannot be rebuilt
for i in wrong_profit:                                 # typing mistakes in profit
    df.at[i, "profit"] = round(float(df.at[i, "profit"]) * random.choice([10, -1, 0.1]), 2)
df.loc[zero_qty, ["quantity", "sales", "cost", "profit"]] = [0, 0, 0, 0]   # test entries

# missing text values
df.loc[df.sample(n=30, random_state=1).index, "customer_name"] = None
df.loc[df.sample(n=25, random_state=2).index, "region"] = None
df.loc[df.sample(n=15, random_state=3).index, "state"] = None

# inconsistent text
def messy(series, frac, seed):
    pick = series.dropna().sample(frac=frac, random_state=seed).index
    return pick, series.loc[pick].map(lambda s: random.choice([s.upper(), s.lower(), f" {s}", f"{s}  "]))

for col, frac, seed in [("category", 0.04, 4), ("region", 0.05, 5), ("state", 0.04, 6), ("customer_name", 0.03, 7)]:
    pick, values = messy(df[col], frac, seed)
    df.loc[pick, col] = values
pick = df.sample(frac=0.02, random_state=8).index
df.loc[pick, "product_name"] = df.loc[pick, "product_name"] + " "

# dates: about 5% are in DD/MM/YYYY format
df["order_date"] = [d.strftime("%d/%m/%Y") if random.random() < 0.05 else d.strftime("%Y-%m-%d")
                    for d in df["order_date"]]

# exact duplicate rows
df = pd.concat([df, df.sample(n=40, random_state=9)]).sort_values(["order_id", "product_id"]).reset_index(drop=True)

df.to_csv(OUT_FILE, index=False)
print("raw rows written:", len(df), "->", OUT_FILE)
