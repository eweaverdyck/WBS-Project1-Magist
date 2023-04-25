/* 
######################################################################
BUSINESS QUESTIONS ABOUT MAGIST
######################################################################
*/

use magist;
-- ##################################################################
/*
3.1 QUESTIONS IN RELATION TO PRODUCTS
*/
-- ------------------------------------------------------------------
/*
What categories of tech products does Magist have?
*/
-- get a list of all products
SELECT DISTINCT
    product_category_name_english
FROM
    product_category_name_translation
ORDER BY product_category_name_english;

-- most relevant tech categories
SELECT 
    *
FROM
    product_category_name_translation
WHERE
    product_category_name_english IN (
    'audio' , 
	'computers',
	'computers_accessories',
	'consoles_games',
	'electronics',
	'pc_gamer',
	'signaling_and_security',
	'tablets_printing_image',
	'telephony',
	'watches_gifts')
ORDER BY product_category_name_english; 

-- -----------------------------------------------------------------------------------
/* 
How many products of these tech categories have been sold 
(within the time window of the database snapshot)? 
What percentage does that represent from the overall number of products sold? 
*/
-- overall number of products sold: 112650
SELECT 
    COUNT(*)
FROM
    order_items;

-- sales of items in most relevant tech categories: 23125
SELECT 
    COUNT(*) AS total,
    (COUNT(*) / (SELECT 
            COUNT(*)
        FROM
            order_items)) * 100 AS 'percent of all sales'
FROM
    order_items AS oi
        JOIN
    products AS pr ON oi.product_id = pr.product_id
        JOIN
    product_category_name_translation AS tr ON pr.product_category_name = tr.product_category_name
WHERE
    tr.product_category_name_english IN ('audio' , 'computers',
        'computers_accessories',
        'consoles_games',
        'electronics',
        'pc_gamer',
        'signaling_and_security',
        'tablets_printing_image',
        'telephony',
        'watches_gifts')
;

-- sales of items in most relevant tech categories by category
SELECT 
    tr.product_category_name_english AS category,
    COUNT(*) AS items_sold,
    ROUND(COUNT(*) / (SELECT 
                    COUNT(*)
                FROM
                    order_items) * 100,
            2) AS 'percent of all sales'
FROM
    order_items AS oi
        JOIN
    products AS pr ON oi.product_id = pr.product_id
        JOIN
    product_category_name_translation AS tr ON pr.product_category_name = tr.product_category_name
WHERE
    tr.product_category_name_english IN ('audio' , 'computers',
        'computers_accessories',
        'consoles_games',
        'electronics',
        'pc_gamer',
        'signaling_and_security',
        'tablets_printing_image',
        'telephony',
        'watches_gifts')
GROUP BY tr.product_category_name_english
ORDER BY items_sold DESC
;

-- --------------------------------------------------------------------------------------
/* 
What's the average price of the products being sold?
*/
-- average price of all sales: 120.65
SELECT 
    AVG(price)
FROM
    order_items;
-- average average price of most relevant tech sales: 132.44
SELECT 
    AVG(price)
FROM
    order_items AS oi
        LEFT JOIN
    products AS pr ON oi.product_id = pr.product_id
        INNER JOIN
    (SELECT 
        *
    FROM
        product_category_name_translation
    WHERE
        product_category_name_english IN (
        'audio' , 
        'computers', 
        'computers_accessories', 
        'consoles_games', 
        'electronics', 
        'pc_gamer', 
        'signaling_and_security', 
        'tablets_printing_image', 
        'telephony', 
        'watches_gifts')
        ) AS tech ON pr.product_category_name = tech.product_category_name;

/* 
Are expensive tech products popular? 
*/

-- determine quartiles of prices in most relevant tech categories
select 
min(avg_prices.price_average) Minimum,
max(case when avg_prices.quartile = 1 then avg_prices.price_average end) q1,
max(case when avg_prices.quartile = 2 then avg_prices.price_average end) median,
max(case when avg_prices.quartile = 3 then avg_prices.price_average end) q3,
max(avg_prices.price_average) Maximum
from(
-- calculate the average price for which each tech item sold
SELECT 
    avg(price) as price_average,
    ntile(4) over(order by avg(price)) as quartile
FROM
    products AS pr
        LEFT JOIN
    product_category_name_translation AS tr ON pr.product_category_name = tr.product_category_name
        LEFT JOIN
    order_items AS oi ON oi.product_id = pr.product_id
WHERE
    tr.product_category_name_english IN (
		'audio' , 
        'computers',
        'computers_accessories',
        'consoles_games',
        'electronics',
        'pc_gamer',
        'signaling_and_security',
        'tablets_printing_image',
        'telephony',
        'watches_gifts')
GROUP BY oi.product_id) as avg_prices
;
-- sales of products whose average price is in the top quartile of relevant tech product prices: 3.1 percent of all sales
SELECT 
	count(*) as expensive_tech, (count(*) / (select count(*) from order_items)) * 100 as percent
