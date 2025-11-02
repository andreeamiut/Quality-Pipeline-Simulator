#!/bin/bash

# Stage C: Data Persistence & Consistency
# Oracle 19c SQL

set -e

# Configuration
DB_HOST="${DB_HOST:-oracle-db}"
DB_USER="${DB_USER:-fqge_user}"
DB_PASS="${DB_PASS:-fqge_password}"
DB_SID="${DB_SID:-XE}"
ORDER_ID="$1"  # Passed from main script

if [ -z "$ORDER_ID" ]; then
    echo "ERROR: ORDER_ID not provided"
    exit 1
fi

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log "Stage C: Checking Data Persistence & Consistency"

# Function to execute SQL query
execute_sql() {
    local query=$1
    sqlplus -s "$DB_USER/$DB_PASS@$DB_HOST/$DB_SID" << EOF
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
$query;
EXIT;
EOF
}

# 1. Validate the created record: SELECT order_status FROM orders WHERE id = [ID_from_StageB]
log "Validating order status..."
ORDER_STATUS=$(execute_sql "SELECT order_status FROM orders WHERE id = $ORDER_ID;")

if [ -z "$ORDER_STATUS" ]; then
    log "ERROR: Order with ID $ORDER_ID not found"
    exit 1
fi

ORDER_STATUS=$(echo "$ORDER_STATUS" | tr -d '[:space:]')

if [ "$ORDER_STATUS" != "COMPLETED" ]; then
    log "ERROR: Order status is '$ORDER_STATUS', expected 'COMPLETED'"
    exit 1
fi

log "Order status validated: $ORDER_STATUS"

# 2. Run a complex query utilizing MINUS or JOIN to verify data consistency across the Orders and Invoices tables
log "Checking data consistency between Orders and Invoices tables..."

# This query checks for orders that have been completed but don't have corresponding invoices
# Using MINUS to find inconsistencies
INCONSISTENCIES=$(execute_sql "
SELECT id FROM orders WHERE order_status = 'COMPLETED'
MINUS
SELECT order_id FROM invoices;
")

INCONSISTENCY_COUNT=$(echo "$INCONSISTENCIES" | wc -l)

if [ "$INCONSISTENCY_COUNT" -gt 0 ]; then
    log "ERROR: Found $INCONSISTENCY_COUNT data inconsistencies between Orders and Invoices tables"
    log "Inconsistent order IDs: $INCONSISTENCIES"
    exit 1
fi

log "Data consistency check passed (0 inconsistencies found)"

log "Stage C completed successfully"