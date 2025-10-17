select * from walmart;

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

-- Business Problems
-- 1. Find the different payment method and no. of transactions, no. of qty sold
select payment_method, count(*) no_of_payments, sum(quantity) no_of_qty_sold
from walmart
group by payment_method
order by no_of_payments desc;

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

-- 4. Calculate the total quantity of items sold per payment_method, list payment_method
-- and total_quantity
select payment_method, sum(quantity) no_of_qty_sold
from walmart
group by payment_method
order by no_of_qty_sold desc;

-- 5. Determine the average, minimum and maximum rating of category for each city,
-- list the city, avg_rating, min_rating and max_rating
select city, category, avg(rating) avg_rating, min(rating) min_rating, max(rating) max_rating
from walmart
group by city, category;

-- 6. Calculate the total profit for each category by considering total_profit as
-- (unit_price * quantity * profit_margin), list category and total_profit, ordered from 
-- highest to lowest
select category, sum(total) total_revenue,
sum(total * profit_margin) total_profit
from walmart
group by category
order by total_profit desc;

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