FROM 
	order_items as oi 
    JOIN 
		(SELECT 
			oi.product_id as product_id,
			avg(price) as price_average,
			ntile(4) over(order by avg(price)) as quartile
		FROM
			products AS pr
				LEFT JOIN
			product_category_name_translation AS tr ON pr.product_category_name = tr.product_category_name
				LEFT JOIN
			order_items AS oi ON oi.product_id = pr.product_id
		WHERE
			tr.product_category_name_english IN (
				'audio' , 
				'computers',
				'computers_accessories',
				'consoles_games',
				'electronics',
				'pc_gamer',
				'signaling_and_security',
				'tablets_printing_image',
				'telephony',
				'watches_gifts')
		GROUP BY oi.product_id) AS avg_price ON avg_price.product_id = oi.product_id
WHERE 
	avg_price.quartile = 4
;
-- ###########################################################################################
/*
3.2 QUESTIONS IN RELATION TO SELLERS
*/
-- ----------------------------------------------------------------------------------------
/*
How many months of data are included in the magist database?
*/
-- order purchased
SELECT 
    MIN(order_purchase_timestamp) AS earliest,
    MAX(order_purchase_timestamp) AS latest,
    COUNT(DISTINCT YEAR(order_purchase_timestamp),
        MONTH(order_purchase_timestamp)) AS months
FROM
    orders;
-- order approved
SELECT 
    MIN(order_approved_at) AS earliest,
    MAX(order_approved_at) AS latest,
    COUNT(DISTINCT YEAR(order_approved_at),
        MONTH(order_approved_at)) AS months
FROM
    orders;
-- order delivered to carrier
SELECT 
    MIN(order_delivered_carrier_date) AS earliest,
    MAX(order_delivered_carrier_date) AS latest,
    COUNT(DISTINCT YEAR(order_delivered_carrier_date),
        MONTH(order_delivered_carrier_date)) AS months
FROM
    orders;
-- order delivered to customer
SELECT 
    MIN(order_delivered_customer_date) AS earliest,
    MAX(order_delivered_customer_date) AS latest,
    COUNT(DISTINCT YEAR(order_delivered_customer_date),
        MONTH(order_delivered_customer_date)) AS months
FROM
    orders;
-- estimated delivery
SELECT 
    MIN(order_estimated_delivery_date) AS earliest,
    MAX(order_estimated_delivery_date) AS latest,
    COUNT(DISTINCT YEAR(order_estimated_delivery_date),
        MONTH(order_estimated_delivery_date)) AS months
FROM
    orders;

-- ----------------------------------------------------------------------------------
/*
How many sellers are there? 
How many Tech sellers are there? 
What percentage of overall sellers are Tech sellers? 
*/

SELECT 
    COUNT(seller_id)
FROM
    sellers; -- 3095
-- tech sellers: 572, 18.48%
SELECT 
    COUNT(DISTINCT oi.seller_id) AS tech_sellers,
    (COUNT(DISTINCT oi.seller_id) / (SELECT 
            COUNT(*)
        FROM
            sellers)) * 100 AS percentage
FROM
    order_items AS oi
        LEFT JOIN
    products AS pr ON oi.product_id = pr.product_id
        LEFT JOIN
    product_category_name_translation AS tr ON pr.product_category_name = tr.product_category_name
WHERE
    tr.product_category_name_english IN ('audio' , 'computers',
        'computers_accessories',
        'consoles_games',
        'electronics',
        'pc_gamer',
        'signaling_and_security',
        'tablets_printing_image',
        'telephony',
        'watches_gifts')
;

-- -----------------------------------------------------------------------------
/*
What is the total amount earned by all sellers? 
What is the total amount earned by all Tech sellers?
*/
-- total value of all items sold: 13591643.70
SELECT 
    ROUND(SUM(price), 2) as total_value
FROM
    order_items;

-- total value of all tech products sold: 3062574.70, 22.53% of all total value of all items
SELECT 
    ROUND(SUM(oi.price), 2) as tech_value,
    (SUM(oi.price) / (SELECT 
            SUM(price)
        FROM
            order_items)) * 100 as percent
