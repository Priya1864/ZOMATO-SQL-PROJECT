# Zomato Food Delivery SQL Project

This project presents a comprehensive SQL-based analysis of a food delivery platform modeled on Zomato. It includes a complete dataset and a series of SQL queries to extract actionable insights across customers, restaurants, riders, deliveries and orders.


# Project Description:
This project simulates a real-world food delivery system (inspired by Zomato/Swiggy) with over of data across multiple relational tables. Using advanced SQL queries, we perform business-critical analysis to uncover key metrics such as customer lifetime value, cancellation trends, restaurant growth, rider performance, seasonal trends, and more.

# Database Schema:
customers: customer_id, customer_name, reg_date

restaurants: restaurant_id, restaurant_name, city, opening_hours

riders: rider_id, rider_name, signupdate

orders: order_id, customer_id, restaurant_id, order_item, order_date, order_time, order_status, total_amount

deliveries: delivery_id, delivery_status, order_id, delivery_time, rider_id



# Key SQL Insights

###  Customer Analysis
- Top 5 most ordered dishes by customers in the last year
- High-value customers (spent > ₹1000)
- Churned customers from 2023 to 2024

###  Order Trends
- Order trends by 2-hour slots
- Most ordered dishes city-wise
- Monthly order trend & % change

###  Rider Performance
- Average delivery time per rider
- Monthly earnings (8% of order total)
- Rider ratings based on delivery time

### Restaurant & Item Insights
- Top restaurants per city by order volume
- Seasonal dish popularity
- Monthly restaurant growth ratio

###  Segmentation & Lifetime Value
- Segment customers into Gold/Silver based on spend
- Calculate Customer Lifetime Value (CLV)

---

##  Optimization
- Indexing applied on key columns for query performance
- Used `CTEs`, `Window Functions`, `GROUP BY`, `HAVING`, and `CASE` logic for complex calculations

# Recommendations

-  **Retarget Churned Customers**: Offer discounts to customers inactive for 3+ months.
- **Rider Training Programs**: Train slower riders to improve delivery speed and satisfaction.
-  **Menu Optimization**: Highlight top-selling dishes during peak hours and promote combos.
-  **Loyalty Program**: Launch tiered rewards (Gold/Silver) based on customer spending.
- **Expand in Top Cities**: Focus marketing efforts in high-growth cities like Bangalore and Hyderabad.

# Conclusion
This project demonstrates the use of SQL for conducting detailed operational and customer analytics in a food delivery business scenario. The structured insights support data-driven decisions to improve customer retention, delivery efficiency, and revenue growth.


## Contact

**Name**: [PRIYA]  
**Email**: [PRIYAPRIYA72884@GMAIL.COM]  

> ⭐ Star the repo if you like it and want more real-time SQL projects


# This project is created for educational and portfolio purposes only. All data used is synthetically generated.

