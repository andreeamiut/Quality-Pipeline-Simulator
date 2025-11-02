#!/bin/bash

# ========================================================================================
# STAGE C: DATA PERSISTENCE & CONSISTENCY VALIDATION
# ========================================================================================
# Purpose: Validates data integrity and relationships in the database to ensure
# that business operations maintain data consistency across related tables.
#
# Tests performed:
# 1. Order status validation - Verify specific order created in Stage B
# 2. Cross-table consistency - Check relationships between Orders and Invoices
#
# Key inputs:
# - ORDER_ID: Order identifier generated in Stage B (passed as $1)
#
# Key validations:
# - Order exists and has correct status (COMPLETED)
# - All completed orders have corresponding invoices (referential integrity)
#
# Exit codes:
# 0 = Success (all data consistency checks passed)
# 1 = Failure (data corruption or missing relationships detected)
# ========================================================================================

set -e  # Exit immediately if any command fails

# ========================================================================================
# CONFIGURATION SECTION
# ========================================================================================
DB_HOST="${DB_HOST:-oracle-db}"              # Oracle database hostname
DB_USER="${DB_USER:-fqge_user}"              # Database username
DB_PASS="${DB_PASS:-fqge_password}"          # Database password
DB_SID="${DB_SID:-FREEPDB1}"                 # Oracle SID
ORDER_ID="$1"                                # Order ID from Stage B (command line argument)

# ========================================================================================
# INPUT VALIDATION
# ========================================================================================
# Ensure ORDER_ID was provided by the main script
echo "DEBUG: Received ORDER_ID = '$ORDER_ID'"
if [ -z "$ORDER_ID" ]; then
    echo "ERROR: ORDER_ID not provided"
    exit 1  # Cannot proceed without order ID from Stage B
fi

# ========================================================================================
# UTILITY FUNCTIONS
# ========================================================================================

# Function: log
# Purpose: Standardized logging function with timestamps
# Parameters: $1 - Message to log
# Output: Timestamped message to stdout (captured by main script)
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log "Stage C: Checking Data Persistence & Consistency"

# Function: execute_sql
# Purpose: Execute SQL query against Oracle database with clean output formatting
# Parameters: $1 - SQL query string to execute
# Output: Query results (without headers, feedback, or pagination)
# Side effects: Connects to Oracle database using configured credentials
execute_sql() {
    local query=$1    # SQL query passed as first argument

    # Execute query using SQL*Plus with silent options for clean output
    sqlplus -s "$DB_USER/$DB_PASS@$DB_HOST/$DB_SID" << EOF
SET HEADING OFF     -- Suppress column headers
SET FEEDBACK OFF    -- Suppress "X rows selected" messages
SET PAGESIZE 0      -- Disable pagination
$query;             -- Execute the provided query
EXIT;               -- Exit SQL*Plus cleanly
EOF
}

# ========================================================================================
# VALIDATION 1: ORDER STATUS VERIFICATION
# ========================================================================================
# Verifies that the specific order created in Stage B exists and has correct status.
# This ensures the order was properly persisted to the database.
# ========================================================================================
log "Validating order status..."

# Query the order status for the specific ORDER_ID from Stage B
ORDER_STATUS=$(execute_sql "SELECT order_status FROM orders WHERE id = $ORDER_ID;")

# Check if the order exists in the database
if [ -z "$ORDER_STATUS" ]; then
    log "ERROR: Order with ID $ORDER_ID not found"
    exit 1  # Fail if order wasn't persisted properly
fi

# Clean whitespace from the result
ORDER_STATUS=$(echo "$ORDER_STATUS" | tr -d '[:space:]')

# Verify the order has the expected COMPLETED status
if [ "$ORDER_STATUS" != "COMPLETED" ]; then
    log "ERROR: Order status is '$ORDER_STATUS', expected 'COMPLETED'"
    exit 1  # Fail if order status is incorrect
fi

log "Order status validated: $ORDER_STATUS"

# ========================================================================================
# VALIDATION 2: CROSS-TABLE DATA CONSISTENCY
# ========================================================================================
# Validates referential integrity between Orders and Invoices tables.
# Ensures that all completed orders have corresponding invoice records.
# Uses Oracle MINUS operator to find orders without invoices.
# ========================================================================================
log "Checking data consistency between Orders and Invoices tables..."

# Execute complex query to find data inconsistencies
# MINUS returns orders that exist in first query but not in second
# This finds completed orders that don't have corresponding invoices
INCONSISTENCIES=$(execute_sql "
SELECT id FROM orders WHERE order_status = 'COMPLETED'
MINUS
SELECT order_id FROM invoices;
")

# Count the number of inconsistent records
INCONSISTENCY_COUNT=$(echo "$INCONSISTENCIES" | wc -l)

# Fail if any inconsistencies are found
if [ "$INCONSISTENCY_COUNT" -gt 0 ]; then
    log "ERROR: Found $INCONSISTENCY_COUNT data inconsistencies between Orders and Invoices tables"
    log "Inconsistent order IDs: $INCONSISTENCIES"
    exit 1  # Fail stage due to data integrity issues
fi

log "Data consistency check passed (0 inconsistencies found)"

# ========================================================================================
# STAGE COMPLETION
# ========================================================================================
# All data consistency validations have passed. Log success and exit.
# ========================================================================================
log "Stage C completed successfully"