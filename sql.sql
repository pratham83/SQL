### Q1.	Provide the list of markets in which customer "Atliq Exclusive" operates its
### business in the APAC region.

SELECT market FROM gdb023.dim_customer
where customer = "Atliq Exclusive" and region = "APAC"
group by market 
order by market ;

### Q2What is the percentage of unique product increase in 2021 vs. 2020? The
### final output contains these fields,
### unique_products_2020
### unique_products_2021
### percentage_chg



SELECT 
		AA.A as Unique_products_2020, 
        BB.B as Unique_product_2021,
        round((B-A)*100/A,2) as percentage_chg
from
(
(select count(distinct(product_code)) as A FROM gdb023.fact_sales_monthly 
where fiscal_year =2020) AA,
(select count(distinct(product_code)) as B FROM gdb023.fact_sales_monthly 
where fiscal_year =2021) BB
);


### Q3  Provide a report with all the unique product counts for each segment and
### sort them in descending order of product counts. The final output contains
### 2 fields,
### segment
### product_count

select * from dim_product;
select 
		segment,
        count(distinct(product_code)) as product_count
from dim_product
group by segment
order by product_count desc;


### Q4 Follow-up: Which segment had the most increase in unique products in
###	2021 vs 2020? The final output contains these fields,
###	segment
###	product_count_2020
###	product_count_2021
###	difference

with cte1 as(
select 	dp.segment as A,
		count(distinct fs.product_code) as B
from fact_sales_monthly fs
join dim_product dp
on fs.product_code=dp. product_code
group by dp.segment , fs.fiscal_year
having fs.fiscal_year=2020
),

 cte2 as(
select 	dp.segment as C,
		count(distinct fs.product_code) as D
from fact_sales_monthly fs
join dim_product dp
on fs.product_code=dp. product_code
group by dp.segment, fs.fiscal_year
having fs.fiscal_year= 2021
)

select cte1.A as segment,
		cte1.B as product_code_2020,
        cte2. D as product_code_2021,
        (cte2.D-cte1.B) as difference
from cte1,cte2
where cte1.A=cte2.C;

### Q5.Get the products that have the highest and lowest manufacturing costs.
### The final output should contain these fields,
### product_code
### product
### manufacturing_cost

select 
		m.product_code,
        p.product,
        m.manufacturing_cost
from fact_manufacturing_cost m
join dim_product p
on m.product_code= p.product_code
where manufacturing_cost in (
select max(manufacturing_cost) from fact_manufacturing_cost
union
select min(manufacturing_cost) from fact_manufacturing_cost
)
order by manufacturing_cost desc
;

### Q6 Generate a report which contains the top 5 customers who received an
### average high pre_invoice_discount_pct for the fiscal year 2021 and in the
### Indian market. The final output contains these fields,
### customer_code
### customer
### average_discount_percentage

with cte1 as (select customer_code as A , Avg(pre_invoice_discount_pct) as B from fact_pre_invoice_deductions
where fiscal_year = 2021 
group by customer_code),

cte2 as ( select customer_code as C, customer as  D from dim_customer
where market ="India")

select cte2.C as customer_code,
		cte2.D as cutsomer,
        round(cte1.B,4) as Average_discount_percentage
from cte1,cte2
where cte1.A= cte2.C
order by Average_discount_percentage desc
limit 5;

### Get the complete report of the Gross sales amount for the customer “Atliq
### Exclusive” for each month. This analysis helps to get an idea of low and
### high-performing months and take strategic decisions.
### The final report contains these columns:
### Month
### Year
### Gross sales Amount
with cte1 as (
select 
	monthname(s.date) as A,
    year(s.date) as B ,
    s.fiscal_year,
    (g.gross_price*s.sold_quantity) as C
from fact_sales_monthly s
join fact_gross_price g on s.product_code=g.product_code
join dim_customer c on s.customer_code=c.customer_code
where c.customer="Atliq Exclusive")

select A as month,B as Year, round(sum(C),2) as Gross_sales_amount from cte1
group by month,Year
order by year;


### Q8 In which quarter of 2020, got the maximum total_sold_quantity? The final
### output contains these fields sorted by the total_sold_quantity,
### Quarter
### total_sold_quantity

SELECT 
 case 
	when month(date) in ( 9,10,11) then "Q1"
    when month(date) in (12,1,2) then "Q2"
    when month(date) in (3,4,5) then "Q3"
    when month(date) in (6,7,8) then "Q4"
    end as Quater,
    round(sum(sold_quantity)/1000000,2) as total_sold_quantity_mln
from fact_sales_monthly
where fiscal_year=2020
group by Quater;

### Q9 Which channel helped to bring more gross sales in the fiscal year 2021
### and the percentage of contribution? The final output contains these fields,
### channel
### gross_sales_mln
### percentage

with cte1 as (
select c.channel,
		sum(s.sold_quantity*g.gross_price) as total_sales
from fact_sales_monthly s
join  fact_gross_price g on s.product_code=g.product_code
join  dim_customer c on s.customer_code=c.customer_code
where s.fiscal_year=2021
group by c.channel
)
select 
	channel,
    round(total_sales/100000,2) as gross_sales_mln,
	round((total_sales)/sum(total_sales)over() *100,2) as percentage
from cte1
order by percentage desc;


### Get the Top 3 products in each division that have a high
### total_sold_quantity in the fiscal_year 2021? The final output contains these
### fields
### division
#### product_code
### product
### total_sold_quantity
### rank_order

with cte1 as(select
		p.division,
        s.product_code,
        p.product,
        sum(s.sold_quantity) as total_sold_quantity,
        rank() over(partition by division order by sum(s.sold_quantity) desc) as rank_order 
from fact_sales_monthly s
join dim_product p on s.product_code=p.product_code
where s.fiscal_year=2021
group by p.product,division,s.product_code)

select * from cte1
where rank_order in (1,2,3);



