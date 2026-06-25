-- ═══════════════════════════════════════
-- QUERY 1: Revenue, Profit & Orders
--          by Region
-- ═══════════════════════════════════════
USE superstore_sales;

SELECT
    c.region,
    COUNT(DISTINCT o.order_id)       AS total_orders,
    ROUND(SUM(od.sales), 2)          AS total_revenue,
    ROUND(SUM(od.profit), 2)         AS total_profit,
    ROUND(SUM(od.profit)
        / SUM(od.sales) * 100, 2)    AS profit_margin_pct
        

FROM orders o
JOIN customers   c  ON o.customer_id  = c.customer_id
JOIN order_details od ON o.order_id   = od.order_id
GROUP BY c.region
ORDER BY total_revenue DESC;




-- ═══════════════════════════════════════
-- QUERY 2: Month over Month Revenue
--          Growth using Window Functions
-- ═══════════════════════════════════════

WITH monthly_revenue AS (
    SELECT
        YEAR(o.order_date)                    AS order_year,
        MONTH(o.order_date)                   AS order_month,
        ROUND(SUM(od.sales), 2)               AS total_revenue
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY
        YEAR(o.order_date),
        MONTH(o.order_date)
)
SELECT
    order_year,
    order_month,
    total_revenue,
    LAG(total_revenue) OVER (
        ORDER BY order_year, order_month
    )                                         AS prev_month_revenue,
    ROUND(total_revenue - LAG(total_revenue) OVER (
        ORDER BY order_year, order_month), 2) AS revenue_change,
    ROUND((total_revenue - LAG(total_revenue) OVER (
        ORDER BY order_year, order_month))
        / LAG(total_revenue) OVER (
        ORDER BY order_year, order_month)
        * 100, 2)                             AS growth_pct
FROM monthly_revenue
ORDER BY order_year, order_month;



-- ═══════════════════════════════════════
-- QUERY 3: Top 10 Customers by Revenue
--          with Ranking using RANK()
-- ═══════════════════════════════════════

WITH customer_summary AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.segment,
        c.region,
        COUNT(DISTINCT o.order_id)    AS total_orders,
        ROUND(SUM(od.sales), 2)       AS total_revenue,
        ROUND(SUM(od.profit), 2)      AS total_profit,
        ROUND(SUM(od.profit)
            / SUM(od.sales) * 100, 2) AS profit_margin_pct
    FROM customers c
    JOIN orders       o  ON c.customer_id = o.customer_id
    JOIN order_details od ON o.order_id   = od.order_id
    GROUP BY
        c.customer_id,
        c.customer_name,
        c.segment,
        c.region
)
SELECT
    RANK() OVER (
        ORDER BY total_revenue DESC
    )                  AS revenue_rank,
    customer_name,
    segment,
    region,
    total_orders,
    total_revenue,
    total_profit,
    profit_margin_pct
FROM customer_summary
LIMIT 10;



-- ═══════════════════════════════════════
-- QUERY 4: Category & Sub-Category
--          Performance Analysis
-- ═══════════════════════════════════════

SELECT
    p.category,
    p.sub_category,
    COUNT(DISTINCT o.order_id)        AS total_orders,
    ROUND(SUM(od.sales), 2)           AS total_revenue,
    ROUND(SUM(od.profit), 2)          AS total_profit,
    ROUND(SUM(od.profit)
        / SUM(od.sales) * 100, 2)     AS profit_margin_pct,
    ROUND(AVG(od.discount) * 100, 2)  AS avg_discount_pct,
    RANK() OVER (
        PARTITION BY p.category
        ORDER BY SUM(od.sales) DESC
    )                                  AS rank_within_category
FROM products p
JOIN order_details od ON p.product_id = od.product_id
JOIN orders       o  ON od.order_id   = o.order_id
GROUP BY
    p.category,
    p.sub_category
ORDER BY
    p.category,
    total_revenue DESC;
    
    
    -- ═══════════════════════════════════════
-- QUERY 5: Year over Year Sales Growth
--          by Customer Segment
-- ═══════════════════════════════════════

WITH yearly_segment AS (
    SELECT
        YEAR(o.order_date)            AS order_year,
        c.segment,
        ROUND(SUM(od.sales), 2)       AS total_revenue,
        ROUND(SUM(od.profit), 2)      AS total_profit,
        COUNT(DISTINCT o.order_id)    AS total_orders
    FROM orders o
    JOIN customers    c  ON o.customer_id = c.customer_id
    JOIN order_details od ON o.order_id   = od.order_id
    GROUP BY
        YEAR(o.order_date),
        c.segment
)
SELECT
    order_year,
    segment,
    total_revenue,
    total_profit,
    total_orders,
    LAG(total_revenue) OVER (
        PARTITION BY segment
        ORDER BY order_year
    )                                  AS prev_year_revenue,
    ROUND(total_revenue - LAG(total_revenue) OVER (
        PARTITION BY segment
        ORDER BY order_year), 2)       AS revenue_change,
    ROUND((total_revenue - LAG(total_revenue) OVER (
        PARTITION BY segment
        ORDER BY order_year))
        / LAG(total_revenue) OVER (
        PARTITION BY segment
        ORDER BY order_year)
        * 100, 2)                      AS yoy_growth_pct
FROM yearly_segment
ORDER BY segment, order_year;


-- ═══════════════════════════════════════
-- QUERY 6: Discount Impact on
--          Profitability Analysis
-- ═══════════════════════════════════════

WITH discount_bands AS (
    SELECT
        od.order_id,
        od.product_id,
        od.sales,
        od.profit,
        od.discount,
        od.quantity,
        CASE
            WHEN od.discount = 0         THEN '0% No Discount'
            WHEN od.discount <= 0.10     THEN '1-10% Low'
            WHEN od.discount <= 0.20     THEN '11-20% Medium'
            WHEN od.discount <= 0.30     THEN '21-30% High'
            ELSE                              '30%+ Extreme'
        END AS discount_band
    FROM order_details od
)
SELECT
    discount_band,
    COUNT(*)                           AS total_transactions,
    ROUND(SUM(sales), 2)               AS total_revenue,
    ROUND(SUM(profit), 2)              AS total_profit,
    ROUND(AVG(profit), 2)              AS avg_profit_per_order,
    ROUND(SUM(profit)
        / SUM(sales) * 100, 2)         AS profit_margin_pct,
    ROUND(AVG(discount) * 100, 2)      AS avg_discount_pct
FROM discount_bands
GROUP BY discount_band
ORDER BY avg_discount_pct;