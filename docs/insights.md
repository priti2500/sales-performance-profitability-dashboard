# Insights

All numbers come from `sql/analysis_queries.sql` (query number in brackets) run on the cleaned data: 3,739 order lines, Jan 2024 to Dec 2025. The data is generated for practice, so these are findings about this dataset, not a real company.

## Overall

| KPI | Value |
|---|---|
| Total sales | ₹14,738,904 (about ₹1.47 crore) |
| Total profit | ₹2,871,113 (about ₹28.7 lakh) |
| Profit margin | 19.5% |
| Total orders | 2,569 |
| Unique customers | 686 |
| Average order value | ₹5,737 |

## 1. Sales grew 15.4% in 2025, but profit grew only 4.7% (24, 25, 26)

Orders went up 10.9% and margin dropped from 20.5% to 18.6%. Discounts were not the reason, because the average discount was about the same (11.7% in 2024, 11.3% in 2025). The growth mostly came from low-margin categories: Furniture sales grew 40.2% and Electronics 12.6%, while Fashion grew 8.3% and Beauty only 0.6%. Electronics margin also fell from 11.6% to 9.2%.

## 2. Electronics is 47% of sales but only 25% of profit (10, 11)

Electronics margin is 10.3%. Laptops lost money overall (-0.5% margin) and Mobiles made only 4.2%. Furniture is similar, with 19.9% of sales and 11.7% of profit.

## 3. Fashion and Beauty are the most profitable categories (10)

Fashion is 13.5% of sales but 30.8% of profit (44.4% margin). Beauty has the highest margin at 53.0%, but it is only 4.5% of sales.

## 4. The best-selling products make very little profit (12, 14, 15)

The top 5 products by sales are all phones and laptops, with margins between 0.7% and 7.0%. Moto G64 sold ₹661,767 but made only ₹4,516. Ten products have above-average sales and less than 10% margin (8 Electronics, 2 Furniture). Three laptops lost money: Vivobook 15 (-₹20,351), HP 15s Ryzen 5 (-₹12,475) and Inspiron 3520 (-₹9,205).

## 5. Order lines with more than 20% discount lost money (21, 22)

| Discount | Margin |
|---|---|
| 0% | 29.2% |
| 1-10% | 22.1% |
| 11-20% | 13.9% |
| Above 20% | -7.0% |

120 of the 165 loss-making order lines had a discount above 20%. Above 20% discount, Electronics margin is -25.0% and Furniture is -16.6%, but Fashion (27.6%) and Beauty (37.3%) still make a good profit.

## 6. Oct-Nov has the most orders but the lowest margins (3, 23)

During Oct-Nov the store averaged 142 orders a month vs 100 in other months. The average discount was 15.8% vs 10.3%, and margin was 15.1% vs 20.6%. November 2025 had the lowest monthly margin in the data (12.6%).

## 7. Monthly sales are uneven (4, 5, 6)

Month-over-month growth ranged from -38.4% (Jan 2025) to +118.8% (May 2025). A few large laptop or furniture orders can move a month's total a lot. The highest sales month was July 2025 (₹973,900) and the lowest profit month was February 2025 (₹78,977). Monthly numbers should be read together with the trend, not one month at a time.

## 8. North sells the most, South has the best margin (7, 9)

North is 34.4% of sales. West is second (29.5%) but has the lowest margin (17.4%). South has the best margin (22.0%). Rajasthan has the lowest state margin at 8.5% on ₹929,778 of sales, while Delhi made the most profit (₹312,796, 24.6% margin).

## 9. Bihar and West Bengal are the weakest states by profit (8)

Bihar made ₹56,002 and West Bengal ₹77,608. West Bengal's margin is actually good (25.5%). It is weak because its sales are small, not because it is unprofitable.

## 10. Repeat customers bring most of the sales (17, 18, 20)

70.0% of customers ordered more than once, and they brought 91.5% of sales. The top 20% of customers brought 61.4% of sales. The top customer by sales (₹266,732 over 19 orders) made a loss of ₹19,862 for the store.

## Recommendations

These are based on this dataset only.

1. Review discounts above 20% on Electronics and Furniture. Both categories had negative margins in this range.
2. Fashion and Beauty kept good margins even above 20% discount, so they may be safer choices for big promotions.
3. For the Oct-Nov sale, compare discount levels by category instead of using the same high discount for everything.
4. Review laptop pricing and supplier costs. Laptops are a large part of sales but had a negative margin overall.
5. Check which products and discounts explain Rajasthan's low margin (8.5%).
6. Report profit and margin together with sales. In 2025, sales grew much faster than profit.
