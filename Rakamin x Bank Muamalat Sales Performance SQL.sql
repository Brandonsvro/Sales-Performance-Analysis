/*
Create the necessary tables to hold data for analysis:
- customers table
- orders table
- products table
- product_categories table
*/

-- Create the customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(254) UNIQUE CHECK (customer_email LIKE '%@%'),
    mail_to VARCHAR(261) UNIQUE,
    customer_phone VARCHAR(20) UNIQUE NOT NULL,
    customer_address VARCHAR(255) NOT NULL,
    customer_city VARCHAR(100) NOT NULL,
    customer_state VARCHAR(50) NOT NULL,
    customer_zip VARCHAR(10) NOT NULL
); -- Customers data will be imported using the import feature in the menu


-- Create the orders table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    date DATE NOT NULL,
    customer_id INT NOT NULL,
    product_number VARCHAR(25) NOT NULL,
    quantity INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_number) REFERENCES products(product_number)
); -- Orders data will be imported using the import feature in the menu


-- Create the products table
CREATE TABLE products (
    product_number VARCHAR(25) PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category INT NOT NULL,
    price NUMERIC(5,2) NOT NULL,
    FOREIGN KEY (category) REFERENCES product_categories(category_id)
); -- Products data will be imported using the import feature in the menu


-- Create the product_categories table
DROP TABLE IF EXISTS product_categories; -- Ensures the table is dropped before re-creating
CREATE TABLE product_categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL,
    category_abbreviation VARCHAR(10) NOT NULL
); -- Product categories data will be imported using the import feature in the menu


/*
Query 1: Business Performance by Metrics
*/

-- Total Revenue
WITH revenue_peryear AS(
	SELECT SUM(CASE WHEN EXTRACT(YEAR FROM o.date) = 2020 THEN o.quantity * p.price ELSE NULL END) AS revenue_2020,
			SUM(CASE WHEN EXTRACT(YEAR FROM o.date) = 2021 THEN o.quantity * p.price ELSE NULL END) AS revenue_2021
	FROM orders AS o
	JOIN products AS p
	ON o.product_number = p.product_number	
)

SELECT revenue_2020,
		revenue_2021,
		ROUND(((revenue_2021-revenue_2020)/revenue_2020)*100,2) AS growth_percentage
FROM revenue_peryear
	
-- Avg Order Value
WITH aov_peryear AS(
	SELECT SUM(CASE WHEN EXTRACT(YEAR FROM o.date) = 2020 THEN o.quantity * p.price ELSE NULL END)/COUNT(CASE WHEN EXTRACT(YEAR FROM o.date) = 2020 THEN o.order_id ELSE NULL END) AS aov_2020,
			SUM(CASE WHEN EXTRACT(YEAR FROM o.date) = 2021 THEN o.quantity * p.price ELSE NULL END)/COUNT(CASE WHEN EXTRACT(YEAR FROM o.date) = 2021 THEN o.order_id ELSE NULL END) AS aov_2021
	FROM orders AS o
	JOIN products AS p
	ON o.product_number = p.product_number
)

SELECT ROUND(aov_2020,2),
		ROUND(aov_2021,2),
		ROUND(((aov_2021 - aov_2020)/aov_2020)*100,2) as growth_percentage
FROM aov_peryear

-- Avg Revenue per Customer
WITH revenue_percust_peryear AS(
	SELECT SUM(CASE WHEN EXTRACT(YEAR FROM o.date) = 2020 THEN o.quantity * p.price ELSE NULL END)/COUNT (DISTINCT((CASE WHEN EXTRACT(YEAR FROM o.date) = 2020 THEN o.customer_id ELSE NULL END))) AS revenue_percust_2020,
			SUM(CASE WHEN EXTRACT(YEAR FROM o.date) = 2021 THEN o.quantity * p.price ELSE NULL END)/COUNT (DISTINCT((CASE WHEN EXTRACT(YEAR FROM o.date) = 2021 THEN o.customer_id ELSE NULL END))) AS revenue_percust_2021
	FROM orders AS o
	JOIN products AS p
	ON o.product_number = p.product_number
)

SELECT ROUND(revenue_percust_2020,2),
		ROUND(revenue_percust_2021,2),
		ROUND(((revenue_percust_2021 - revenue_percust_2020)/revenue_percust_2020)*100,2) as growth_percentage
FROM revenue_percust_peryear
	
