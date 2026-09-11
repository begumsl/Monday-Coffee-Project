
----Q1 : Cofee Consumers Count 
--How many people in each city are estimated to consume coffee, given that 25% of the population does?
-- CAST to DECIMAL used instead of ROUND because the goal here
-- is to display the calculated value with a fixed 2-decimal precision

select city_name,
cast((population*0.25)/1000000 as decimal(10,2))
as coffee_consumers_in_millions
from city
order by coffee_consumers_in_millions desc


----Q2: Total Revenue from Coffee Sales
--What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
--First calculated total revenue for Q4 2023 across all cities

select sum(total) as total_revenue
from sales
where year(sale_date) = 2023 and
DATEPART(q,sale_date) =4

--Then broke the same metric down by city to compare city-level performance
select ci.city_name, 
	sum(s.total) as total_sale 
from sales s 
inner join customers cu on cu.customer_id = s.customer_id
inner join city ci on ci.city_id=cu.city_id
where year(s.sale_date) = 2023 and
DATEPART(q,s.sale_date) =4
group by ci.city_name
order by total_sale desc


----Q3: Sales Count for Each Product
-- How many units of each coffee product have been sold?

-- Using LEFT JOIN instead of INNER JOIN: some products may have zero sales,
-- and we still want them to appear in the result (with a count of 0),
-- rather than being dropped from the output entirely

select  p.product_name,
		count(s.sale_id) as total_orders
from products p 
left join sales s 
on p.product_id=S.product_id
group by p.product_name


----Q4: Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- Step 1: total sales per city
-- Step 2: unique customer count per city (COUNT(DISTINCT customer_id) used because the metric is calculated per customer:
-- a customer with multiple purchases should still be counted only once)
-- Step 3: average sale per customer = total sales / customer count

select  ci.city_name, 
		sum(s.total) as total_sale ,
		count(Distinct s.customer_id) as customer_count,
		Cast(sum(s.total) /count(Distinct s.customer_id) as decimal(10,2) ) as avg_sale_pr
from sales s 
inner join customers cu on cu.customer_id = s.customer_id
inner join city ci on ci.city_id=cu.city_id
group by ci.city_name
order by total_sale desc


----Q5:City Population and Coffee Consumers
--Provide a list of cities along with their populations and estimated coffee consumers.

--CTEs used to separate the city-level calculations and keep the final query readable
--The first CTE calculates estimated coffee consumers,
--while the second calculates unique customers per city

with city_table as
(
	select city_name,
		cast((population*0.25)/1000000 as decimal(5,2))as coffee_cons_mil
	from city
),
customers_table
as
(
	select ci.city_name,
		count(Distinct s.customer_id) as unique_customer
	from sales s 
	inner join customers cu on s.customer_id= cu.customer_id
	inner join city ci on cu.city_id=ci.city_id
	group by ci.city_name
)

select
	ci.city_name,
	ci.coffee_cons_mil,
	cu.unique_customer

from city_table ci
join customers_table cu
on ci.city_name=cu.city_name


----Q6: Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?

-- Used DENSE_RANK() instead of RANK() or ROW_NUMBER():
--DENSE_RANK() used to keep products with tied sales counts at the same rank without skipping rank numbers
--ROW_NUMBER() would arbitrarily break ties,
--while RANK() would leave gaps after tied ranks
with tbl 
as 
(
select  city_name,
		p.product_name,
		count(s.product_id) as prodct_count,
		DENSE_RANK() over (partition by city_name order by count(s.product_id) desc)as product_rank
from sales s 
inner join customers cu on cu.customer_id = s.customer_id
inner join city ci on ci.city_id=cu.city_id
inner join products p on p.product_id=s.product_id

group by city_name ,product_name
)
select * from tbl
where product_rank<=3



----Q7: Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?
--Filtered to coffee products only because the products table also contains non-coffee items such as cups and thermoses

select  ci.city_name,
		count(Distinct cu.customer_id) as unique_cx
