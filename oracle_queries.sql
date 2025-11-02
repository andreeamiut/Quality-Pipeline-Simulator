-- Oracle 19c SQL Queries for FQGE Stage C: Data Persistence & Consistency
-- These queries are used by stageC.sh for validation

-- Query 1: Validate order status for a specific order ID
-- Used to check if order_status is "COMPLETED"
SELECT order_status
FROM orders
WHERE id = 1001;

-- Query 2: Data consistency check using NOT EXISTS
-- Find orders that are completed but don't have corresponding invoices
SELECT id
FROM orders
WHERE order_status = 'COMPLETED'
AND NOT EXISTS (SELECT 1 FROM invoices WHERE order_id = id);

-- Query 3: Alternative consistency check using JOIN
-- Find orders with status COMPLETED that have no matching invoice
SELECT o.id, o.order_status
FROM orders o
LEFT JOIN invoices i ON o.id = i.order_id
WHERE o.order_status = 'COMPLETED'
AND i.order_id IS NULL;

-- Query 4: Comprehensive data integrity check
-- Check for various data consistency issues
SELECT
    'Orphaned Orders' as issue_type,
    COUNT(*) as count
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.id
WHERE c.id IS NULL
UNION ALL
SELECT
    'Invalid Order Status' as issue_type,
    COUNT(*) as count
FROM orders
WHERE order_status NOT IN ('PENDING', 'PROCESSING', 'COMPLETED', 'CANCELLED')
UNION ALL
SELECT
    'Negative Totals' as issue_type,
    COUNT(*) as count
FROM orders
WHERE total < 0;

-- Query 5: Performance check - ensure indexes exist
SELECT index_name, table_name, column_name
FROM all_ind_columns
WHERE table_name IN ('ORDERS', 'INVOICES', 'CUSTOMERS')
ORDER BY table_name, index_name;

-- Query 6: Check for recent data modifications (last 24 hours)
SELECT
    table_name,
    inserts,
    updates,
    deletes
FROM (
    SELECT
        'ORDERS' as table_name,
        (SELECT COUNT(*) FROM orders WHERE created_date >= SYSDATE - 1) as inserts,
        (SELECT COUNT(*) FROM orders WHERE updated_date >= SYSDATE - 1 AND created_date < SYSDATE - 1) as updates,
        0 as deletes -- Assuming soft deletes or no delete tracking
    FROM dual
    UNION ALL
    SELECT
        'INVOICES' as table_name,
        (SELECT COUNT(*) FROM invoices WHERE created_date >= SYSDATE - 1) as inserts,
        (SELECT COUNT(*) FROM invoices WHERE updated_date >= SYSDATE - 1 AND created_date < SYSDATE - 1) as updates,
        0 as deletes
    FROM dual
) stats;