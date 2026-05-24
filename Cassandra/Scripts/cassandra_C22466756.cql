-- ==========================================================
-- Student: C22466756
-- Phase 3: Cassandra Distributed Setup & Experiments
-- ==========================================================

-- ----------------------------------------------------------
-- 1. CLEANUP
-- ----------------------------------------------------------
DROP KEYSPACE IF EXISTS sales_ks_rf1_C22466756;
DROP KEYSPACE IF EXISTS sales_ks_rf3_C22466756;

-- ----------------------------------------------------------
-- 2. SCHEMA SETUP (Replication Factors)
-- ----------------------------------------------------------

-- Scenario A: Low Availability (RF=1)
CREATE KEYSPACE sales_ks_rf1_C22466756 
WITH replication = {'class': 'NetworkTopologyStrategy', 'DC1': 1};

-- Scenario B: High Availability (RF=3)
CREATE KEYSPACE sales_ks_rf3_C22466756 
WITH replication = {'class': 'NetworkTopologyStrategy', 'DC1': 3};

-- ----------------------------------------------------------
-- 3. TABLE DESIGN (Identical in both keyspaces)
-- Uses Collection Datatypes (map, set) for Excellent band.
-- ----------------------------------------------------------

-- Create table in RF=1 Keyspace
USE sales_ks_rf1_C22466756;
CREATE TABLE purchases (
    customer_id int,
    order_id int,
    purchase_date timestamp,
    items map<text, decimal>, 
    tags set<text>,
    total_amount decimal,
    PRIMARY KEY ((customer_id), purchase_date, order_id)
) WITH CLUSTERING ORDER BY (purchase_date DESC);

-- Create table in RF=3 Keyspace
USE sales_ks_rf3_C22466756;
CREATE TABLE purchases (
    customer_id int,
    order_id int,
    purchase_date timestamp,
    items map<text, decimal>, 
    tags set<text>,
    total_amount decimal,
    PRIMARY KEY ((customer_id), purchase_date, order_id)
) WITH CLUSTERING ORDER BY (purchase_date DESC);

-- ----------------------------------------------------------
-- 4. DATA POPULATION (Using Collections)
-- ----------------------------------------------------------
INSERT INTO purchases (customer_id, order_id, purchase_date, total_amount, items, tags) 
VALUES (101, 5001, '2024-01-15 10:00:00', 150.00, {'Laptop': 120.00, 'Mouse': 30.00}, {'Electronics', 'HighValue'});

INSERT INTO purchases (customer_id, order_id, purchase_date, total_amount, items, tags) 
VALUES (102, 5002, '2024-01-16 11:30:00', 20.00, {'Book': 20.00}, {'Books', 'Sale'});

INSERT INTO purchases (customer_id, order_id, purchase_date, total_amount, items, tags) 
VALUES (101, 5003, '2024-02-01 09:00:00', 800.00, {'Phone': 800.00}, {'Electronics'});

-- Verify Data
SELECT * FROM purchases;

-- ----------------------------------------------------------
-- 5. EXPERIMENT A: Healthy Cluster & Tracing
-- ----------------------------------------------------------
TRACING ON;
CONSISTENCY QUORUM;
SELECT * FROM purchases WHERE customer_id = 101;
TRACING OFF;

-- ----------------------------------------------------------
-- 6. EXPERIMENT B: Failure Test (CAP Theorem)
-- ----------------------------------------------------------

-- STEP 1: Execute in separate terminal to simulate failure:
-- BASH: docker stop cassandra3_C22466756
-- BASH: docker exec -it cassandra1_C22466756 nodetool status

-- Test B1: Consistency QUORUM (Availability Wins)
-- With 2/3 nodes up, Quorum is met.
CONSISTENCY QUORUM;
INSERT INTO purchases (customer_id, order_id, purchase_date, total_amount) 
VALUES (999, 1, toTimestamp(now()), 10.00);

-- Test B2: Consistency ALL (Consistency Wins)
-- This is expected to FAIL because Node 3 is down.
-- Proof of CAP trade-off (sacrificing availability for strict consistency).
CONSISTENCY ALL;
INSERT INTO purchases (customer_id, order_id, purchase_date, total_amount) 
VALUES (888, 2, toTimestamp(now()), 20.00);

-- ----------------------------------------------------------
-- 7. CLEANUP & RECOVERY
-- ----------------------------------------------------------

-- STEP 2: Restore the cluster:
-- BASH: docker start cassandra3_C22466756

-- STEP 3: Run repair to synchronise missing data:
-- BASH: docker exec -it cassandra1_C22466756 nodetool repair