-- Order Frequency
WITH orderfreq_percust_peryear AS(
	SELECT COUNT ((CASE WHEN EXTRACT(YEAR FROM o.date) = 2020 THEN o.order_id ELSE NULL END))/COUNT (DISTINCT((CASE WHEN EXTRACT(YEAR FROM o.date) = 2020 THEN o.customer_id ELSE NULL END))) AS freq_percust_2020,
			COUNT ((CASE WHEN EXTRACT(YEAR FROM o.date) = 2021 THEN o.order_id ELSE NULL END))/COUNT (DISTINCT((CASE WHEN EXTRACT(YEAR FROM o.date) = 2021 THEN o.customer_id ELSE NULL END))) AS freq_percust_2021
	FROM orders AS o
	JOIN products AS p
	ON o.product_number = p.product_number
)

SELECT freq_percust_2020,
		freq_percust_2021,
		((freq_percust_2021 - freq_percust_2020)/freq_percust_2020)*100 as growth_percentage
FROM orderfreq_percust_peryear
	
-- Avg Items per Order
WITH items_perorder_peryear AS(
	SELECT SUM(CASE WHEN EXTRACT(YEAR FROM o.date) = 2020 THEN o.quantity ELSE NULL END)/COUNT(CASE WHEN EXTRACT(YEAR FROM o.date) = 2020 THEN o.order_id ELSE NULL END) AS items_perorder_2020,
			SUM(CASE WHEN EXTRACT(YEAR FROM o.date) = 2021 THEN o.quantity ELSE NULL END)/COUNT(CASE WHEN EXTRACT(YEAR FROM o.date) = 2021 THEN o.order_id ELSE NULL END) AS items_perorder_2021
	FROM orders AS o
	JOIN products AS p
	ON o.product_number = p.product_number
)

SELECT items_perorder_2020,
		items_perorder_2021,
		((items_perorder_2021 - items_perorder_2020)/items_perorder_2020)*100 as growth_percentage
FROM items_perorder_peryear

/*
Query 2: Display total sales by product category
*/
SELECT pc.category_name,
       SUM(o.quantity * p.price) AS total_sales
FROM orders AS o
JOIN products AS p
ON o.product_number = p.product_number
JOIN product_categories AS pc
ON p.category = pc.category_id
GROUP BY pc.category_name
ORDER BY total_sales DESC;


/*
Query 3: Display total quantities by product category
*/
SELECT pc.category_name,
       SUM(o.quantity) AS total_quantity
FROM orders AS o
JOIN products AS p
ON o.product_number = p.product_number
JOIN product_categories AS pc
ON p.category = pc.category_id
GROUP BY pc.category_name
ORDER BY total_quantity DESC;


/*
Query 4: Display total sales by city
*/
SELECT c.customer_city,
       SUM(o.quantity * p.price) AS total_sales
FROM orders AS o
JOIN products AS p
ON o.product_number = p.product_number
JOIN customers AS c
ON o.customer_id = c.customer_id
GROUP BY c.customer_city
ORDER BY total_sales DESC;


/*
Query 5: Display total quantity by city
*/
SELECT c.customer_city,
       SUM(o.quantity) AS total_quantity
FROM orders AS o
JOIN customers AS c
ON o.customer_id = c.customer_id
GROUP BY c.customer_city
ORDER BY total_quantity DESC;


/*
Query 6: Display the top 5 product categories by total sales
*/
SELECT pc.category_name,
       SUM(o.quantity * p.price) AS total_sales
FROM orders AS o
JOIN products AS p
ON o.product_number = p.product_number
JOIN product_categories AS pc
ON p.category = pc.category_id
GROUP BY pc.category_name
ORDER BY total_sales DESC
LIMIT 5;


/*
Query 7: Display the top 5 product categories by total quantity
*/
SELECT pc.category_name,
       SUM(o.quantity) AS total_quantity
FROM orders AS o
JOIN products AS p
ON o.product_number = p.product_number
JOIN product_categories AS pc
ON p.category = pc.category_id
GROUP BY pc.category_name
ORDER BY total_quantity DESC
LIMIT 5;


/*
Query 8: Create materialized views for visualization
*/

CREATE MATERIALIZED VIEW main_table AS
SELECT	c.customer_id,
		CONCAT(c.first_name, ' ', c.last_name) as customer_name,
		c.customer_city,
		c.customer_state,
		o.order_id,
		o.date,
		p.product_name,
		pc.category_name,
		o.quantity,
		p.price
FROM customers AS c
LEFT JOIN orders AS o
	ON c.customer_id = o.customer_id
JOIN products AS p
	ON o.product_number = p.product_number
JOIN product_categories AS pc
	ON p.category = pc.category_id;