#!/bin/bash

# ========================================================================================
# STAGE A: INFRASTRUCTURE HEALTH CHECK
# ========================================================================================
# Purpose: Validates that all critical infrastructure components are operational
# and meet minimum health requirements before proceeding with functional testing.
#
# Validates:
# 1. Database connectivity and responsiveness
# 2. Available disk space (must be < 90% usage)
# 3. System memory usage (must be < 95% usage)
#
# Exit codes:
# 0 = Success (all checks passed)
# 1 = Failure (any check failed)
#
# This stage ensures the deployment environment is stable and has sufficient
# resources to handle the upcoming validation stages.
# ========================================================================================

set -e  # Exit immediately if any command fails

# ========================================================================================
# CONFIGURATION SECTION
# ========================================================================================
# These variables are inherited from the main fqge.sh script via environment variables
REMOTE_HOST="${REMOTE_HOST:-fqge-app}"        # Target application server hostname
REMOTE_USER="${REMOTE_USER:-root}"           # SSH username for remote access
SSH_KEY="${SSH_KEY:-/root/.ssh/id_rsa}"      # SSH private key path for authentication

# ========================================================================================
# UTILITY FUNCTIONS
# ========================================================================================

# Function: log
# Purpose: Standardized logging function with timestamps
# Parameters: $1 - Message to log
# Output: Timestamped message to stdout (will be captured by main script)
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ========================================================================================
# MAIN EXECUTION: INFRASTRUCTURE HEALTH VALIDATION
# ========================================================================================

log "Stage A: Checking Infrastructure Health"

# ========================================================================================
# CHECK 1: DATABASE CONNECTIVITY
# ========================================================================================
# Validates that the Oracle database is accessible and responding to queries.
# This is critical because all subsequent stages depend on database functionality.
# ========================================================================================
log "Checking database connectivity..."

# Attempt to connect to Oracle database and execute a simple test query
# Redirect all output to /dev/null to avoid cluttering logs with SQL*Plus output
# Note: In GitHub Actions, the database connection string needs to match the service configuration
if ! sqlplus -s "$DB_USER/$DB_PASS@$DB_HOST/$DB_SID" << EOF > /dev/null 2>&1
SELECT 1 FROM dual;  -- Simple test query that should always work if DB is accessible
EXIT;                -- Exit SQL*Plus cleanly
EOF
then
    log "ERROR: Database connectivity check failed - Connection string: $DB_USER@$DB_HOST/$DB_SID"
    log "Troubleshooting: Check if Oracle service is running and network connectivity"
    # Try alternative connection string for local container networking
    if ! sqlplus -s "$DB_USER/$DB_PASS@//$DB_HOST:1521/$DB_SID" << EOF > /dev/null 2>&1
SELECT 1 FROM dual;
EXIT;
EOF
    then
        exit 1  # Fail the entire stage if database is unreachable
    fi
fi
log "Database connectivity check passed"

# ========================================================================================
# CHECK 2: AVAILABLE DISK SPACE
# ========================================================================================
# Ensures sufficient disk space is available for application operations and logging.
# High disk usage can cause application failures, especially during load testing.
# Threshold: 90% - above this level, deployment should be rejected.
# ========================================================================================
log "Checking disk space..."

# Get disk usage percentage for root filesystem
# df / shows disk usage, tail -1 gets the data line, awk extracts 5th field (usage %)
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

# Check if disk usage exceeds 90% threshold
if [ "$DISK_USAGE" -gt 90 ]; then
    log "ERROR: Disk usage is ${DISK_USAGE}%, which is above 90%"
    exit 1  # Fail stage if insufficient disk space
fi
log "Disk space check passed (${DISK_USAGE}%)"

# ========================================================================================
# CHECK 3: SYSTEM MEMORY USAGE
# ========================================================================================
# Validates that system memory usage is within acceptable limits.
# High memory usage can cause application slowdowns or crashes during testing.
# Threshold: 95% - above this level, deployment should be rejected.
# ========================================================================================
log "Checking system memory..."

# Calculate memory usage percentage
# free shows memory stats, grep Mem gets memory line, awk calculates used/total * 100
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')

# Check if memory usage exceeds 95% threshold
if [ "$MEMORY_USAGE" -gt 95 ]; then
    log "ERROR: Memory usage is ${MEMORY_USAGE}%, which is above 95%"
    exit 1  # Fail stage if memory usage is too high
fi
log "Memory usage check passed (${MEMORY_USAGE}%)"

# ========================================================================================
# STAGE COMPLETION
# ========================================================================================
# All infrastructure checks have passed. Log success and exit with code 0.
# ========================================================================================
log "Stage A completed successfully"