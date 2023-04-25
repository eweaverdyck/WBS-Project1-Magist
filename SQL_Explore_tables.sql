-- How many orders are there in the dataset? The orders table contains a row for each order, so this should be easy to find out!
    
 SELECT 
	COUNT(*)
FROM 
	orders;
 

-- Are orders actually delivered? Look at columns in the orders table: one of them is called order_status. Most orders seem to be delivered, but some aren’t. Find out how many orders are delivered and how many are canceled, unavailable, or in any other status by grouping and aggregating this column.

 SELECT 
	order_status, COUNT(order_status), (COUNT(order_status)/99441)*100 AS PER_ORDER_STATUS
FROM 
	orders
GROUP BY     
	order_status;

    
    
-- Is Magist having user growth? A platform losing users left and right isn’t going to be very useful to us. It would be a good idea to check for the number of orders grouped by year and month. Tip: you can use the functions YEAR() and MONTH() to separate the year and the month of the order_purchase_timestamp.

SELECT 
    YEAR(order_purchase_timestamp) as year,
    MONTH(order_purchase_timestamp) as month,
    COUNT(*)
FROM
    orders
GROUP BY YEAR(order_purchase_timestamp) , MONTH(order_purchase_timestamp)
order by year, month;


-- How many products are there on the products table? (Make sure that there are no duplicate products.)
SELECT
	DISTINCT COUNT(product_id)
FROM
	products;


-- Which are the categories with the most products? Since this is an external database and has been partially anonymized, we do not have the names of the products. But we do know which categories products belong to. This is the closest we can get to know what sellers are offering in the Magist marketplace. By counting the rows in the products table and grouping them by categories, we will know how many products are offered in each category. This is not the same as how many products are actually sold by category. To acquire this insight we will have to combine multiple tables together: we’ll do this in the next lesson.

SELECT 
	t.product_category_name_english, products.product_category_name, COUNT(products.product_category_name)
FROM
	products
LEFT JOIN product_category_name_translation as t ON products.product_category_name = t.product_category_name
GROUP BY 
	products.product_category_name
ORDER BY COUNT(products.product_category_name) DESC;

-- How many of those products were present in actual transactions? The products table is a “reference” of all the available products. Have all these products been involved in orders? Check out the order_items table to find out!

SELECT 
	count(DISTINCT product_id) AS n_products
FROM
	order_items;


SELECT 
    prt.product_category_name_english, COUNT(oi.product_id) as products_ordered
FROM
    products AS pr
        INNER JOIN
    product_category_name_translation AS prt ON pr.product_category_name = prt.product_category_name
        INNER JOIN
    order_items AS oi ON pr.product_id = oi.product_id
GROUP BY prt.product_category_name
order by products_ordered desc;

select count(distinct product_id) from order_items;


-- What’s the price for the most expensive and cheapest products? Sometimes, having a basing range of prices is informative. Looking for the maximum and minimum values is also a good way to detect extreme outliers.

SELECT
	MAX(price), MIN(price)
FROM
	order_items;



-- What are the highest and lowest payment values? Some orders contain multiple products. What’s the highest someone has paid for an order? Look at the order_payments table and try to find it out.  

SELECT
	MAX(payment_value), MIN(payment_value)
FROM
	order_payments;


