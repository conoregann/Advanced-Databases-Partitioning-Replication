--
-- RANGE PARTITIONING
--

-- 1. Baseline (Non-Partitioned)
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM dw_lite_c22466756.fact_sales WHERE date_key BETWEEN 20250101 AND 20250131;

-- 2. Partitioned (Range)
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM dw_lite_c22466756.fact_sales_range_C22466756 WHERE date_key BETWEEN 20250101 AND 20250131;


--
-- LIST PARTITIONING
--

-- 1. Baseline (Requires Join - Expensive)
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM dw_lite_c22466756.fact_sales f 
JOIN dw_lite_c22466756.dim_merchant m ON f.merchant_key = m.merchant_key
WHERE m.region_name = 'Ireland';

-- 2. Partitioned (List - No Join needed, plus Pruning)
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM dw_lite_c22466756.fact_sales_list_C22466756 WHERE region_name = 'Ireland';

--
-- HASH PARTITIONING
--

-- 1. Baseline (Non-Partitioned)
-- This will likely result in a Parallel Seq Scan or Index Scan on the whole table
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM dw_lite_c22466756.fact_sales WHERE order_id = 5000;

-- 2. Partitioned (Hash)
-- PostgreSQL will use the hash function to jump directly to the specific partition
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM dw_lite_c22466756.fact_sales_hash_C22466756 WHERE order_id = 5000;








