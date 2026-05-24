-- ===============================================
-- dw_etl_C22466756.sql
-- This script populates the data warehouse from the rel_src schema.
-- Student ID: C22466756
-- ===============================================

-- Set the search path to your new schema
SET search_path = dw_lite_c22466756, public;

-- -------------------------
-- 1. POPULATE DIMENSIONS (from scaffold)
-- These should be run first to ensure referential integrity.
-- -------------------------
INSERT INTO dim_date(date_key, date_actual, year, month, day)
SELECT to_char(d,'YYYYMMDD')::int, d,
       EXTRACT(YEAR FROM d)::int,
       EXTRACT(MONTH FROM d)::int,
       EXTRACT(DAY FROM d)::int
FROM generate_series(current_date - interval '90 days', current_date, interval '1 day') d;

INSERT INTO dim_customer(customer_key, region, full_name, age_band)
SELECT c.customer_id,
       r.region_name,
       c.full_name,
       c.attributes ->> 'age_band'
FROM rel_src.customers c
JOIN rel_src.regions r ON r.region_id = c.region_id;

INSERT INTO dim_product(product_key, category, merchant, price)
SELECT p.product_id,
       cat.category_name,
       m.merchant_name,
       p.base_price
FROM rel_src.products p
JOIN rel_src.categories cat ON cat.category_id = p.category_id
JOIN rel_src.merchants m ON m.merchant_id = p.merchant_id;

-- -------------------------
-- 2. POPULATE NEW dim_merchant TABLE
-- -------------------------
INSERT INTO dim_merchant(merchant_id, merchant_name, region_name)
SELECT
    m.merchant_id,
    m.merchant_name,
    r.region_name
FROM rel_src.merchants m
JOIN rel_src.regions r ON m.region_id = r.region_id;


-- -------------------------
-- 3. POPULATE THE fact_sales TABLE
-- This is the main ETL step, joining transactional tables to dimensions.
-- -------------------------
-- -------------------------
-- 3. POPULATE THE fact_sales TABLE
-- This is the main ETL step, joining transactional tables to dimensions.
-- -------------------------
INSERT INTO fact_sales (
    date_key,
    customer_key,
    product_key,
    merchant_key,
    order_id,
    quantity,
    unit_price,
    discount,
    total_sale_amount,
    order_metadata
)
SELECT
    -- Dimension Keys (used for grouping)
    d.date_key,
    o.customer_id,
    oi.product_id,
    m.merchant_key,
    o.order_id,

    -- Aggregated Numeric Facts
    SUM(oi.quantity) AS quantity,
    AVG(oi.unit_price) AS unit_price, -- Use AVG for price as it might vary per item_no
    SUM(oi.discount) AS discount,
    SUM(oi.quantity * oi.unit_price - oi.discount) AS total_sale_amount,

    -- Cast jsonb to text to use MIN/MAX, then cast result back to jsonb for the fact table
    MIN(o.meta::text)::jsonb AS order_metadata
FROM
    rel_src.order_items oi
JOIN
    rel_src.orders o ON oi.order_id = o.order_id
JOIN
    dim_date d ON d.date_actual = o.order_date
JOIN
    dim_merchant m ON m.merchant_id = o.merchant_id
GROUP BY
    d.date_key,
    o.customer_id,
    oi.product_id,
    m.merchant_key,
    o.order_id;

-- Refresh statistics after a large data load for the query planner
ANALYZE;