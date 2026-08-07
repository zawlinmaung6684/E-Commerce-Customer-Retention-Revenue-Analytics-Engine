# 1. Overall Conversion Funnel & Drop-Off Ratios
WITH event_status AS (
	SELECT 
		session_id,
		MAX(CASE WHEN event_type = 'page_view' THEN 1 ELSE 0 END) AS page_view,
		MAX(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS add_to_cart,
		MAX(CASE WHEN event_type = 'checkout_start' THEN 1 ELSE 0 END) AS checkout_start,
		MAX(CASE WHEN event_type = 'payment_info' THEN 1 ELSE 0 END) AS payment_info,
		MAX(CASE WHEN event_type = 'purchase_complete' THEN 1 ELSE 0 END) AS purchase_complete
	FROM web_logs
	GROUP BY session_id
)
SELECT 
	COUNT(DISTINCT session_id) AS total_sessions,
    
    -- Step Counts
    SUM(page_view) AS page_views,
    SUM(add_to_cart) AS add_to_carts,
    SUM(checkout_start) AS checkout_starts,
    SUM(payment_info) AS payment_infos,
    SUM(purchase_complete) AS purhcases,
    
    -- Step-over-step Drop-off Percentages
    1.0 - (SUM(add_to_cart) / SUM(page_view)) AS page_to_cart_dropoff,
    1.0 - (SUM(checkout_start) / SUM(add_to_cart)) AS cart_to_checkout_dropoff,
    1.0 - (SUM(payment_info) / SUM(checkout_start)) AS checkout_to_payment_dropoff,
    1.0 - (SUM(purchase_complete) / SUM(payment_info)) AS payment_to_purchase_dropoff,

	-- Overall Conversion Rate
    SUM(purchase_complete)/ COUNT(DISTINCT session_id) AS overall_conversion_rt
FROM event_status;

# 2. Funnel Conversion by Device & Browser
SELECT
    device_type,
    COUNT(DISTINCT session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN session_id END) AS checkout_sessions,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase_complete' THEN session_id END) AS purchase_sessions,
    
    -- Funnel Step 1: % of total sessions that start checkout
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN session_id END) / COUNT(DISTINCT session_id), 2) AS checkout_rate_pct,
    
    -- Funnel Step 2: % of checkouts that finish purchase (Identifies Checkout Friction)
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN event_type = 'purchase_complete' THEN session_id END) / NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN session_id END), 0), 2) AS checkout_completion_pct,
    
    -- Overall Conversion Rate
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN event_type = 'purchase_complete' THEN session_id END) / COUNT(DISTINCT session_id), 2) AS overall_conversion_pct
FROM web_logs
GROUP BY device_type
ORDER BY overall_conversion_pct DESC;

SELECT
    browser,
    COUNT(DISTINCT session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN session_id END) AS checkout_sessions,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase_complete' THEN session_id END) AS purchase_sessions,
    
    -- Funnel Step 1: % of total sessions that start checkout
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN session_id END) / COUNT(DISTINCT session_id), 2) AS checkout_rate_pct,
    
    -- Funnel Step 2: % of checkouts that finish purchase (Identifies Checkout Friction)
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN event_type = 'purchase_complete' THEN session_id END) / NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN session_id END), 0), 2) AS checkout_completion_pct,
    
    -- Overall Conversion Rate
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN event_type = 'purchase_complete' THEN session_id END) / COUNT(DISTINCT session_id), 2) AS overall_conversion_pct
FROM web_logs
GROUP BY browser
ORDER BY overall_conversion_pct DESC;

# 3. Session Duration and Time-to-Convert
WITH session_duration AS (
	SELECT
		session_id,
		MIN(event_timestamp) AS session_start,
		MAX(event_timestamp) AS session_end,
		TIMESTAMPDIFF(SECOND, MIN(event_timestamp), MAX(event_timestamp)) AS session_duration_seconds,
        -- Use MAX to treat this as a true/false flag (1 if at least one purchase occurred)
		MAX(CASE WHEN event_type = 'purchase_complete' THEN 1 ELSE 0 END) AS is_converted
	FROM web_logs
	GROUP BY session_id
)
SELECT 
	CASE
		WHEN is_converted = 1 THEN 'yes' 
        ELSE 'no'
    END AS is_converted,
    ROUND(AVG(session_duration_seconds) / 60.0, 2) avg_session_duration_mins
FROM session_duration
GROUP BY is_converted
ORDER BY is_converted DESC;
