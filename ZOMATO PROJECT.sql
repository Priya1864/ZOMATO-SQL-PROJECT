drop table if exists deliveries ;
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    reg_date DATE
);
CREATE TABLE restaurants (
    restaurant_id INT PRIMARY KEY,
    restaurant_name VARCHAR(100),
    city VARCHAR(50),
    opening_hours VARCHAR(20)
);
CREATE TABLE riders (
    rider_id INT PRIMARY KEY,
    rider_name VARCHAR(100),
    signupdate DATE
);
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    restaurant_id INT,
    order_item VARCHAR(100),
    order_date DATE,
    order_time TIME,
    order_status VARCHAR(20),
    total_amount DECIMAL(10, 2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
);


CREATE TABLE deliveries (
    delivery_id INT PRIMARY KEY,
    delivery_status VARCHAR(20),
    order_id INT,
    delivery_time TIME,
    rider_id INT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (rider_id) REFERENCES riders(rider_id)
);
select*from orders;
select*from customers;
select*from deliveries;
select*from riders;
select*from restaurants;

--EDA
select count(*) from restaurants
where city is null or restaurant_name is null or opening_hours is null;

select count(*)  from orders 
where order_date is null
or order_time is null or  total_amount is null or order_status is null;


create index orderscustomerid on orders(customer_id);
create index orderrestaurantid on  orders(restaurant_id);
create index ordersorderdate on orders(order_date);
create index ordersordertime on orders(order_time);

--write query to find the top 5 most frequently ordered dishes by customer called "name" in the last 1 year
select*from(select  o.customer_id,c.customer_name,order_item as dishes ,count(*) as orders ,dense_rank() over(order by count(*) desc) as rank from orders o
join customers c
on o.customer_id=c.customer_id
where   order_date>current_date -interval '1 year' and customer_name='Karan Naidu'
group by 1,2,3
order by 1,4 desc)t
where rank<=2;

---time solts which hour most oreder placed by -2 hours'
select  floor(extract(hour from order_time)/2)as timesolt,
floor(extract(hour from order_time)/2)*2  as starttime,floor(extract(hour from order_time)/2)*2+2 as endtime,
count(*) as orders from orders
group by 1,2,3
order by 4 desc;



----order value analysis
--find the avg order value per customer who as placed more than 40 orders
select  customer_id,avg(total_amount) avgcustomer ,count(order_id) orders 
from orders o
group by 1
having count(*)>40;





---highvalue customers
--list the customers who have spent more than 1k in total on food orders
select customer_name,order_item,count(*) as orders ,sum(total_amount) as totalspent from orders o
join customers c on c.customer_id=o.customer_id
group by 1,2
having sum(total_amount)>1000;


--orders without delivery
---write querey to find orders that were placed but not delivered 
select restaurant_name,count(o.order_id) as orders from orders o
left join restaurants r on o.restaurant_id=r.restaurant_id
left join deliveries d
on d.order_id=o.order_id
where d.delivery_id is null
group by 1;


select *from orders o 
left join restaurants r
on o.restaurant_id=r.restaurant_id
where o.order_id not in(select order_id from deliveries );


--find the city wise orders and restaurant_name
select*from(select*,dense_rank() over(partition by city order by orders desc ) ran  from(select city,restaurant_name,count(*) as orders from orders o
join restaurants t
on t.restaurant_id=o.restaurant_id
join customers c
on c.customer_id=o.customer_id
group by 1,2
order by 3 desc)t)m
where ran=1;



----find city wise restaurant and revenue based top 5 city
select*from(select *,rank() over(order by  revenue desc) as ran from(select city,restaurant_name,sum(total_amount) as revenue from orders o
join restaurants r
on o.restaurant_id=r.restaurant_id
join customers c
on c.customer_id=o.customer_id
group by 1,2
order by 3 desc) t)m
where ran<=5;


--most popular dish in city
select*from(select*,dense_rank() over(partition by city order by orders desc ) as ran from(select city,order_item ,count(o.order_id) as orders from customers c
left join orders o
on o.customer_id=c.customer_id
join restaurants r
on o.restaurant_id=r.restaurant_id
group by 1,2
order by 1,3 desc)t)m
where ran=1;


--find customers who havent placed order in 2024 but did in 2023
select  distinct customer_id  from orders o
where extract(year from order_date)=2023 and customer_id not in(select  distinct customer_id from orders where extract(year from order_date)=2024);


---calcualate and compare the order cancellation rate for restaurants betwwen the current_year and previous year


WITH orders_by_year AS (
    SELECT 
        r.restaurant_name,
        EXTRACT(YEAR FROM o.order_date) AS order_year,
        COUNT(*) FILTER (WHERE o.order_status = 'Cancelled') AS cancel_orders,
        COUNT(*) AS total_orders
    FROM orders o
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.restaurant_name, EXTRACT(YEAR FROM o.order_date)
),
cancellation_rate AS (
    SELECT 
        restaurant_name,
        order_year,
        ROUND((cancel_orders::numeric / total_orders) * 100, 2) AS cancellation_rate
    FROM orders_by_year
)
SELECT 
    curr.restaurant_name,
    curr.cancellation_rate AS current_year_rate,
    prev.cancellation_rate AS previous_year_rate,
    ROUND(curr.cancellation_rate - prev.cancellation_rate, 2) AS rate_difference
