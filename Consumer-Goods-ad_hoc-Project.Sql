1.Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.

Query:
	SELECT DISTINCT market 
	FROM dim_customer
	WHERE customer="Atliq Exclusive" AND region="APAC";


------------------------------------------------------------------------------------------------------------------------------------------------------

2.What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg.

Query:
	WITH unique_2020 AS(
			SELECT count(DISTINCT p.product_code) AS unique_product_2020
		FROM fact_sales_monthly s
		JOIN dim_product p ON
		p.product_code=s.product_code
		WHERE fiscal_year=2020),
	unique_2021 AS(
		SELECT count(DISTINCT p.product_code) AS unique_product_2021 
		FROM fact_sales_monthly s
		JOIN dim_product p ON
		p.product_code=s.product_code
		WHERE fiscal_year=2021)
	SELECT *,
		round(((unique_product_2021-unique_product_2020)/unique_product_2020)*100,2) as percentage_chg 
	    FROM unique_2020,unique_2021

---------------------------------------------------------------------------------------------------------------------------------------------------

3.Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count.

Query:
	SELECT segment,count(DISTINCT product_code) AS product_count 
	FROM dim_product
	GROUP BY segment
	ORDER BY product_count DESC

---------------------------------------------------------------------------------------------------------------------------------------------------

4.Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference.

Query:
	WITH product_2020 AS(
		SELECT p.segment,count(DISTINCT p.product_code) AS product_count_2020
		FROM dim_product p
		JOIN fact_sales_monthly s
		ON p.product_code=s.product_code
		WHERE fiscal_year=2020
		GROUP BY segment
		ORDER BY product_count_2020 DESC),
	product_2021 AS(
		SELECT p.segment,count(DISTINCT p.product_code) AS product_count_2021
		FROM dim_product p
		JOIN fact_sales_monthly s
		ON p.product_code=s.product_code
		WHERE fiscal_year=2021
		GROUP BY segment
		ORDER BY product_count_2021 DESC)
	SELECT a.segment,
		   a.product_count_2020,
	       	b.product_count_2021,
		   b.product_count_2021-a.product_count_2020 AS diff,
	round(((b.product_count_2021-a.product_count_2020)/a.product_count_2020)*100,2) 
	FROM product_2020 a 
	JOIN product_2021 b
	ON a.segment=b.segment

---------------------------------------------------------------------------------------------------------------------------------------------------

5.Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost.

Query:
	SELECT p.product,
		   p.product_code,
	       manufacturing_cost
	FROM fact_manufacturing_cost m 
	JOIN dim_product p
	ON p.product_code=m.product_code
	WHERE manufacturing_cost=(
	SELECT max(manufacturing_cost) FROM fact_manufacturing_cost)
	UNION
	SELECT p.product,
		   p.product_code,
		   manufacturing_cost
	FROM fact_manufacturing_cost m 
	JOIN dim_product p
	ON p.product_code=m.product_code
	WHERE manufacturing_cost=(SELECT min(manufacturing_cost) FROM fact_manufacturing_cost)

---------------------------------------------------------------------------------------------------------------------------------------------------

6.Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage.

Query:
	SELECT c.customer_code,
		   c.customer,
		   round(AVG(pre.pre_invoice_discount_pct)*100,2) AS average_discount_pct
	FROM fact_sales_monthly s
	JOIN dim_customer c
	ON s.customer_code=c.customer_code
	JOIN fact_pre_invoice_deductions pre
	ON s.customer_code=pre.customer_code 
	AND s.fiscal_year=pre.fiscal_year
	WHERE s.fiscal_year=2021 AND c.market="India"
	GROUP BY c.customer,c.customer_code
	ORDER BY  average_discount_pct DESC
	LIMIT 5

---------------------------------------------------------------------------------------------------------------------------------------------------

7.Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount.

Query:
	SELECT  month(date) as month,
			year(date) as year,
			sum(s.sold_quantity*g.gross_price) AS gross_sales_amount
	FROM fact_sales_monthly s 
	JOIN dim_customer c
	ON c.customer_code=s.customer_code
	JOIN fact_gross_price g
	ON g.fiscal_year=s.fiscal_year AND
	g.product_code=s.product_code
	WHERE c.customer="Atliq Exclusive"
	GROUP BY month,year
	ORDER BY year

8.In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity.

Query:
	SELECT CASE
	WHEN month(date) in(9,10,11) THEN 'Q1'
	WHEN month(date) in(12,1,2) THEN 'Q2'
	WHEN month(date) in(3,4,5) THEN 'Q3'
	WHEN month(date) in(6,7,8) THEN 'Q4'
	END AS quater,sum(sold_quantity) AS total_sold_quantity 
	FROM fact_sales_monthly
	WHERE fiscal_year=2020
	GROUP BY quater
	ORDER BY total_sold_quantity DESC

---------------------------------------------------------------------------------------------------------------------------------------------------

9.Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage.

Query:
	WITH gross_sale AS(
			SELECT channel,
		round(sum(sold_quantity*gross_price)/1000000,2) AS gross_sales_mln
	FROM fact_sales_monthly s
	JOIN dim_customer c
	ON c.customer_code=s.customer_code
	JOIN fact_gross_price g
	ON g.product_code=s.product_code 
	AND g.fiscal_year=s.fiscal_year
	WHERE s.fiscal_year=2021
	GROUP BY channel
	ORDER BY gross_sales_mln DESC)
	SELECT *,
		   gross_sales_mln*100/sum(gross_sales_mln) over() AS pct 
	       FROM gross_sale
       
---------------------------------------------------------------------------------------------------------------------------------------------------


10.Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order

Query:
	WITH total_sold AS(SELECT 
			p.division,
		p.product_code,
			p.product,
		sum(s.sold_quantity) AS total_quantity
	FROM fact_sales_monthly s
	JOIN dim_product p
	ON s.product_code=p.product_code
	WHERE fiscal_year=2021
	GROUP BY division,product,product_code),
	ct2 AS(
			SELECT *,
			rank() over(partition by division ORDER BY total_quantity DESC) as rnk
	FROM total_sold)
	SELECT * FROM ct2 WHERE  rnk<=3
	LIMIT 9



