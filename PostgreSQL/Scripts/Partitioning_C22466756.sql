-- Set Schema to your specific student schema
SET search_path = dw_lite_C22466756, public;

-- =================================================================
-- 1. RANGE PARTITIONING (Time-Based)
-- Goal: Optimize queries filtering by date (e.g., "Sales in 2024")
-- =================================================================
DROP TABLE IF EXISTS fact_sales_range_C22466756 CASCADE;

CREATE TABLE fact_sales_range_C22466756 (
    date_key int NOT NULL,
    customer_key bigint NOT NULL,
    product_key bigint NOT NULL,
    merchant_key bigint NOT NULL,
    order_id bigint NOT NULL,
    quantity int,
    unit_price numeric(12,2),
    total_sale_amount numeric(14,2),
    -- Partition Key must be part of the primary key
    PRIMARY KEY (date_key, order_id, product_key)
) PARTITION BY RANGE (date_key);

-- Create Partitions (Based on your generated data range)
-- Adjust values if your data is older/newer, but this covers 2023-2025
CREATE TABLE fact_sales_range_2023 PARTITION OF fact_sales_range_C22466756
    FOR VALUES FROM (20230101) TO (20231231);

CREATE TABLE fact_sales_range_2024 PARTITION OF fact_sales_range_C22466756
    FOR VALUES FROM (20240101) TO (20241231);

CREATE TABLE fact_sales_range_2025 PARTITION OF fact_sales_range_C22466756
    FOR VALUES FROM (20250101) TO (20251231);

CREATE TABLE fact_sales_range_default PARTITION OF fact_sales_range_C22466756 DEFAULT;

-- Populate (ETL)
INSERT INTO fact_sales_range_C22466756 
SELECT date_key, customer_key, product_key, merchant_key, order_id, quantity, unit_price, total_sale_amount 
FROM fact_sales;

-- =================================================================
-- 2. LIST PARTITIONING (Region-Based)
-- Goal: Optimize queries filtering by specific regions (e.g. "Ireland")
-- Note: We add 'region_name' to the table to allow this.
-- =================================================================
DROP TABLE IF EXISTS fact_sales_list_C22466756 CASCADE;

CREATE TABLE fact_sales_list_C22466756 (
    region_name text NOT NULL, -- Added specifically for partitioning
    date_key int NOT NULL,
    customer_key bigint NOT NULL,
    product_key bigint NOT NULL,
    order_id bigint NOT NULL,
    total_sale_amount numeric(14,2),
    PRIMARY KEY (region_name, order_id, product_key)
) PARTITION BY LIST (region_name);

-- Create Partitions
CREATE TABLE fact_sales_list_ie PARTITION OF fact_sales_list_C22466756 FOR VALUES IN ('Ireland');
CREATE TABLE fact_sales_list_uk PARTITION OF fact_sales_list_C22466756 FOR VALUES IN ('United Kingdom');
CREATE TABLE fact_sales_list_us PARTITION OF fact_sales_list_C22466756 FOR VALUES IN ('United States');
CREATE TABLE fact_sales_list_eu PARTITION OF fact_sales_list_C22466756 FOR VALUES IN ('Europe');
CREATE TABLE fact_sales_list_default PARTITION OF fact_sales_list_C22466756 DEFAULT;

-- Populate (Join required to get Region Name from Merchant/Region dimension)
INSERT INTO fact_sales_list_C22466756
SELECT 
    m.region_name, 
    f.date_key, f.customer_key, f.product_key, f.order_id, f.total_sale_amount
FROM fact_sales f
JOIN dim_merchant m ON f.merchant_key = m.merchant_key;

-- =================================================================
-- 3. HASH PARTITIONING (Load Balancing)
-- Goal: Evenly distribute data to prevent hotspots (e.g. by Order ID)
-- =================================================================
DROP TABLE IF EXISTS fact_sales_hash_C22466756 CASCADE;

CREATE TABLE fact_sales_hash_C22466756 (
    order_id bigint NOT NULL,
    product_key bigint NOT NULL,
    date_key int,
    total_sale_amount numeric(14,2),
    PRIMARY KEY (order_id, product_key)
) PARTITION BY HASH (order_id);

-- Create 3 Modulo Partitions
CREATE TABLE fact_sales_hash_0 PARTITION OF fact_sales_hash_C22466756 FOR VALUES WITH (MODULUS 3, REMAINDER 0);
CREATE TABLE fact_sales_hash_1 PARTITION OF fact_sales_hash_C22466756 FOR VALUES WITH (MODULUS 3, REMAINDER 1);
CREATE TABLE fact_sales_hash_2 PARTITION OF fact_sales_hash_C22466756 FOR VALUES WITH (MODULUS 3, REMAINDER 2);

-- Populate
INSERT INTO fact_sales_hash_C22466756 
SELECT order_id, product_key, date_key, total_sale_amount 
FROM fact_sales;

-- Analyze to update statistics for accurate query plans
ANALYZE fact_sales_range_C22466756;
ANALYZE fact_sales_list_C22466756;
ANALYZE fact_sales_hash_C22466756;
