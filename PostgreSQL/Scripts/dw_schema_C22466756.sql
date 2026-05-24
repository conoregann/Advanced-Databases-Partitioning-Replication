-- ===============================================
-- dw_schema_C22466756.sql
-- This script defines the complete star schema for the data warehouse.
-- Student ID: C22466756
-- ===============================================

-- Drop and create the schema to ensure a clean slate
-- Schema name includes student number as required by the rubric
DROP SCHEMA IF EXISTS dw_lite_C22466756 CASCADE;
CREATE SCHEMA dw_lite_C22466756;
SET search_path = dw_lite_C22466756, public;

-- -------------------------
-- DIMENSIONS (from scaffold, but included for completeness)
-- -------------------------

CREATE TABLE dim_date (
  date_key int PRIMARY KEY,
  date_actual date NOT NULL,
  year int NOT NULL,
  month int NOT NULL,
  day int NOT NULL
);

CREATE TABLE dim_customer (
  customer_key bigint PRIMARY KEY,
  region text,
  full_name text,
  age_band text
);

CREATE TABLE dim_product (
  product_key bigint PRIMARY KEY,
  category text,
  merchant text,
  price numeric(12,2)
);

-- -------------------------
-- NEW DIMENSION: dim_merchant
-- Required for merchant-based analysis
-- -------------------------
CREATE TABLE dim_merchant (
    merchant_key bigserial PRIMARY KEY,
    merchant_id bigint NOT NULL,
    merchant_name text NOT NULL,
    region_name text NOT NULL
);


-- -------------------------
-- FACT TABLE (Fully Defined)
-- Grain: One row per order item (atomic grain)
-- This allows for maximum flexibility in analysis.
-- -------------------------

CREATE TABLE fact_sales (
  -- Foreign keys to dimension tables
  date_key int NOT NULL REFERENCES dim_date(date_key),
  customer_key bigint NOT NULL REFERENCES dim_customer(customer_key),
  product_key bigint NOT NULL REFERENCES dim_product(product_key),
  merchant_key bigint NOT NULL REFERENCES dim_merchant(merchant_key),

  -- Degenerate Dimension: The original order ID is kept for reference
  order_id bigint NOT NULL,

  -- Additive Numeric Facts (Measures)
  quantity int NOT NULL,
  unit_price numeric(12,2) NOT NULL,
  discount numeric(12,2) NOT NULL,
  total_sale_amount numeric(14,2) NOT NULL,

  -- JSONB column for semi-structured data, as required
  order_metadata jsonb,

  -- Composite primary key based on the grain
  PRIMARY KEY (order_id, product_key)
);

-- Indexing on foreign keys is crucial for join performance
CREATE INDEX ON fact_sales(date_key);
CREATE INDEX ON fact_sales(customer_key);
CREATE INDEX ON fact_sales(product_key);
CREATE INDEX ON fact_sales(merchant_key);