# Walmart-sales

**1. Project Overview**  
This project performs Exploratory Data Analysis (EDA), Data Processing and Data cleaning on Walmart’s retail sales dataset using Python,  
While Core Data Analysis was performed using SQL.  
It aims to uncover trends in sales performance, branch-level operations, and customer behavior by cleaning, transforming, and preparing data for database upload.  

**2. Data Source & Structure**  

The dataset (Walmart.csv) was loaded directly into the notebook, It contains approximately 10,051 records with 11 columns.  

**PYTHON ASPECT - Exploration and Processing**  

**3. Data Cleaning & Transformation**  

Steps Performed  
Importing Dependencies  
```python
import pandas as pd
from sqlalchemy import create_engine
```

Data Loading  
```python
df = pd.read_csv("Walmart.csv", encoding_errors="ignore")
```

Removing Duplicates
```python
df.drop_duplicates(inplace=True)
```
➤ Ensures data integrity and prevents overcounting in analysis.  

Handling Missing Values  
```python
df.dropna(inplace=True)
```
➤ Removed rows with missing entries to maintain data consistency.  

Cleaning Unit Price  
```python
df["unit_price"] = df["unit_price"].str.replace("$", "").astype(float)
```
➤ Converted from string to numeric for computation.  

Feature Engineering  
```python
df["total"] = df["unit_price"] * df["quantity"]
```
➤ Added a new total column representing per-transaction revenue.  

Column Normalization  
```python
df.columns = df.columns.str.lower()
```
➤ Ensures compatibility with SQL and downstream analytics tools.  

Exporting Cleaned Data  
```python
df.to_csv("walmart_cleaned.csv", index=False)
```
➤ Cleaned dataset is stored locally for reporting or dashboard use.

**Database Connection (SQL Integration)**  
```python 
engine = create_engine(f"mysql+pymysql://{username}:{password}@{host}/{database}")
df.to_sql(name="walmart", con=engine, if_exists="append", index=False)
```
➤ Facilitates real-time data updates and scalability.  


**SQL ASPECT - Core Analysis**  


```sql
select * from walmart;
```  
![](https://github.com/XeNoX36/Walmart-sales/blob/main/walmart/data.png)

```sql
select count(*) from walmart;

select distinct payment_method, count(*) count
from walmart
group by payment_method
order by count desc;

select count(distinct Branch), Branch
from walmart
group by Branch;
-- convert all columns to lowercase from python
drop table walmart;
-- now reuse the lowercase branch
select count(distinct branch)
from walmart;

select max(quantity)
from walmart;
select min(quantity)
from walmart;
```

```sql
-- Business Problems
-- 1. Find the different payment method and no. of transactions, no. of qty sold
select payment_method, count(*) no_of_payments, sum(quantity) no_of_qty_sold
from walmart
group by payment_method
order by no_of_payments desc;
```
![](https://github.com/XeNoX36/Walmart-sales/blob/main/walmart/1.png)

```sql
-- 2. Identify the highest-rated category in each branch, displaying the branch,
-- category and Avg rating.
select *
from
	(select branch, category, avg(rating) avg_rating,
    rank() over(partition by branch order by avg(rating) desc) ranking
    from walmart
    group by branch, category
	) sub
where ranking = 1;
```
![](https://github.com/XeNoX36/Walmart-sales/blob/main/walmart/2.png)

```sql
-- 3. Identify the busiest day for each branch based on the no. of transactions.
select *
from
	(select branch, dayname(str_to_date(date, "%d/%m/%Y")) day_name,
	count(*) no_of_transactions,
	rank() over(partition by branch order by count(*)) ranking
	from walmart
	group by branch, day_name
	) sub
where ranking = 1;
```
![](https://github.com/XeNoX36/Walmart-sales/blob/main/walmart/3.png)

-- 4. Calculate the total quantity of items sold per payment_method, list payment_method
-- and total_quantity
select payment_method, sum(quantity) no_of_qty_sold
from walmart
group by payment_method
order by no_of_qty_sold desc;
![](https://github.com/XeNoX36/Walmart-sales/blob/main/walmart/4.png)

```sql
-- 5. Determine the average, minimum and maximum rating of category for each city,
-- list the city, avg_rating, min_rating and max_rating
select city, category, avg(rating) avg_rating, min(rating) min_rating, max(rating) max_rating
from walmart
group by city, category;
```
![](https://github.com/XeNoX36/Walmart-sales/blob/main/walmart/5.png)

```sql
-- 6. Calculate the total profit for each category by considering total_profit as
-- (unit_price * quantity * profit_margin), list category and total_profit, ordered from 
-- highest to lowest
select category, round(sum(total), 2) total_revenue,
round(sum(total * profit_margin), 2) total_profit
from walmart
group by category
order by total_profit desc;
```
![](https://github.com/XeNoX36/Walmart-sales/blob/main/walmart/6.png)

```sql
-- 7. Determine the most common payment_method for each branch, display branch and the
-- preferred_payment_method
select *
from
	(
	select branch, payment_method, count(invoice_id) total_transactions,
	rank() over(partition by branch order by count(invoice_id) desc) ranking
	from walmart
	group by branch, payment_method
	order by branch, total_transactions desc
	) sub
where ranking = 1;
```
![](https://github.com/XeNoX36/Walmart-sales/blob/main/walmart/7.png)

```sql
-- 8. Categorize sales into 3 group MORNING, AFTERNOON, EVENING, Find out each of the shift
-- and no. of invoices
select branch,
	case
		when hour(time(time)) < 12 then "Morning"
        when hour(time(time)) between 12 and 17 then "Afternoon"
		else "Evening"
	end time_of_day, count(*) counts
from walmart
group by branch, time_of_day
order by branch, counts desc;
```  
![](https://github.com/XeNoX36/Walmart-sales/blob/main/walmart/8.png)

```sql
-- 9. Identify 5 branch with the highest decrease ratio in revenue compare to last year
-- (current year is 2022)
with revenue_2022 as
	(select branch, sum(total) as tot_revenue
    from walmart
    where year(str_to_date(date, "%d/%m/%Y")) = 2022
    group by branch
	),
revenue_2023 as
	(select branch, sum(total) as tot_revenue
    from walmart
    where year(str_to_date(date, "%d/%m/%Y")) = 2023
    group by branch
    )
select ls.branch,
ls.tot_revenue as last_year_rev,
cs.tot_revenue as current_year_rev,
round((ls.tot_revenue - cs.tot_revenue)/ls.tot_revenue * 100, 2) percent_decrease
from revenue_2022 ls
join revenue_2023 cs
	on ls.branch = cs.branch
where ls.tot_revenue > cs.tot_revenue
order by percent_decrease desc
limit 5;
```  
![](https://github.com/XeNoX36/Walmart-sales/blob/main/walmart/9.png)
