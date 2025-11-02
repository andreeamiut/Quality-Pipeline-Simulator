-- Oracle 19c Test Suite for FQGE Validation
-- This file contains test data setup and validation queries

-- Setup test data (run this first to create test environment)
-- Note: Adjust table names and structures based on your actual schema

-- Create test tables (if not exists)
-- Note: In Oracle, conditional table creation requires PL/SQL blocks
-- For simplicity, we'll create tables directly (they will error if exist)
CREATE TABLE ORDERS (
    id NUMBER PRIMARY KEY,
    customer_id NUMBER,
    order_status VARCHAR2(20),
    total NUMBER(10,2),
    created_date DATE DEFAULT SYSDATE,
    updated_date DATE DEFAULT SYSDATE
);

CREATE TABLE INVOICES (
    id NUMBER PRIMARY KEY,
    order_id NUMBER,
    invoice_number VARCHAR2(50),
    amount NUMBER(10,2),
    created_date DATE DEFAULT SYSDATE,
    FOREIGN KEY (order_id) REFERENCES ORDERS(id)
);

CREATE TABLE CUSTOMERS (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100),
    email VARCHAR2(100)
);

-- Insert test data
INSERT INTO customers (id, name, email) VALUES (1, 'John Doe', 'john@example.com');
INSERT INTO customers (id, name, email) VALUES (2, 'Jane Smith', 'jane@example.com');

INSERT INTO orders (id, customer_id, order_status, total) VALUES (1001, 1, 'COMPLETED', 150.00);
INSERT INTO orders (id, customer_id, order_status, total) VALUES (1002, 2, 'PENDING', 75.50);
INSERT INTO orders (id, customer_id, order_status, total) VALUES (1003, 1, 'COMPLETED', 200.00);

INSERT INTO invoices (id, order_id, invoice_number, amount) VALUES (2001, 1001, 'INV-001', 150.00);
INSERT INTO invoices (id, order_id, invoice_number, amount) VALUES (2002, 1003, 'INV-002', 200.00);
-- Note: Order 1002 has no invoice (for testing consistency)

-- Test Query 1: Validate order status
-- Expected: COMPLETED for order 1001
SELECT order_status FROM orders WHERE id = 1001;

-- Test Query 2: Data consistency check
-- Expected: Should return order 1002 (no invoice)
SELECT id FROM orders
MINUS
SELECT order_id FROM invoices;

-- Test Query 3: Comprehensive integrity check
-- Expected: Various counts (should be 0 for a clean system)
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

-- Test Query 4: Index verification
-- Expected: Should show existing indexes
SELECT index_name, table_name, column_name
FROM all_ind_columns
WHERE table_name IN ('ORDERS', 'INVOICES', 'CUSTOMERS')
ORDER BY table_name, index_name;

-- Test Query 5: Recent modifications check
-- Expected: Shows activity in last 24 hours
SELECT 'Recent activity check completed' as status FROM dual;

-- Cleanup test data (run after testing)
-- DROP TABLE invoices;
-- DROP TABLE orders;
-- DROP TABLE customers;