-- Oracle 19c Test Runner for FQGE Validation
-- Execute this script to run all validation tests

SET SERVEROUTPUT ON
SET FEEDBACK ON
SET VERIFY OFF

-- Test Variables
DEFINE test_order_id = 1001
DEFINE expected_status = 'COMPLETED'

PROMPT ========================================
PROMPT FQGE Oracle Validation Test Suite
PROMPT ========================================

-- Test 1: Order Status Validation
PROMPT
PROMPT Test 1: Order Status Validation
PROMPT Expected: &expected_status for order ID &test_order_id

DECLARE
    v_status VARCHAR2(20);
BEGIN
    SELECT order_status INTO v_status
    FROM orders
    WHERE id = &test_order_id;

    IF v_status = '&expected_status' THEN
        DBMS_OUTPUT.PUT_LINE('✓ PASS: Order status is ' || v_status);
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ FAIL: Order status is ' || v_status || ', expected &expected_status');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('✗ FAIL: Order ID &test_order_id not found');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ FAIL: Unexpected error - ' || SQLERRM);
END;
/

-- Test 2: Data Consistency Check (MINUS query)
PROMPT
PROMPT Test 2: Data Consistency Check
PROMPT Expected: 0 rows (no inconsistencies)

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM (
        SELECT id
        FROM orders
        WHERE order_status = 'COMPLETED'
        MINUS
        SELECT order_id
        FROM invoices
    );

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('✓ PASS: No data inconsistencies found');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ FAIL: Found ' || v_count || ' data inconsistencies');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ FAIL: Error in consistency check - ' || SQLERRM);
END;
/

-- Test 3: Data Integrity Check
PROMPT
PROMPT Test 3: Data Integrity Check
PROMPT Expected: All issue counts should be 0

DECLARE
    v_orphaned_orders NUMBER := 0;
    v_invalid_status NUMBER := 0;
    v_negative_totals NUMBER := 0;
    v_duplicate_invoices NUMBER := 0;
BEGIN
    -- Check for orphaned orders
    SELECT COUNT(*) INTO v_orphaned_orders
    FROM orders o
    LEFT JOIN customers c ON o.customer_id = c.id
    WHERE c.id IS NULL;

    -- Check for invalid status
    SELECT COUNT(*) INTO v_invalid_status
    FROM orders
    WHERE order_status NOT IN ('PENDING', 'PROCESSING', 'COMPLETED', 'CANCELLED');

    -- Check for negative totals
    SELECT COUNT(*) INTO v_negative_totals
    FROM orders
    WHERE total < 0;

    -- Check for duplicate invoices
    SELECT COUNT(*) INTO v_duplicate_invoices
    FROM (
        SELECT order_id
        FROM invoices
        GROUP BY order_id
        HAVING COUNT(*) > 1
    );

    IF v_orphaned_orders = 0 AND v_invalid_status = 0 AND v_negative_totals = 0 AND v_duplicate_invoices = 0 THEN
        DBMS_OUTPUT.PUT_LINE('✓ PASS: All data integrity checks passed');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ FAIL: Data integrity issues found:');
        DBMS_OUTPUT.PUT_LINE('  - Orphaned orders: ' || v_orphaned_orders);
        DBMS_OUTPUT.PUT_LINE('  - Invalid status: ' || v_invalid_status);
        DBMS_OUTPUT.PUT_LINE('  - Negative totals: ' || v_negative_totals);
        DBMS_OUTPUT.PUT_LINE('  - Duplicate invoices: ' || v_duplicate_invoices);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ FAIL: Error in integrity check - ' || SQLERRM);
END;
/

-- Test 4: Index Verification
PROMPT
PROMPT Test 4: Index Verification
PROMPT Expected: Required indexes exist

DECLARE
    v_index_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_index_count
    FROM all_ind_columns
    WHERE table_name IN ('ORDERS', 'INVOICES', 'CUSTOMERS')
    AND column_name IN ('ID', 'ORDER_ID', 'CUSTOMER_ID', 'ORDER_STATUS');

    IF v_index_count >= 4 THEN  -- At least ID indexes on main tables
        DBMS_OUTPUT.PUT_LINE('✓ PASS: Found ' || v_index_count || ' relevant indexes');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ WARNING: Only found ' || v_index_count || ' relevant indexes (expected >= 4)');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ FAIL: Error checking indexes - ' || SQLERRM);
END;
/

-- Test 5: Recent Data Check
PROMPT
PROMPT Test 5: Recent Data Activity
PROMPT Expected: Shows recent modifications

DECLARE
    v_orders_recent NUMBER;
    v_invoices_recent NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_orders_recent
    FROM orders
    WHERE created_date >= SYSDATE - 1;

    SELECT COUNT(*) INTO v_invoices_recent
    FROM invoices
    WHERE created_date >= SYSDATE - 1;

    DBMS_OUTPUT.PUT_LINE('✓ INFO: Recent orders (24h): ' || v_orders_recent);
    DBMS_OUTPUT.PUT_LINE('✓ INFO: Recent invoices (24h): ' || v_invoices_recent);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ FAIL: Error checking recent data - ' || SQLERRM);
END;
/

PROMPT
PROMPT ========================================
PROMPT Test Suite Complete
PROMPT ========================================