FROM
    order_items AS oi 
        JOIN
    products AS pr ON oi.product_id = pr.product_id
        JOIN
    product_category_name_translation AS tr ON pr.product_category_name = tr.product_category_name
WHERE
    tr.product_category_name_english IN (
		'audio', 
		'computers',
        'computers_accessories',
        'consoles_games',
        'electronics',
        'pc_gamer',
        'signaling_and_security',
        'tablets_printing_image',
        'telephony',
        'watches_gifts');

-- ---------------------------------------------------------------------------------------------------------------
/*
Can you work out the average monthly income of all sellers? 
Can you work out the average monthly income of Tech sellers?
*/
-- average monthly income of all sellers: 826.79

WITH monthly_incomes AS (
-- requires calculating total monthly income for every seller
SELECT 
    YEAR(order_purchase_timestamp) AS year, 
    MONTH(order_purchase_timestamp) AS month, 
    SUM(price) AS month_income, 
    seller_id
FROM
    orders AS ord
        JOIN
    order_items AS oi ON ord.order_id = oi.order_id
GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp), seller_id
ORDER BY year, month
)
SELECT 
	AVG(month_income) 
FROM 
	monthly_incomes
;

-- average monthly income of all tech sellers: 1102.44
WITH monthly_incomes AS (
SELECT 
    YEAR(order_purchase_timestamp) as year, 
    MONTH(order_purchase_timestamp) as month, 
    SUM(price) as month_income, 
    seller_id
FROM
    orders AS ord
        JOIN
    order_items AS oi ON ord.order_id = oi.order_id
		JOIN
    products AS pr ON oi.product_id = pr.product_id
        JOIN
    product_category_name_translation AS tr ON pr.product_category_name = tr.product_category_name
WHERE
    tr.product_category_name_english IN (
		'audio', 
        'computers',
        'computers_accessories',
        'consoles_games',
        'electronics',
        'pc_gamer',
        'signaling_and_security',
        'tablets_printing_image',
        'telephony',
        'watches_gifts')
GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp), seller_id
ORDER BY year, month
)
SELECT 
	AVG(month_income) 
FROM 
	monthly_incomes
;

-- #####################################################################################################
/*
Questions in relation to delivery time
*/
-- -----------------------------------------------------------------------------------------------------
/*
What’s the average time between the order being placed and the product being delivered?
*/
-- comparing three different calculation methods
SELECT 
    AVG(TIMESTAMPDIFF(HOUR,
        order_purchase_timestamp,
        order_delivered_customer_date))/24,
	AVG(TIMESTAMPDIFF(day,
        order_purchase_timestamp,
        order_delivered_customer_date)),
	AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp))
FROM
    orders;

/*
How many orders are delivered on time vs orders delivered with a delay?
*/
-- create a view storing data on the status of delivered orders
CREATE VIEW summary AS
    SELECT 
        order_id,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        order_status,
        CASE
            WHEN DATE(order_delivered_customer_date) <= DATE(order_estimated_delivery_date) THEN 'On Time'
            WHEN DATE(order_delivered_customer_date) > DATE(order_estimated_delivery_date) THEN 'Delayed'
        END AS order_compliance
    FROM
        orders
    WHERE
        order_status = 'delivered';

-- Count orders falling into each status category: 6.9% of orders were delayed.
SELECT 
    order_compliance, COUNT(*) as deliveries, COUNT(*) / (SELECT COUNT(*) FROM summary) * 100 AS percent
FROM
    summary
GROUP BY order_compliance;

/*
Is there any pattern for dealyed orders, e.g. big products being delayed more often?
*/
-- Create a view storing information about ordered products and their delivery status
CREATE VIEW products_delays AS
    SELECT 
        pr.product_id,
        pr.product_category_name,
        pr.product_weight_g,
        pr.product_length_cm,
        pr.product_height_cm,
        pr.product_width_cm,
        oi.order_id,
        oi.seller_id,
        oi.price,
        oi.freight_value,
        summary.order_delivered_customer_date,
        summary.order_estimated_delivery_date,
        summary.order_compliance
    FROM
        products AS pr
            LEFT JOIN
        order_items AS oi ON pr.product_id = oi.product_id
            LEFT JOIN
        summary ON oi.order_id = summary.order_id;
        
-- on average, products with delayed deliveries tend to be slightly heavier and bigger       

SELECT 
    order_compliance,
    AVG(product_length_cm * product_height_cm * product_width_cm) AS volume,
    AVG(product_weight_g)
FROM
    products_delays
GROUP BY order_compliance;