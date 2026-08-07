CREATE DATABASE IF NOT EXISTS ecommerce_analytics;
USE ecommerce_analytics;

-- Drop existing tables to start clean
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS web_logs;

CREATE TABLE users (
	user_id INT PRIMARY KEY,
    created_at DATETIME NOT NULL,
    customer_name VARCHAR(50) NOT NULL,
    email VARCHAR(50) NOT NULL,
    gender VARCHAR(20) NOT NULL,
    birth_date DATETIME NOT NULL,
    traffic_source VARCHAR(50) NOT NULL
);

CREATE TABLE orders (
	order_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    order_date DATETIME NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    item_count INT NOT NULL,
    shipping_fee DECIMAL(10, 2) NOT NULL,
    discount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE web_logs (
	event_id INT PRIMARY KEY,
    session_id INT NOT NULL,
    user_id INT NOT NULL,
    order_id INT DEFAULT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_timestamp DATETIME NOT NULL,
    device_type VARCHAR(20) NOT NULL,
    browser VARCHAR(20) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

SET GLOBAL local_infile = 1;

-- Importing users data
LOAD DATA LOCAL INFILE 'C:/Zaw/My Projects/Customer Retention and Revenue Cohort Engine/Data/users.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Importing orders data
LOAD DATA LOCAL INFILE 'C:/Zaw/My Projects/Customer Retention and Revenue Cohort Engine/Data/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Importing web_logs data
LOAD DATA LOCAL INFILE 'C:/Zaw/My Projects/Customer Retention and Revenue Cohort Engine/Data/web_logs.csv'
INTO TABLE web_logs
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT
	(SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT COUNT(*) FROM web_logs) AS total_web_logs;