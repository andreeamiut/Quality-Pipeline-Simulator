-- ========================================================================================
-- ORACLE 19C SQL QUERIES FOR FQGE STAGE C: DATA PERSISTENCE & CONSISTENCY
-- ========================================================================================
-- Purpose: Collection of SQL queries used by stageC.sh for comprehensive data validation
-- These queries validate data integrity, referential consistency, and business rules
-- Used in the FQGE pipeline to ensure database state meets quality requirements
--
-- Query Categories:
-- 1. Order Status Validation
-- 2. Referential Integrity Checks
-- 3. Data Consistency Validation
-- 4. Performance/Index Validation
-- 5. Data Modification Auditing
-- ========================================================================================

-- ========================================================================================
-- QUERY 1: ORDER STATUS VALIDATION
-- ========================================================================================
-- Purpose: Validate the status of a specific order created in Stage B
-- Used by: stageC.sh execute_sql function
-- Expected: Order should exist and have status "COMPLETED"
-- Parameters: Order ID is passed dynamically from Stage B
-- ========================================================================================
SELECT order_status
FROM orders
WHERE id = 1001;  -- This ID will be replaced with actual ORDER_ID from Stage B

-- ========================================================================================
-- QUERY 2: REFERENTIAL INTEGRITY CHECK (NOT EXISTS VERSION)
-- ========================================================================================
-- Purpose: Find completed orders that lack corresponding invoice records
-- Business Rule: Every completed order must have an invoice
-- Used by: stageC.sh for data consistency validation
-- Method: Uses NOT EXISTS subquery for performance
-- Expected Result: Should return orders 1002 and 1004 (no invoices)
-- ========================================================================================
SELECT id
FROM orders
WHERE order_status = 'COMPLETED'
AND NOT EXISTS (SELECT 1 FROM invoices WHERE order_id = orders.id);

-- ========================================================================================
-- QUERY 3: REFERENTIAL INTEGRITY CHECK (LEFT JOIN VERSION)
-- ========================================================================================
-- Purpose: Alternative method to find completed orders without invoices
-- Business Rule: Every completed order must have an invoice
-- Used by: Alternative validation approach (same result as Query 2)
-- Method: Uses LEFT JOIN to identify NULL relationships
-- Expected Result: Should return orders 1002 and 1004 (no invoices)
-- ========================================================================================
SELECT o.id, o.order_status
FROM orders o
LEFT JOIN invoices i ON o.id = i.order_id
WHERE o.order_status = 'COMPLETED'
AND i.order_id IS NULL;

-- ========================================================================================
-- QUERY 4: COMPREHENSIVE DATA INTEGRITY DASHBOARD
-- ========================================================================================
-- Purpose: Provide a summary of various data quality issues in the database
-- Used by: Data quality monitoring and reporting systems
-- Output: Issue type and count for each data quality problem found
-- Categories:
--   - Orphaned Orders: Orders referencing non-existent customers
--   - Invalid Order Status: Orders with status values outside allowed range
--   - Negative Totals: Orders with negative total amounts
-- ========================================================================================
SELECT
    'Orphaned Orders' as issue_type,           -- Orders without valid customer references
    COUNT(*) as count
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.id
WHERE c.id IS NULL
UNION ALL
SELECT
    'Invalid Order Status' as issue_type,      -- Orders with invalid status values
    COUNT(*) as count
FROM orders
WHERE order_status NOT IN ('PENDING', 'PROCESSING', 'COMPLETED', 'CANCELLED')
UNION ALL
SELECT
    'Negative Totals' as issue_type,           -- Orders with negative amounts
    COUNT(*) as count
FROM orders
WHERE total < 0;

-- ========================================================================================
-- QUERY 5: INDEX VALIDATION AND PERFORMANCE CHECK
-- ========================================================================================
-- Purpose: Verify that required indexes exist for optimal query performance
-- Used by: Database performance monitoring and optimization
-- Output: List of indexes with their table and column mappings
-- Validates: Indexes created in oracle_setup.sql are present
-- ========================================================================================
SELECT index_name, table_name, column_name
FROM all_ind_columns
WHERE table_name IN ('ORDERS', 'INVOICES', 'CUSTOMERS')
ORDER BY table_name, index_name;

-- ========================================================================================
-- QUERY 6: DATA MODIFICATION AUDIT (LAST 24 HOURS)
-- ========================================================================================
-- Purpose: Track recent data changes for audit and monitoring purposes
-- Used by: Data governance and change tracking systems
-- Output: Summary of inserts, updates, deletes by table (last 24 hours)
-- Note: This is a simplified audit - production systems would use audit trails
-- ========================================================================================
SELECT
    table_name,
    inserts,
    updates,
    deletes
FROM (
    SELECT
        'ORDERS' as table_name,
        (SELECT COUNT(*) FROM orders WHERE created_date >= SYSDATE - 1) as inserts,      -- New orders in last 24h
        (SELECT COUNT(*) FROM orders WHERE updated_date >= SYSDATE - 1 AND created_date < SYSDATE - 1) as updates, -- Modified existing orders
        0 as deletes -- Assuming soft deletes or no delete tracking in this schema
    FROM dual
    UNION ALL
    SELECT
        'INVOICES' as table_name,
        (SELECT COUNT(*) FROM invoices WHERE created_date >= SYSDATE - 1) as inserts,   -- New invoices in last 24h
        (SELECT COUNT(*) FROM invoices WHERE updated_date >= SYSDATE - 1 AND created_date < SYSDATE - 1) as updates, -- Modified existing invoices
        0 as deletes -- Assuming soft deletes or no delete tracking in this schema
    FROM dual
) stats;

-- ========================================================================================
-- USAGE NOTES:
-- - Query 1: Used by stageC.sh to validate specific order status
-- - Query 2: Used by stageC.sh for referential integrity validation (MINUS version)
-- - Query 3: Alternative approach for referential integrity (JOIN version)
-- - Query 4: Comprehensive data quality dashboard for monitoring
-- - Query 5: Performance validation - ensures indexes are in place
-- - Query 6: Audit trail for recent data modifications
-- ========================================================================================