FROM cancellation_rate curr
JOIN cancellation_rate prev
  ON curr.restaurant_name = prev.restaurant_name
WHERE curr.order_year = EXTRACT(YEAR FROM CURRENT_DATE)
  AND prev.order_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1;




---determine each riders avg delivery time
SELECT 
    d.rider_id,
    r.rider_name,
    ROUND(AVG(EXTRACT(EPOCH FROM d.delivery_time - o.order_time) / 60), 2) AS avg_delivery_time_minutes
FROM deliveries d
JOIN riders r ON r.rider_id = d.rider_id
JOIN orders o ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered'
GROUP BY d.rider_id, r.rider_name;




---monthly restaurant growthratio
--calculate each restaurants growth ratio based on the total number of delivered orders since its joining
--cs-ls/ls*100
WITH growthratio AS (
    SELECT  
        restaurant_id,
        TO_CHAR(order_date, 'MM-YY') AS month,
        COUNT(*) AS currentorders,
        LAG(COUNT(*), 1) OVER (
            PARTITION BY restaurant_id 
            ORDER BY TO_CHAR(order_date, 'MM-YY')
        ) AS prev_month_orders
    FROM orders o
    JOIN deliveries d ON o.order_id = d.order_id
    WHERE order_status = 'Delivered'
    GROUP BY 1, 2
    ORDER BY 1, 2
)
SELECT *, 
    ROUND(
        ((currentorders::numeric - prev_month_orders::numeric) / prev_month_orders::numeric) * 100.0,
        2
    ) AS pct
FROM growthratio;



--current segementations
--customer segemenattion segement customers into 'gold' or silver groups based on therir total spending 
--compared to the avg order value .if a customer total spending exceeds the avv,
--label them as gold othervise label them as silver write an sql query to determine each segments 
--total no of orders and total revenue
select falg,sum(total_orders) as orders,sum(total_spending) asrevenue 
from(SELECT customer_id, 
        SUM(total_amount) AS total_spending,
        COUNT(*) AS total_orders,case when sum(total_amount)>( SELECT AVG(total_amount) AS avg_value FROM orders)  then 'Gold' else 'silver'
        end as falg
       FROM orders
       GROUP BY customer_id)
	   group by 1;


---rider monthly earnings
--calculate each riders total monthly earnings ,
--assuming they earn 8% of the order amount
SELECT 
    d.rider_id,
    TO_CHAR(o.order_date, 'YYYY-MM') AS month,
    ROUND(SUM(o.total_amount * 0.08), 2) AS total_earnings
FROM riders r
JOIN deliveries d ON d.rider_id = r.rider_id
JOIN orders o ON d.order_id = o.order_id
WHERE o.order_status = 'Delivered'  -- optional, if you only want completed deliveries
GROUP BY d.rider_id, TO_CHAR(o.order_date, 'YYYY-MM')
ORDER BY d.rider_id, month;



---rider rating analysis
--find the no of 5 star ,4star,and 3 star ratings each rider has.
--riders recieve this rating bsed on delivery time
--if orders are delivered less than 15 min of orders received time the rider .get 5 star rating
--if they deliver 15 and 20 minute they get 4 star rating
---if they deliver after 20 minutes they get 3 star rating
SELECT 
    d.rider_id,
    o.order_date,
    o.order_time,
    d.delivery_time,
    ROUND(EXTRACT(EPOCH FROM (
        (o.order_date + d.delivery_time) - (o.order_date + o.order_time)
    )) / 60, 2) AS delivery_minutes,
    CASE 
        WHEN EXTRACT(EPOCH FROM (
            (o.order_date + d.delivery_time) - (o.order_date + o.order_time)
        )) / 60 < 15 THEN '5 Star'
        WHEN EXTRACT(EPOCH FROM (
            (o.order_date + d.delivery_time) - (o.order_date + o.order_time)
        )) / 60 BETWEEN 15 AND 20 THEN '4 Star'
        ELSE '3 Star'
    END AS rating
FROM deliveries d
JOIN orders o ON d.order_id = o.order_id
WHERE o.order_status = 'Delivered'
ORDER BY d.rider_id, o.order_date, o.order_time;


---order frequency by day
--analyze order frequnecy per day of the week and identify the peak day for each restaurant
SELECT *
FROM (
    SELECT 
        o.restaurant_id,
        r.restaurant_name,
        TO_CHAR(o.order_date, 'FMDay') AS peak_day,
        COUNT(*) AS order_count,
        DENSE_RANK() OVER (
            PARTITION BY o.restaurant_id 
            ORDER BY COUNT(*) DESC
        ) AS rank
    FROM orders o
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    GROUP BY o.restaurant_id, r.restaurant_name, TO_CHAR(o.order_date, 'FMDay')
) t
WHERE rank = 1
ORDER BY order_count DESC;