from city ci
inner join customers cu on ci.city_id= cu.city_id
inner join sales s on cu.customer_id= s.customer_id
inner join products p on p.product_id= s.product_id
where s.product_id<=14
group by city_name


----Q8: Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer

-- Wrapped the calculation in a CTE to keep the final SELECT clean and readable,  rather than nesting the aggregation directly into the outer query
-- COUNT(DISTINCT cu.customer_id) used because the metric is per-customer: a customer with multiple purchases must still be counted once
-- INNER JOINs used deliberately to include only cities with customers and sales, since the analysis focuses on cities with actual sales activity.

with tbl1
as(
select city_name,estimated_rent,
	sum(s.total)as total_sale,
	count(Distinct cu.customer_id) as unique_cx,
	cast(sum(s.total)/count(Distinct cu.customer_id)as decimal(10,2)) as avg_sale_prsn,
	cast(estimated_rent/count(Distinct cu.customer_id)as decimal(10,2)) as avg_rent
from city ci
inner join customers cu on ci.city_id=cu.city_id
inner join sales s on s.customer_id=cu.customer_id
group by city_name,estimated_rent
)
select city_name,avg_sale_prsn,avg_rent
from tbl1
order by avg_sale_prsn desc


----Q9: Monthly Sales Growth
--Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

-- CTEs used to keep the different calculation steps separate and make the final SELECT cleaner
-- FORMAT() used to convert sale_date into a YYYY-MM format, allowing sales to be grouped by month
-- LAG() used to compare the current month's sales with the previous month's sales and calculate the percentage increase or decrease
-- Rows with NULL previous-month values excluded since there is no previous month to compare

with monthly_sale as
(
	select city_name,
	Format(s.sale_date, 'yyyy-MM')as date,
	sum(s.total) as total_sale
	from sales s
	inner join customers cu on cu.customer_id=s.customer_id
	inner join city ci on ci.city_id=cu.city_id
	group by city_name,Format(s.sale_date, 'yyyy-MM')
),
prev_sale
as
(
	select * ,
			LAG(total_sale,1) Over (partition by city_name order by date)as prev_month_sale
	from monthly_sale
)
select *,
cast((total_sale-prev_month_sale)/prev_month_sale*100 as decimal(10,2))as monthly_growth_ratio
from prev_sale
where prev_month_sale is not null



----Q10: Market Potential Analysis
--Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

with avg_city
as(
	select ci.city_name,ci.estimated_rent,
	sum(s.total)as total_sale,
	count(Distinct cu.customer_id) as unique_cx,
	cast(sum(s.total)/count(Distinct cu.customer_id)as decimal(10,2)) as avg_sale_prsn,
	cast(estimated_rent/count(Distinct cu.customer_id)as decimal(10,2)) as avg_rent
from city ci
inner join customers cu on ci.city_id=cu.city_id
inner join sales s on s.customer_id=cu.customer_id
group by ci.city_name,ci.estimated_rent
),

city_rent
as 
	(select city_name,
	estimated_rent,
	cast((population*0.25)/1000000 as decimal(5,2))as estimated_coffee_consumer_in_mil
	from city

)

select  c.city_name,
		c.total_sale as total_revenue,
		c.estimated_rent as total_rent,
		c.unique_cx as total_customers,
		r.estimated_coffee_consumer_in_mil,
		c.avg_sale_prsn,
		c.avg_rent


from city_rent r join avg_city c
on r.city_name=c.city_name
order by total_revenue desc


/*
------RECOMMENDATION-----

City 1) DELHI
		Highest estimated coffee cunsomers 7.75 million. 
		Second highest total number of customers, which is 68
		Average rent per customer is 330 

City 2) PUNE
		Highest total revenue  1.2m
		Highest average sales per customer, which is 24k
		Average rent per customer is 294

City 3) CHENNAI
		Second highest total revenue, 944k
		Second highest average sales per customer, which is 22k 
		Average rent per customer is 407

*/