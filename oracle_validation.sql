-- Oracle 19c Validation Queries for FQGE Stage C
-- These are the exact queries used by stageC.sh

-- Query 1: Validate order status for a specific order ID
-- Input: order_id = order_id from Stage B
-- Expected: Single row with "COMPLETED"
SELECT order_status
FROM orders
WHERE id = 1001;

-- Query 2: Data consistency check using LEFT JOIN
-- Find orders that are COMPLETED but don't have corresponding invoices
-- Expected: Zero rows for data consistency
SELECT o.id
FROM orders o
LEFT JOIN invoices i ON o.id = i.order_id
WHERE o.order_status = 'COMPLETED'
AND i.order_id IS NULL;

-- Query 3: Alternative consistency check using LEFT JOIN
-- Find completed orders without invoices
-- Expected: Zero rows
SELECT o.id, o.order_status
FROM orders o
LEFT JOIN invoices i ON o.id = i.order_id
WHERE o.order_status = 'COMPLETED'
AND i.order_id IS NULL;

-- Query 4: Data integrity verification
-- Check for various data quality issues
-- Expected: All counts should be 0
SELECT
    'Orphaned Orders' as issue_type,
    COUNT(*) as issue_count
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.id
WHERE c.id IS NULL
UNION ALL
SELECT
    'Invalid Status' as issue_type,
    COUNT(*) as issue_count
FROM orders
WHERE order_status NOT IN ('PENDING', 'PROCESSING', 'COMPLETED', 'CANCELLED')
UNION ALL
SELECT
    'Negative Totals' as issue_type,
    COUNT(*) as issue_count
FROM orders
WHERE total < 0
UNION ALL
SELECT
    'Duplicate Invoices' as issue_type,
    COUNT(*) as issue_count
FROM (
    SELECT order_id, COUNT(*) as cnt
    FROM invoices
    GROUP BY order_id
    HAVING COUNT(*) > 1
) subquery;

-- Query 5: Index existence check
-- Verify that required indexes exist for performance
SELECT
    table_name,
    index_name,
    column_name,
    'EXISTS' as status
FROM all_ind_columns
WHERE table_name IN ('ORDERS', 'INVOICES', 'CUSTOMERS')
AND column_name IN ('ID', 'ORDER_ID', 'CUSTOMER_ID', 'ORDER_STATUS')
ORDER BY table_name, index_name;

-- Query 6: Recent data validation (last 24 hours)
-- Check for recent data modifications
SELECT
    'ORDERS' as table_name,
    COUNT(CASE WHEN created_date >= SYSDATE - 1 THEN 1 END) as inserts_24h,
    COUNT(CASE WHEN updated_date >= SYSDATE - 1 AND created_date < SYSDATE - 1 THEN 1 END) as updates_24h
FROM orders
UNION ALL
SELECT
    'INVOICES' as table_name,
    COUNT(CASE WHEN created_date >= SYSDATE - 1 THEN 1 END) as inserts_24h,
    COUNT(CASE WHEN updated_date >= SYSDATE - 1 AND created_date < SYSDATE - 1 THEN 1 END) as updates_24h
FROM invoices
UNION ALL
SELECT
    'CUSTOMERS' as table_name,
    COUNT(CASE WHEN created_date >= SYSDATE - 1 THEN 1 END) as inserts_24h,
    COUNT(CASE WHEN updated_date >= SYSDATE - 1 AND created_date < SYSDATE - 1 THEN 1 END) as updates_24h
FROM customers;