# Oracle 19c SQL Queries and Tests for FQGE

## Overview

This document provides the Oracle 19c SQL queries and test suite used by the FullStack Quality Gate Expert (FQGE) system for Stage C: Data Persistence & Consistency validation.

## Files Included

- [`oracle_setup.sql`](oracle_setup.sql) - Database setup and test data creation
- [`oracle_validation.sql`](oracle_validation.sql) - Production validation queries used by stageC.sh
- [`oracle_test_runner.sql`](oracle_test_runner.sql) - Comprehensive test suite with pass/fail validation
- [`oracle_queries.sql`](oracle_queries.sql) - Additional utility queries
- [`oracle_tests.sql`](oracle_tests.sql) - Test data and validation examples

## Database Schema

The FQGE validation assumes the following Oracle tables:

### ORDERS table
```sql
CREATE TABLE orders (
    id NUMBER PRIMARY KEY,
    customer_id NUMBER,
    order_status VARCHAR2(20) CHECK (order_status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'CANCELLED')),
    total NUMBER(10,2) CHECK (total >= 0),
    created_date DATE DEFAULT SYSDATE,
    updated_date DATE DEFAULT SYSDATE
);
```

### INVOICES table
```sql
CREATE TABLE invoices (
    id NUMBER PRIMARY KEY,
    order_id NUMBER,
    invoice_number VARCHAR2(50) UNIQUE,
    amount NUMBER(10,2),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_invoice_order FOREIGN KEY (order_id) REFERENCES orders(id)
);
```

### CUSTOMERS table
```sql
CREATE TABLE customers (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    email VARCHAR2(100) UNIQUE
);
```

## Validation Queries

### 1. Order Status Validation
**Purpose**: Verify that the order created in Stage B has status "COMPLETED"

**Query**:
```sql
SELECT order_status
FROM orders
WHERE id = &order_id;
```

**Success Criteria**: Returns exactly one row with value "COMPLETED"

### 2. Data Consistency Check (MINUS)
**Purpose**: Ensure all completed orders have corresponding invoices

**Query**:
```sql
SELECT id
FROM orders
WHERE order_status = 'COMPLETED'
MINUS
SELECT order_id
FROM invoices;
```

**Success Criteria**: Returns zero rows (no inconsistencies)

### 3. Alternative Consistency Check (LEFT JOIN)
**Purpose**: Alternative method to check for completed orders without invoices

**Query**:
```sql
SELECT o.id, o.order_status
FROM orders o
LEFT JOIN invoices i ON o.id = i.order_id
WHERE o.order_status = 'COMPLETED'
AND i.order_id IS NULL;
```

**Success Criteria**: Returns zero rows

### 4. Data Integrity Verification
**Purpose**: Check for various data quality issues

**Query**:
```sql
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
);
```

**Success Criteria**: All issue_count values are 0

### 5. Index Verification
**Purpose**: Ensure required indexes exist for performance

**Query**:
```sql
SELECT
    table_name,
    index_name,
    column_name,
    'EXISTS' as status
FROM all_ind_columns
WHERE table_name IN ('ORDERS', 'INVOICES', 'CUSTOMERS')
AND column_name IN ('ID', 'ORDER_ID', 'CUSTOMER_ID', 'ORDER_STATUS')
ORDER BY table_name, index_name;
```

**Success Criteria**: At least 4 relevant indexes exist

### 6. Recent Data Validation
**Purpose**: Check for recent data modifications (last 24 hours)

**Query**:
```sql
SELECT
    'ORDERS' as table_name,
    COUNT(CASE WHEN created_date >= SYSDATE - 1 THEN 1 END) as inserts_24h,
    COUNT(CASE WHEN updated_date >= SYSDATE - 1 AND created_date < SYSDATE - 1 THEN 1 END) as updates_24h
FROM orders
UNION ALL
-- Similar for INVOICES and CUSTOMERS
```

**Success Criteria**: Shows activity counts (informational)

## Test Data Setup

To set up test data, run [`oracle_setup.sql`](oracle_setup.sql) which creates:

- 3 customers
- 4 orders (2 completed, 1 pending, 1 processing)
- 2 invoices (for completed orders only, leaving one without invoice for testing)

## Running Tests

Execute [`oracle_test_runner.sql`](oracle_test_runner.sql) to run the complete test suite:

```sql
@oracle_test_runner.sql
```

This will run all validation tests and report PASS/FAIL status for each.

## Integration with FQGE

The [`stageC.sh`](stageC.sh) script uses SQL*Plus to execute these queries against the Oracle database:

```bash
sqlplus -s "$DB_USER/$DB_PASS@$DB_HOST:1521/$DB_SID" << EOF
[validation queries here]
EXIT;
EOF
```

## Performance Considerations

- All queries are optimized for Oracle 19c
- Indexes are recommended on primary keys and foreign keys
- MINUS operations are efficient for set-based consistency checks
- Queries use appropriate WHERE clauses to limit result sets

## Error Handling

The FQGE system expects:
- Order status query to return exactly one row
- Consistency checks to return zero rows
- Any non-zero results or SQL errors trigger Stage C failure

## Customization

To adapt for your schema:
1. Update table names in queries
2. Modify column names as needed
3. Adjust CHECK constraints for valid order statuses
4. Update index verification queries for your indexing strategy