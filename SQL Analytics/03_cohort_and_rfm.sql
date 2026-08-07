# 1. Cohort Retention Matrix

-- CTE 1: Identify each user's initial purchase date to establish their cohort
WITH user_first_order AS (
	SELECT 
		user_id,
        -- Truncate the earliest order date to the 1st of the month (YYYY-MM-01 format)
		DATE_FORMAT(MIN(order_date), '%Y-%m-01') AS first_order_month
	FROM orders
    -- Filter only for successful transactions
	WHERE status IN ('completed', 'shipped')
	GROUP BY user_id
),

-- CTE 2: Calculate the total base population (cohort size) for each cohort month
cohort_sizes AS (
	SELECT
		first_order_month,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM user_first_order
    GROUP BY first_order_month 
),

-- CTE 3: Join overall order history back to each user's cohort details
-- and calculate the relative month offset for every subsequent order
user_activities AS (
	SELECT 
		u.user_id,
        u.first_order_month,
        DATE_FORMAT(o.order_date, '%Y-%m-%d') AS order_date,
        -- Calculate how many months elapsed between acquisition month and transaction month
        -- (0 = initial purchase month, 1 = first month following acquisition, etc.)
		PERIOD_DIFF(
			DATE_FORMAT(o.order_date, '%Y%m'),
			DATE_FORMAT(u.first_order_month, '%Y%m')
		) AS cohort_index
	FROM user_first_order AS u
		LEFT JOIN orders AS o
		ON u.user_id = o.user_id
			-- Only evaluate valid subsequent purchases
			AND o.status IN ('completed', 'shipped')
)

-- FINAL SELECT: Aggregate activity into multi-month retention windows per cohort
SELECT 
	a.first_order_month,
    c.cohort_size,
    -- Months 1 to 3: % of cohort returning during Quarter 1 post-acquisition
    ROUND(COUNT(DISTINCT CASE WHEN a.cohort_index BETWEEN 1 AND 3 THEN a.user_id END) / c.cohort_size, 2) AS m1_m3,
    -- Months 4-6: % of cohort returning during Quarter 2 post-acquisition
    ROUND(COUNT(DISTINCT CASE WHEN a.cohort_index BETWEEN 4 AND 6 THEN a.user_id END) / c.cohort_size, 2) AS m4_m6,
	-- Months 7 to 12: % of cohort returning during the remainder of Year 1
	ROUND(COUNT(DISTINCT CASE WHEN a.cohort_index BETWEEN 7 AND 12 THEN a.user_id END) / c.cohort_size, 2) AS m7_m12,
	-- Months 13 to 24: % of cohort returning anytime during Year 2
	ROUND(COUNT(DISTINCT CASE WHEN a.cohort_index BETWEEN 13 AND 24 THEN a.user_id END) / c.cohort_size, 2) AS y2,
	-- Months 25 to 36: % of cohort returning anytime during Year 3
	ROUND(COUNT(DISTINCT CASE WHEN a.cohort_index BETWEEN 25 AND 36 THEN a.user_id END) / c.cohort_size, 2) AS y3
FROM user_activities AS a
	-- Join cohort size denominator to compute retention ratios
	LEFT JOIN cohort_sizes AS c
    ON a.first_order_month = c.first_order_month
GROUP BY a.first_order_month, c.cohort_size;

# 2. RFM Customer Segmentation 

-- CTE 1: Calculate raw Recency, Frequency, and Monetary metrics per user
WITH user_rfm_raw AS (
	SELECT
		user_id,
        -- Recency: Days between the dataset's latest transaction date and the user's last order
		DATEDIFF((SELECT MAX(order_date) FROM orders), MAX(order_date)) AS days_since_last_order,
        -- Frequency: Total number of completed orders
		COUNT(order_id) AS total_orders,
        -- Monetary Value: Total net spend after discounts
		SUM(total_amount - discount) AS total_spend
	FROM orders
	GROUP BY user_id
),

-- CTE 2: Bin raw metrics into 1-5 score quintiles using NTILE(5)
rfm_scores AS (
	SELECT 
		user_id,
		days_since_last_order,
		total_orders,
		total_spend,
        -- Recency: Lower days = higher score (ORDER BY DESC puts smallest days at quintile 5)
		NTILE(5) OVER (ORDER BY days_since_last_order DESC) AS r_score,
        -- Frequency: Higher count = higher score
		NTILE(5) OVER (ORDER BY total_orders ASC) AS f_score,
        -- Monetary: Higher spend = higher score
		NTILE(5) OVER (ORDER BY total_spend ASC) AS m_score
	FROM user_rfm_raw
),

-- CTE 3: Combine individual R, F, and M scores into a single RFM string (e.g., '5-5-5')
rfm_combined AS (
	SELECT 
		*,
        CONCAT(r_score, '-', f_score, '-', m_score) AS rfm_score
    FROM rfm_scores
),

-- CTE 4: Map RFM score profiles to business segment labels
customer_segment AS(
	SELECT 
		user_id,
        days_since_last_order,
        total_orders,
        total_spend,
        rfm_score,
		CASE
			-- Best overall customers (High R, High F, High M)
			WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            -- Consistent, high-value repeat buyers
			WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
            -- Recent buyers with lower purchase counts
			WHEN r_score >= 4 AND f_score <= 2 THEN 'Promising/ New'
            -- Formerly frequent/high spenders who haven't ordered recently
            WHEN r_score <= 2 AND (f_score >= 3 OR m_score >= 3) THEN 'At Risk'
            -- Inactive users across all three metrics
			WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost/ Churned'
            -- Catch-all for remaining unclassified score combinations
            ELSE 'Needs Attention'
		END AS customer_status
	FROM rfm_combined
)

-- Final SELECT: Aggregate key performance indicators across customer segments
SELECT 
	customer_status,
    COUNT(DISTINCT user_id) AS num_of_customers,
    ROUND(AVG(total_spend), 2) AS avg_spend,
    ROUND(AVG(days_since_last_order), 2) AS avg_days_since_last_order,
    ROUND(AVG(total_orders), 2) AS avg_orders_per_user
FROM customer_segment
GROUP BY customer_status;