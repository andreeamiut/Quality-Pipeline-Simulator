-- Oracle 19c Database Setup for FQGE Testing
-- Run this script to set up the test environment

-- Create test schema/user (run as DBA)
-- CREATE USER fqge_test IDENTIFIED BY test_password;
-- GRANT CONNECT, RESOURCE TO fqge_test;
-- ALTER USER fqge_test QUOTA UNLIMITED ON USERS;

-- Switch to test schema
-- ALTER SESSION SET CURRENT_SCHEMA = fqge_test;

-- Create test tables
CREATE TABLE orders (
    id NUMBER PRIMARY KEY,
    customer_id NUMBER,
    order_status VARCHAR2(20) CHECK (order_status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'CANCELLED')),
    total NUMBER(10,2) CHECK (total >= 0),
    created_date DATE DEFAULT SYSDATE,
    updated_date DATE DEFAULT SYSDATE
);

CREATE TABLE invoices (
    id NUMBER PRIMARY KEY,
    order_id NUMBER,
    invoice_number VARCHAR2(50) UNIQUE,
    amount NUMBER(10,2),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_invoice_order FOREIGN KEY (order_id) REFERENCES orders(id)
);

CREATE TABLE customers (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    email VARCHAR2(100) UNIQUE
);

-- Create indexes for performance
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_invoices_order ON invoices(order_id);
CREATE INDEX idx_customers_email ON customers(email);

-- Insert test data
INSERT INTO customers (id, name, email) VALUES (1, 'John Doe', 'john@example.com');
INSERT INTO customers (id, name, email) VALUES (2, 'Jane Smith', 'jane@example.com');
INSERT INTO customers (id, name, email) VALUES (3, 'Bob Johnson', 'bob@example.com');

INSERT INTO orders (id, customer_id, order_status, total) VALUES (1001, 1, 'COMPLETED', 150.00);
INSERT INTO orders (id, customer_id, order_status, total) VALUES (1002, 2, 'PENDING', 75.50);
INSERT INTO orders (id, customer_id, order_status, total) VALUES (1003, 1, 'COMPLETED', 200.00);
INSERT INTO orders (id, customer_id, order_status, total) VALUES (1004, 3, 'PROCESSING', 125.25);

INSERT INTO invoices (id, order_id, invoice_number, amount) VALUES (2001, 1001, 'INV-001', 150.00);
INSERT INTO invoices (id, order_id, invoice_number, amount) VALUES (2002, 1003, 'INV-002', 200.00);
-- Note: Orders 1002 and 1004 have no invoices (for testing consistency)

COMMIT;

-- Verification queries
SELECT CONCAT('Orders count: ', TO_CHAR(COUNT(*))) FROM orders;
SELECT CONCAT('Invoices count: ', TO_CHAR(COUNT(*))) FROM invoices;
SELECT CONCAT('Customers count: ', TO_CHAR(COUNT(*))) FROM customers;