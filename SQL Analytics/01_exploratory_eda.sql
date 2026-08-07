# 1. Primary Key Integrity & Record Count Audit

-- Evaluates row counts, NULL key presence, and primary key uniqueness across core tables.
SELECT 
    'users' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(user_id) AS non_null_keys,
    COUNT(DISTINCT user_id) AS distinct_keys,
    COUNT(*) - COUNT(DISTINCT user_id) AS key_discrepancy,
    CASE WHEN COUNT(*) = COUNT(DISTINCT user_id) THEN 'PASS' ELSE 'FAIL' END AS pk_status
FROM users

UNION ALL

SELECT 
    'orders' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(order_id) AS non_null_keys,
    COUNT(DISTINCT order_id) AS distinct_keys,
    COUNT(*) - COUNT(DISTINCT order_id) AS key_discrepancy,
    CASE WHEN COUNT(*) = COUNT(DISTINCT order_id) THEN 'PASS' ELSE 'FAIL' END AS pk_status
FROM orders

UNION ALL

SELECT 
    'web_logs' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(event_id) AS non_null_keys,
    COUNT(DISTINCT event_id) AS distinct_keys,
    COUNT(*) - COUNT(DISTINCT event_id) AS key_discrepancy,
    CASE WHEN COUNT(*) = COUNT(DISTINCT event_id) THEN 'PASS' ELSE 'FAIL' END AS pk_status
FROM web_logs;
    
# 2. Data Range & Time Window Check

-- Check the date range across all the datasets
WITH combined_dates AS (
	SELECT created_at AS event_date FROM users
    UNION ALL
    SELECT order_date AS event_date FROM orders
    UNION ALL
    SELECT event_timestamp AS event_date FROM web_logs
)
SELECT
	MIN(event_date) AS global_mimum_date,
    MAX(event_date) AS global_maximum_date
FROM combined_dates;

-- Check if there is any order made prior to the regristration of the user (orders.order_date < users.created_at)
-- It should return 0 row, or the dataset is flawed
SELECT
	users.user_id,
    orders.order_id,
    users.created_at,
    orders.order_date
FROM users
	LEFT JOIN orders
    ON users.user_id = orders.user_id
WHERE orders.order_date < users.created_at;

# 3. Order Status Breakdown & Revenue Categorization

-- Distribution of order status
SELECT 
	status,
	COUNT(DISTINCT order_id) AS order_count,
    COUNT(DISTINCT order_id) / SUM(COUNT(DISTINCT order_id)) OVER() AS order_count_pct,
    SUM(total_amount) AS total_gross_value
FROM orders
GROUP BY status;

# 4. Missing and Null Value Audit

-- Check if there are any null values across key columns in each dataset.
-- All should return zeros.
SELECT 
	SUM(CASE WHEN created_at IS NULL THEN 1 ELSE 0 END) AS created_at,
    SUM(CASE WHEN traffic_source IS NULL THEN 1 ELSE 0 END) AS traffic_source,
    SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END) AS email
FROM users;

SELECT
	SUM(CASE WHEN total_amount IS NULL THEN 1 ELSE 0 END) AS total_amount,
    SUM(CASE WHEN discount IS NULL THEN 1 ELSE 0 END) AS discount,
    SUM(CASE WHEN shipping_fee IS NULL THEN 1 ELSE 0 END) AS shipping_fee,
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) as user_id
FROM orders;

SELECT
	SUM(CASE WHEN session_id IS NULL THEN 1 ELSE 0 END) AS session_id,
    SUM(CASE WHEN event_type IS NULL THEN 1 ELSE 0 END) AS event_type,
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS user_id
FROM web_logs;

# 5. Referential Integrity Check

-- Check if there are any orders made without the user_id in the users table
SELECT 
    COUNT(o.order_id) AS orphaned_orders
FROM orders o
	LEFT JOIN users u 
    ON o.user_id = u.user_id
WHERE u.user_id IS NULL;