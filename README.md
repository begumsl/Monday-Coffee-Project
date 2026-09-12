# Monday Coffee Expansion SQL Project
## Project Note 
The dataset and business questions in this project are based on the
Zero Analyst YouTube video (https://www.youtube.com/watch?v=ZZEP4ZRnDaU&t=4826s). The original solutions were written in
PostgreSQL. I independently rewrote and adapted all queries in T-SQL
(SQL Server) to practice SQL Server syntax and problem-solving.

## Objective
The goal of this project is to analyze the sales data of Monday Coffee, a company that has been selling its products online since January 2023, and to recommend the top three major cities in India for opening new coffee shop locations based on consumer demand and sales performance.

# Key Questions
1. Coffee Consumers Count  
How many people in each city are estimated to consume coffee, given that 25% of the population does?

2. Total Revenue from Coffee Sales  
What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

3. Sales Count for Each Product  
How many units of each coffee product have been sold?

4. Average Sales Amount per City  
What is the average sales amount per customer in each city?

5. City Population and Coffee Consumers  
Provide a list of cities along with their populations and estimated coffee consumers.

6. Top Selling Products by City  
What are the top 3 selling products in each city based on sales volume?

7. Customer Segmentation by City  
How many unique customers are there in each city who have purchased coffee products?

8. Average Sale vs Rent  
Find each city and their average sale per customer and average rent per customer

9. Monthly Sales Growth  
Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

10. Market Potential Analysis  
Identify top 3 cities based on highest sales, return city name, total sales, total rent, total customers, estimated  coffee consumers

# Recommendations
After analyzing the data, the recommended top three cities for new store openings are:

**City 1) Delhi**
1. Highest estimated coffee consumers, 7.75 m.
2. Second highest total number of customers, which is 68.
3. Average rent per customer is 330.

**City 2) Pune**
1. Highest total revenue, 1.2m.
2. Highest average sales per customer, which is 24k.
3. Average rent per customer is 294.

**City 3) Chennai**
1. Second highest total revenue, 944k.
2. Second highest average sales per customer, which is 22k.
3. Average rent per customer is 407.

# Approach & Challenges
1. Initially used ROUND, but switched to CAST( ... AS DECIMAL(10,2)) because the goal was to make the output more readable by displaying the result with two decimal places.
2. Initially used DECIMAL(5,2), but received an overflow error because the calculated value exceeded the range allowed by the data type. Changed it to DECIMAL(10,2) to provide a larger range for the result.
3. Initially used INNER JOIN, but switched to LEFT JOIN after reviewing the question:  every product should be included, even if it has no sales. This allows products with zero sales to appear in the result.
4. DISTINCT used because the metric is based on unique customers: a customer with multiple purchases should still be counted only once.
5. Used CTEs to separate calculation steps, making multiple metrics easier to compare and keeping the query organized.
6. Used DENSE_RANK() to handle ties when ranking the top-selling products by city, ensuring products with the same sales count receive the same rank.
















