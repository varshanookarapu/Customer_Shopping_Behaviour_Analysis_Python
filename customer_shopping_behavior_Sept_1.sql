-- Schema --- Had to do this at first as one of my column name has closed brackets and it was throwing an error when I tried to run it and all my columns are imported as varchars so it was good to check the datatypes of the columns too.
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
	DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'customer_behaviour_cleaned';
--------------------------------------------------------------------
/*Customer Demographics */

--How many male and female customers are there in the dataset?

SELECT gender, COUNT(customer_id) as gender_count
FROM customer_behaviour_cleaned GROUP BY gender;

--What is the distribution of customers across different age groups?
SELECT age_group,COUNT(customer_id) as customer_count FROM customer_behaviour_cleaned GROUP BY age_group ORDER BY customer_count DESC

--What is the revenue contribution of each age group? */

SELECT age_group , SUM(CAST(purchase_amount_usd AS INT)) as revenue_contribution FROM customer_behaviour_cleaned$ GROUP BY age_group ORDER BY revenue_contribution DESC;

--Sales Channels & Purchasing Behaviour

--How many male and female customers purchased online vs. offline?
WITH category AS
(
SELECT CASE WHEN shipping_type ='Store Pickup' THEN 'Offline' ELSE 'Online' END AS shipping_category   ,gender, COUNT(customer_id) as customers_purchased 
FROM customer_behaviour_cleaned 
GROUP BY gender,shipping_type
)
SELECT gender,shipping_category,SUM(customers_purchased) as customers_purchased FROM category GROUP BY gender,shipping_category ORDER BY customers_purchased DESC;

--Which sales channel generates more revenue: online or offline? Answer : Online 
--Do certain demographics show a preference for online or offline shopping? -- Males show more preference for Online Shopping 

--SELECT shipping_category , SUM(customers_purchased) as customers_purchased FROM category GROUP BY shipping_category ORDER BY customers_purchased DESC


--What is the purchase frequency of customers
SELECT frequency_of_purchases, COUNT(*) as customer_count FROM customer_behaviour_cleaned GROUP BY frequency_of_purchases

--How many customers made purchases in every season?
SELECT season, COUNT(customer_id) as customer_purchase_count FROM customer_behaviour_cleaned GROUP BY season

--Which customers have the highest number of previous purchases (Top 5), and under which season, discount, promo code, and shipping type did they purchase?
SELECT customer_id, SUM(previous_purchases) as total_previous_purchases , season ,discount_applied, promo_code_used, shipping_type FROM customer_behaviour_cleaned
GROUP BY customer_id,season,discount_applied,promo_code_used,shipping_type ORDER BY total_previous_purchases DESC

--------------------------------------------------------------------
--Customer Loyalty & Subscriptions

--How many customers are New, Returning, and Loyal based on their number of previous purchases?

SELECT COUNT(CASE WHEN previous_purchases =1 THEN customer_id END) AS New,
COUNT(CASE WHEN previous_purchases  BETWEEN 2 AND 20 THEN customer_id END) AS Returning,
COUNT(CASE WHEN previous_purchases BETWEEN 21 AND 50 THEN customer_id END) AS Loyal
FROM customer_behaviour_cleaned


--Do subscribed customers spend more than non-subscribed customers based on average spend and total revenue? - even though the average spend is almost similar for both subscription types,  non subscription users spend more than subscribed
--users. 

SELECT subscription_status,COUNT(*) as customers_count, ROUND(AVG(purchase_amount_usd),2) as average_spend , SUM(purchase_amount_usd) FROM customer_behaviour_cleaned
GROUP BY subscription_status

--Are repeat buyers (more than 5 previous purchases) more likely to subscribe?

SELECT subscription_status, COUNT(customer_id) as repeat_buyers_count FROM customer_behaviour_cleaned WHERE previous_purchases > 5 
GROUP BY  subscription_status
ORDER BY subscription_status

--------------------------------------------------------------------
--Product & Category Performance

-- Which product has the most reviews, and how many customers purchased it?
SELECT  item_purchased, COUNT(DISTINCT review_rating) as review_count ,COUNT(DISTINCT customer_id) as customers_purchased FROM customer_behaviour_cleaned 
GROUP BY item_purchased
ORDER BY review_count DESC,customers_purchased ;

--What are the top 5 products with the highest average review ratings?
SELECT  DISTINCT item_purchased,category ,review_rating
FROM customer_behaviour_cleaned 
WHERE review_rating = ( SELECT ROUND(AVG(review_rating),1) FROM customer_behaviour_cleaned )
ORDER BY category,item_purchased

--What are the top 3 most purchased products within each category?
WITH top_products_cte AS
(
SELECT category, item_purchased, COUNT(DISTINCT customer_id) as customers_purchased , ROW_NUMBER() OVER(PARTITION BY category ORDER BY COUNT(customer_id) DESC) as item_ranking
FROM customer_behaviour_cleaned 
GROUP BY category ,item_purchased
)
SELECT category,item_purchased,customers_purchased,item_ranking FROM top_products_cte WHERE item_ranking <=3;

--Which 5 products have the highest percentage of purchases with discounts applied?
WITH discount As
(
 SELECT item_purchased, COUNT(*)  as purchases_with_discount_applied
 FROM customer_behaviour_cleaned
 WHERE discount_applied = 'Yes'
 GROUP BY item_purchased
 ),
 total_purchases AS
 (
SELECT item_purchased,COUNT(customer_id)  as total_purchases
FROM customer_behaviour_cleaned
GROUP BY item_purchased 
)
SELECT  TOP 5 
d.item_purchased, d.purchases_with_discount_applied,t.total_purchases, (d.purchases_with_discount_applied*100/t.total_purchases) as percentage_of_purchases_with_discount_applied
FROM discount d JOIN total_purchases t ON
d.item_purchased = t.item_purchased
ORDER BY percentage_of_purchases_with_discount_applied DESC


--------------------------------------------------------------------

--Discounts & Shipping

--Which customers used a discount but still spent more than the average purchase amount?

SELECT customer_id, SUM(purchase_amount_usd) as total_purchase_amount FROM customer_behaviour_cleaned 
WHERE discount_applied = 'Yes'
GROUP BY customer_id
HAVING SUM(purchase_amount_usd) > (SELECT ROUND(AVG(purchase_amount_usd),2) as avg_purchase_amount FROM customer_behaviour_cleaned)
ORDER BY customer_id

--What is the average purchase amount for Standard vs. Express shipping?

SELECT shipping_type , ROUND(AVG(purchase_amount_usd),2) as avg_purchase_amount FROM customer_behaviour_cleaned 
GROUP BY shipping_type
HAVING shipping_type IN ('Standard','Express')