# 1. Monthly Revenue and Growth Trends (Time-Series Breakdown)

-- Generate a monthly breakdown with MoM growth
WITH monthly_metrics AS (
	SELECT
		YEAR(order_date) AS order_year,
		MONTH(order_date) AS order_month,
		COUNT(DISTINCT order_id) AS total_orders,
		SUM(total_amount) AS gross_revenue,
		SUM(total_amount - discount + shipping_fee) AS net_revenue,
		SUM(discount) AS total_discount
	FROM orders
	WHERE status IN('shipped', 'completed')
	GROUP BY YEAR(order_date), MONTH(order_date)
),
mom_lag AS (
	SELECT 
		order_year,
        order_month,
        total_orders,
        gross_revenue,
        total_discount,
        net_revenue,
        LAG(net_revenue) OVER (ORDER BY order_year, order_month) AS prev_month_revenue
	FROM monthly_metrics
)
SELECT
	*,
    (net_revenue - prev_month_revenue) / NULLIF(prev_month_revenue, 0) AS mom_growth_rate
FROM mom_lag;

# 2. Average Order Value and Basket Size by Traffic Source

-- Customers across different traffic sources
SELECT
	users.traffic_source,
    COUNT(DISTINCT users.user_id) AS total_registered_users,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    AVG(orders.total_amount) AS average_order_value,
    AVG(orders.item_count) AS average_basket_size
FROM users
	LEFT JOIN orders
    ON users.user_id = orders.user_id
GROUP BY users.traffic_source
ORDER BY total_orders DESC;

WITH user_order_aggregates AS (
	SELECT 
		users.user_id,
		users.traffic_source,
		COUNT(orders.order_id) AS user_order_count,
		COALESCE(SUM(orders.total_amount), 0) AS user_total_spend,
		COALESCE(SUM(orders.item_count), 0) AS user_total_units
	FROM users
	LEFT JOIN orders
		ON users.user_id = orders.order_id
		AND orders.status IN ('shipped', 'completed')
	GROUP BY users.user_id, users.traffic_source
)
SELECT
	traffic_source,
    COUNT(user_id) AS total_registered_users,
    COUNT(CASE WHEN user_order_count > 0 THEN 1 END) AS paying_customers,
    
    -- Conversion Rate %
    ROUND(COUNT(CASE WHEN user_order_count > 0 THEN 1 END) * 100.0 / COUNT(user_id), 2) AS conversion_rate_pct,
    
    -- Average Revenue per Registered User (ARPU)
    ROUND(AVG(user_total_spend), 2) AS avg_spend_per_user,
    
    -- Average Units per Registered User 
    ROUND(AVG(user_total_units), 2) AS avg_units_per_user
FROM user_order_aggregates
GROUP BY traffic_source
ORDER BY conversion_rate_pct DESC;

# 3. Discount Impact and Erosion Analysis

SELECT
	-- Categorizing discount tier
	CASE 
		WHEN discount = 0 THEN '1. No Discount'
        WHEN discount BETWEEN 0.01 AND 15.00 THEN '2. Low Discount ($0.01-$15)'
        WHEN discount BETWEEN 15.01 AND 40.00 THEN '3. Medium Discount ($15.01-$40)'
        ELSE '4. High Discount (>$40)'
	END AS discount_tier,
    
	-- Total number of orders in each discount tier
    COUNT(DISTINCT order_id) AS total_orders,

    -- Average number of items per order
    ROUND(AVG(item_count), 2) AS avg_item_count,
    
    -- Total discount given away in this tier
    ROUND(AVG(discount), 2) AS avg_discount_amount,
    
    -- Assuming total_amount is Subtotal (Gross Value)
    ROUND(AVG(total_amount - discount + shipping_fee), 2) AS avg_net_revenue,
    
    -- Erosion Metric: Total discount dollars absorbed across all orders in tier
    ROUND(SUM(discount), 2) AS total_discount_erosion
FROM orders
WHERE status IN('shipped', 'completed')
GROUP BY discount_tier
ORDER BY discount_tier ASC;

# 4. Customer Repeat Purchase Rate & Lifetime Order Frequency

-- Turn it into a view
CREATE OR REPLACE VIEW repeat_customer_summary AS
-- Customers who have made at least one order
WITH CustomerOrderCounts AS (
    SELECT 
        user_id,
        COUNT(order_id) AS total_orders
    FROM orders
    WHERE status IN ('shipped', 'completed')
    GROUP BY user_id
),
-- Categorize customers based on their number of purchases
CategorizedCustomers AS (
    SELECT 
        user_id,
        CASE 
            WHEN total_orders > 1 THEN 'Repeat Customer'
            ELSE 'One-Time Customer'
        END AS customer_type
    FROM CustomerOrderCounts
)
-- Calculate the percentage of one-time and repeat customers
SELECT 
    customer_type,
    COUNT(user_id) AS customer_count,
    ROUND(COUNT(user_id) * 100.0 / SUM(COUNT(user_id)) OVER(), 2) AS customer_pct
FROM CategorizedCustomers
GROUP BY customer_type;

SELECT * FROM repeat_customer_summary;