---customer lifetime value
--calculated the total revenue generated by each customer over all their orders
select o.customer_id,customer_name,sum(total_amount) as revenue ,count(*) as orders from orders o
left  join customers c
on  o.customer_id=c.customer_id
group by 1,2
order by 3 desc;


---monthly sales trends 
--identify sales trends by comparing each monthds total sales to the previous month
WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(total_amount) AS total_sales
    FROM orders
    GROUP BY 1
),
sales_with_change AS (
    SELECT 
        month,
        total_sales,
        LAG(total_sales) OVER (ORDER BY month) AS prev_month_sales,
        LAG(month) OVER (ORDER BY month) AS prev_month_date,
        ROUND(
            CASE 
                WHEN LAG(total_sales) OVER (ORDER BY month) IS NOT NULL 
                     AND LAG(total_sales) OVER (ORDER BY month) != 0
                THEN ((total_sales - LAG(total_sales) OVER (ORDER BY month)) / LAG(total_sales) OVER (ORDER BY month)) * 100
                ELSE NULL
            END, 2
        ) AS pct_change
    FROM monthly_sales
)
SELECT 
    TO_CHAR(month, 'Mon-YYYY') AS month,
    total_sales,
    TO_CHAR(prev_month_date, 'Mon-YYYY') AS prev_month,
    prev_month_sales,
    pct_change
FROM sales_with_change
ORDER BY month;




---rider effeciency

--evaluate rider effeciency by determining avg delivery times and identifying those with the lowest and highest avg
SELECT 
    d.rider_id,
    ROUND(
        AVG(
            CASE 
                WHEN d.delivery_time >= o.order_time THEN 
                    EXTRACT(EPOCH FROM (d.delivery_time - o.order_time)) / 60
                ELSE 
                    NULL  -- ignore bad data where delivery is before order
            END
        ), 
        2
    ) AS avg_delivery_minutes
FROM deliveries d
JOIN orders o ON d.order_id = o.order_id
GROUP BY d.rider_id
ORDER BY avg_delivery_minutes;




---track the populartity of specific order items over time and identify seasonal demand spikes
WITH item_seasonal AS (
    SELECT 
        order_item,
        EXTRACT(YEAR FROM order_date) AS year,
		EXTRACT(month FROM order_date) as month,
        CASE 
            WHEN EXTRACT(MONTH FROM order_date) IN (12, 1, 2) THEN 'Winter'
            WHEN EXTRACT(MONTH FROM order_date) IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(MONTH FROM order_date) IN (6, 7, 8) THEN 'Summer'
            WHEN EXTRACT(MONTH FROM order_date) IN (9, 10, 11) THEN 'Fall'
        END AS season,
        COUNT(*) AS total_orders
    FROM orders
    GROUP BY order_item, year,month, season
)
SELECT 
    order_item,
    year,
	month,
    season,
    total_orders
FROM item_seasonal
ORDER BY order_item, year, season;





--monthly restaurant growth ratio
--calaculate each restuarnats growth ratio based on the total no of delivered orders since its joining
WITH monthly_orders AS (
    SELECT
        r.restaurant_id,
        r.restaurant_name,
        DATE_TRUNC('month', o.order_date) AS month,
        COUNT(*) AS orders
    FROM restaurants r
    JOIN orders o ON o.restaurant_id = r.restaurant_id
    WHERE o.order_status = 'Delivered'
    GROUP BY r.restaurant_id, r.restaurant_name, DATE_TRUNC('month', o.order_date)
),
growth_calc AS (
    SELECT
        restaurant_id,
        restaurant_name,
        month,
        orders,
        LAG(orders) OVER (PARTITION BY restaurant_id ORDER BY month) AS prev_month_orders,
        CASE 
            WHEN LAG(orders) OVER (PARTITION BY restaurant_id ORDER BY month) IS NULL THEN NULL
            WHEN LAG(orders) OVER (PARTITION BY restaurant_id ORDER BY month) = 0 THEN NULL
            ELSE ROUND(((orders - LAG(orders) OVER (PARTITION BY restaurant_id ORDER BY month))::NUMERIC / LAG(orders) OVER (PARTITION BY restaurant_id ORDER BY month)) * 100, 2)
        END AS growth_ratio_pct
    FROM monthly_orders
)
SELECT 
    restaurant_name,
    TO_CHAR(month, 'Mon-YYYY') AS month,
    orders,
    prev_month_orders,
    growth_ratio_pct
FROM growth_calc
ORDER BY restaurant_name, month;




--rank each city based on total revenue for lastyear 2023
SELECT 
    city,
    revenue,
    RANK() OVER (ORDER BY revenue DESC) AS city_rank
FROM (
    SELECT 
        r.city as city,s
        SUM(o.total_amount) AS revenue
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    JOIN restaurants r ON r.restaurant_id = o.restaurant_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2023
    GROUP BY r.city
) t
ORDER BY city_rank;


