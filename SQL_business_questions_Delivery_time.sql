    -- Is Magist a good fit for high-end tech products?
    -- Are orders delivered on time?
    
SELECT * FROM order_items;
SELECT * FROM order_payments;
SELECT * FROM order_reviews;
SELECT * FROM orders;


-- 3.3. In relation to the delivery time:
-- What’s the average time between the order being placed and the product being delivered?

-- overview for each order
SELECT
	order_id, TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) as time_between_order_and_delivery_DAYS
FROM
	orders
WHERE order_status = "delivered"
GROUP BY order_id
ORDER BY time_between_order_and_delivery_DAYS;

-- !!! 12 days is the average between the order being placed and the product being delivered
SELECT
	AVG(TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)) 
FROM
	orders
WHERE order_status = "delivered";



/* STUFF I TRIED BUT IS NOT OK
SELECT
	order_id, AVG(order_delivered_customer_date - order_purchase_timestamp) as avg_time_between_order_and_delivery
FROM
	orders
GROUP BY order_id;


SELECT
	order_id, AVG(datediff(dd, order_purchase_timestamp, order_delivered_customer_date)) as avg_time_between_order_and_delivery
FROM
	orders;
    

SELECT
	order_id, AVG(order_delivered_customer_date - order_purchase_timestamp) as avg_time_between_order_and_delivery
FROM (
	SELECT 
    order_id,
    order_delivered_customer_date,
    LAG(order_delivered_customer_date) OVER (PARTITION BY order_id ORDER BY order_delivered_customer_date) as order_purchase_timestamp
FROM orders)
GROUP BY order_id;

SELECT
	order_id, AVG(order_delivered_customer_date - lag_delivery) as avg_time_between_order_and_delivery
FROM (
	SELECT order_id, order_delivered_customer_date, lag(order_purchase_timestamp) over (partition by order_id) as lag_delivery
    from orders )
GROUP BY order_id; */
    

-- How many orders are delivered on time vs orders delivered with a delay?

-- overview for each order that was delivered
-- Negative Results: if the first date/time argument is greater than the second, the result will be a negative integer.
SELECT
	order_id, order_status, order_purchase_timestamp, order_delivered_customer_date,order_estimated_delivery_date, TIMESTAMPDIFF(DAY,order_estimated_delivery_date, order_delivered_customer_date) as diff_estimated_delivered_DAYS
FROM
	orders
WHERE order_status = "delivered"
GROUP BY order_id
ORDER BY diff_estimated_delivered_DAYS;

-- 7826'orderd are delayed from '99441' => 7.87% or orders are delayed with average of 10 days than expected !

-- '7826'orderd are delayed
with summary as
(
select
order_id, order_delivered_customer_date, order_estimated_delivery_date, order_status,
case
when order_delivered_customer_date<order_estimated_delivery_date then 'Within Schedule'
when order_delivered_customer_date=order_estimated_delivery_date then 'On Time'
when order_delivered_customer_date>order_estimated_delivery_date then 'Delayed' 
end as order_compliance
from orders
WHERE order_status = "delivered"
)
SELECT COUNT(order_id) as order_count
FROM summary 
WHERE order_compliance = 'On Time';


SELECT
	COUNT(order_id)
FROM
	orders
WHERE order_status = "delivered"  AND (date(order_delivered_customer_date) = date(order_estimated_delivery_date));


with summary as
(
select
order_id,order_delivered_customer_date, order_estimated_delivery_date, order_status,
case
when date(order_delivered_customer_date)<date(order_estimated_delivery_date) then 'Within Schedule'
when date(order_delivered_customer_date)=date(order_estimated_delivery_date) then 'On Time'
when date(order_delivered_customer_date)>date(order_estimated_delivery_date) then 'Delayed' 
end as order_compliance
from orders
WHERE order_status = "delivered"
)
SELECT 
	COUNT(order_id) as order_count, 
    AVG(datediff(order_delivered_customer_date, order_estimated_delivery_date)) 
FROM summary 
WHERE order_compliance = 'Delayed';

--- for tableau
with summary as
(
select
order_id,order_delivered_customer_date, order_estimated_delivery_date, order_status,
case
when date(order_delivered_customer_date)<=date(order_estimated_delivery_date) then 'On Time'
when date(order_delivered_customer_date)>date(order_estimated_delivery_date) then 'Delayed' 
end as order_compliance
from orders
WHERE order_status = "delivered"
)
SELECT 
	order_id, order_compliance,
    datediff(order_delivered_customer_date, order_estimated_delivery_date) as delay_betwee_deliv_estim
FROM summary;



with summary as
(
select
order_id,order_delivered_customer_date, order_estimated_delivery_date, order_status,
case
when date(order_delivered_customer_date)<date(order_estimated_delivery_date) then 'Within Schedule'
when date(order_delivered_customer_date)=date(order_estimated_delivery_date) then 'On Time'
when date(order_delivered_customer_date)>date(order_estimated_delivery_date) then 'Delayed' 
end as order_compliance
from orders
WHERE order_status = "delivered"
)
SELECT 
	COUNT(order_id) as order_count, 
    AVG(datediff(order_delivered_customer_date, order_estimated_delivery_date)), 
    MIN((datediff(order_delivered_customer_date, order_estimated_delivery_date)), 
    MAX((datediff(order_delivered_customer_date, order_estimated_delivery_date)), 
    stddev(datediff(order_delivered_customer_date, order_estimated_delivery_date)), 
FROM summary 
WHERE order_compliance = 'Delayed';




-- Is there any pattern for delayed orders, e.g. big products being delayed more often?


-- not the complete version, Eli had a better code!
with summary as
(
select
order_id,order_delivered_customer_date, order_estimated_delivery_date, order_status,
case
when date(order_delivered_customer_date)<date(order_estimated_delivery_date) then 'Within Schedule'
when date(order_delivered_customer_date)=date(order_estimated_delivery_date) then 'On Time'
when date(order_delivered_customer_date)>date(order_estimated_delivery_date) then 'Delayed' 
end as order_compliance
from orders
WHERE order_status = "delivered"
)
SELECT 
    tr.product_category_name_english AS category,
    AVG(datediff(order_delivered_customer_date, order_estimated_delivery_date)) 
FROM
    order_items AS oi
    JOIN 
    summary ON oi.order_id = summary.order_id
        JOIN
    products AS pr ON oi.product_id = pr.product_id
        JOIN
    product_category_name_translation AS tr ON pr.product_category_name = tr.product_category_name
WHERE order_compliance = 'Delayed'
GROUP BY pr.product_category_name
ORDER BY AVG(datediff(order_delivered_customer_date, order_estimated_delivery_date)) DESC;
