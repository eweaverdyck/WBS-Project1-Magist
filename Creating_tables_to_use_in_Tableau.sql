/*
Exporting data for Tablaue
*/

-- products with tech categories (tech vs non-tech, expensive tech vs non-expensive tech vs non-tech)
CREATE VIEW tech_expense as (
WITH tech_quart AS (
	SELECT 
		oi.product_id AS product_id, AVG(price) AS price_average,
		NTILE(4) OVER(ORDER BY AVG(price)) AS quartile
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
	GROUP BY oi.product_id)
SELECT 
	product_id, 
    CASE 
		WHEN quartile = 4 THEN 'expensive tech'
		ELSE 'non-expensive tech'
	END AS tech_expense_category
FROM tech_quart
);

CREATE VIEW our_product_categories AS
    SELECT 
        products.product_id,
        CASE
            WHEN tech_expense.tech_expense_category = 'expensive tech' THEN 'expensive tech'
            WHEN tech_expense.tech_expense_category = 'non-expensive tech' THEN 'non-expensive tech'
            ELSE 'non-tech'
        END AS exp_tech_cat
    FROM
        products
            LEFT JOIN
        tech_expense ON products.product_id = tech_expense.product_id;
        
CREATE VIEW products_tech_categories AS
SELECT 
	pr.product_id, 
    CASE
        WHEN
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
			THEN 'tech'
        ELSE 'non-tech'
    END AS tech_category,
    opc.exp_tech_cat
FROM 
	products AS pr 
		LEFT JOIN 
			product_category_name_translation as tr on pr.product_category_name = tr.product_category_name
        LEFT JOIN
			our_product_categories as opc on opc.product_id = pr.product_id
;

-- average income for all sellers and tech sellers by month
CREATE VIEW monthly_income_all_sellers AS
SELECT 
    YEAR(order_purchase_timestamp) AS year, 
    MONTH(order_purchase_timestamp) as month, 
    SUM(price) as month_income, 
    seller_id
FROM
    orders AS ord
        JOIN
    order_items AS oi ON ord.order_id = oi.order_id
GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp), seller_id
ORDER BY year, month
;

CREATE VIEW monthly_income_tech_sellers AS
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
;
-- calculating date fields from the above views for use in Tableau
SELECT 
    CAST(CONCAT(CAST(year AS CHAR),
                '-',
                CAST(month AS CHAR),
                '-01')
        AS DATE) AS month,
    AVG(month_income) AS avg_tech_seller_income
FROM
    monthly_income_tech_sellers
GROUP BY year , month;
SELECT 
    CAST(CONCAT(CAST(year AS CHAR),
                '-',
                CAST(month AS CHAR),
                '-01')
        AS DATE) AS month,
    AVG(month_income) AS avg_seller_income
FROM
    monthly_income_all_sellers
GROUP BY year , month;

-- order_items with delay information
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
