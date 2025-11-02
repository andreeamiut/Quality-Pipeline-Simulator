-- ========================================================================================
-- ORACLE 19C DATABASE SETUP FOR FQGE TESTING
-- ========================================================================================
-- Purpose: Initialize the Oracle database with test schema, tables, and sample data
-- for the FQGE (FullStack Quality Gate Expert) validation pipeline.
--
-- This script creates:
-- 1. Three core tables: orders, invoices, customers
-- 2. Indexes for performance optimization
-- 3. Sample test data for validation scenarios
-- 4. Referential integrity constraints
--
-- Execution Context:
-- - Run as DBA user (SYS or SYSTEM)
-- - Target database: Oracle 19c or compatible
-- - Schema: Uses the APP_USER created by Oracle Docker image (default: fqge_user)
--
-- Note: User creation is handled automatically by the Oracle Docker image's APP_USER
-- ========================================================================================

-- ========================================================================================
-- SCHEMA SETUP (Handled by Docker Image)
-- ========================================================================================
-- The following commands are commented out because they are handled automatically
-- by the Oracle Docker image when APP_USER and APP_USER_PASSWORD are set:
--
-- CREATE USER fqge_user IDENTIFIED BY fqge_password;  -- Auto-created by Docker
-- GRANT CONNECT, RESOURCE TO fqge_user;               -- Auto-granted by Docker
-- ALTER USER fqge_user QUOTA UNLIMITED ON USERS;      -- Auto-granted by Docker
--
-- ALTER SESSION SET CURRENT_SCHEMA = fqge_user;       -- Not needed - Docker sets this
-- ========================================================================================

-- ========================================================================================
-- TABLE CREATION SECTION
-- ========================================================================================

-- Table: orders
-- Purpose: Stores order information for the e-commerce/order management system
-- Business Rules:
-- - Status must be one of: PENDING, PROCESSING, COMPLETED, CANCELLED
-- - Total amount must be non-negative
-- - Auto-timestamps for audit trail
CREATE TABLE orders (
    id NUMBER PRIMARY KEY,                                           -- Unique order identifier
    customer_id NUMBER,                                              -- Reference to customer who placed order
    order_status VARCHAR2(20) CHECK (order_status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'CANCELLED')), -- Order lifecycle status
    total NUMBER(10,2) CHECK (total >= 0),                          -- Order total amount with 2 decimal places
    created_date DATE DEFAULT SYSDATE,                              -- Auto-set creation timestamp
    updated_date DATE DEFAULT SYSDATE                               -- Auto-set last update timestamp
);

-- Table: invoices
-- Purpose: Stores invoice records linked to completed orders
-- Business Rules:
-- - Each invoice must be linked to exactly one order (foreign key constraint)
-- - Invoice numbers must be unique across the system
-- - Amount represents the billed amount for the order
CREATE TABLE invoices (
    id NUMBER PRIMARY KEY,                                          -- Unique invoice identifier
    order_id NUMBER,                                                -- Reference to the order being invoiced
    invoice_number VARCHAR2(50) UNIQUE,                             -- Human-readable invoice number (must be unique)
    amount NUMBER(10,2),                                            -- Invoice amount
    created_date DATE DEFAULT SYSDATE,                              -- Auto-set invoice creation timestamp
    CONSTRAINT fk_invoice_order FOREIGN KEY (order_id) REFERENCES orders(id) -- Ensures referential integrity
);

-- Table: customers
-- Purpose: Stores customer information for the system
-- Business Rules:
-- - Customer name is required (NOT NULL)
-- - Email addresses must be unique across all customers
-- - Basic customer profile information
CREATE TABLE customers (
    id NUMBER PRIMARY KEY,                                          -- Unique customer identifier
    name VARCHAR2(100) NOT NULL,                                    -- Customer full name (required)
    email VARCHAR2(100) UNIQUE                                       -- Customer email (must be unique)
);

-- ========================================================================================
-- INDEX CREATION SECTION
-- ========================================================================================
-- Purpose: Create indexes to optimize query performance for common access patterns
-- These indexes support the validation queries used in the FQGE pipeline stages
-- ========================================================================================

CREATE INDEX idx_orders_status ON orders(order_status);     -- Optimize order status filtering (Stage C)
CREATE INDEX idx_orders_customer ON orders(customer_id);    -- Optimize customer order lookups
CREATE INDEX idx_invoices_order ON invoices(order_id);      -- Optimize invoice-to-order joins (Stage C)
CREATE INDEX idx_customers_email ON customers(email);       -- Optimize customer email uniqueness checks

-- ========================================================================================
-- TEST DATA INSERTION SECTION
-- ========================================================================================
-- Purpose: Populate tables with realistic test data for FQGE validation scenarios
-- Data Design:
-- - 3 customers with different profiles
-- - 4 orders in various states (mix of completed and pending)
-- - 2 invoices for completed orders (intentionally missing invoices for testing)
-- ========================================================================================

-- Insert customer test data
INSERT INTO customers (id, name, email) VALUES (1, 'John Doe', 'john@example.com');
INSERT INTO customers (id, name, email) VALUES (2, 'Jane Smith', 'jane@example.com');
INSERT INTO customers (id, name, email) VALUES (3, 'Bob Johnson', 'bob@example.com');

-- Insert order test data with various statuses
INSERT INTO orders (id, customer_id, order_status, total) VALUES (1001, 1, 'COMPLETED', 150.00);  -- Will have invoice
INSERT INTO orders (id, customer_id, order_status, total) VALUES (1002, 2, 'PENDING', 75.50);     -- No invoice (for consistency testing)
INSERT INTO orders (id, customer_id, order_status, total) VALUES (1003, 1, 'COMPLETED', 200.00);  -- Will have invoice
INSERT INTO orders (id, customer_id, order_status, total) VALUES (1004, 3, 'PROCESSING', 125.25); -- No invoice (for consistency testing)

-- Insert invoice test data (only for completed orders)
INSERT INTO invoices (id, order_id, invoice_number, amount) VALUES (2001, 1001, 'INV-001', 150.00); -- Matches order 1001
INSERT INTO invoices (id, order_id, invoice_number, amount) VALUES (2002, 1003, 'INV-002', 200.00); -- Matches order 1003
-- Note: Orders 1002 and 1004 intentionally have no invoices to test data consistency validation in Stage C

-- Commit all changes to make them permanent
COMMIT;

-- ========================================================================================
-- VERIFICATION QUERIES SECTION
-- ========================================================================================
-- Purpose: Verify that the database setup completed successfully
-- These queries are executed after setup to confirm data integrity
-- Used by the FQGE pipeline to validate database state in Stage A and Stage B
-- ========================================================================================

-- Verify orders table population
SELECT CONCAT('Orders count: ', TO_CHAR(COUNT(*))) FROM orders;

-- Verify invoices table population
SELECT CONCAT('Invoices count: ', TO_CHAR(COUNT(*))) FROM invoices;

-- Verify customers table population
SELECT CONCAT('Customers count: ', TO_CHAR(COUNT(*))) FROM customers;

-- ========================================================================================
-- EXPECTED RESULTS:
-- Orders count: 4
-- Invoices count: 2
-- Customers count: 3
--
-- Note: Intentionally fewer invoices than orders to test data consistency validation
-- ========================================================================================