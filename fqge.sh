#!/bin/bash

# ========================================================================================
# FullStack_Quality_Gate_Expert (FQGE) - Autonomous Quality Gate for CI/CD Pipeline
# ========================================================================================
# This script orchestrates a comprehensive quality validation pipeline consisting of 4 stages:
# Stage A: Infrastructure Health Check - Validates system and database connectivity
# Stage B: Core Functional & API Integrity - Tests business logic and API endpoints
# Stage C: Data Persistence & Consistency - Verifies data integrity and relationships
# Stage D: Performance Load Test - Validates system performance under load
#
# The script uses a fail-fast approach where any stage failure triggers rollback procedures
# and generates detailed root cause analysis for debugging and remediation.
# ========================================================================================

set -e  # Exit immediately if any command fails (fail-fast approach)

# ========================================================================================
# CONFIGURATION SECTION
# ========================================================================================
# Default configuration values that can be overridden via environment variables
REMOTE_HOST="${REMOTE_HOST:-fqge-app}"        # Remote application server hostname
REMOTE_USER="${REMOTE_USER:-root}"           # SSH username for remote access
SSH_KEY="${SSH_KEY:-/root/.ssh/id_rsa}"      # Path to SSH private key for authentication
DB_HOST="${DB_HOST:-oracle-db}"              # Oracle database hostname/container name
DB_USER="${DB_USER:-fqge_user}"              # Database username for application access
DB_PASS="${DB_PASS:-fqge_password}"          # Database password for application access
DB_SID="${DB_SID:-FREEPDB1}"                 # Oracle PDB name (updated for oracle-free image)
JMETER_SCRIPT="load_test.jmx"                 # JMeter test script filename
LOG_FILE="fqge_report.log"                   # Main log file for all operations

# ========================================================================================
# GLOBAL VARIABLES SECTION
# ========================================================================================
# Stage status tracking - each stage can be PENDING, PASS, or FAIL
STAGE_A_STATUS="PENDING"    # Infrastructure Health Check status
STAGE_B_STATUS="PENDING"    # Core Functional & API Integrity status
STAGE_C_STATUS="PENDING"    # Data Persistence & Consistency status
STAGE_D_STATUS="PENDING"    # Performance Load Test status
ORDER_ID=""                 # Order ID captured from Stage B for Stage C validation
REPORT=""                   # Final validation report content

# ========================================================================================
# FUNCTION DEFINITIONS SECTION
# ========================================================================================

# Function: log
# Purpose: Centralized logging function that writes to both console and log file
# Parameters: $1 - Message to log
# Output: Timestamped message to stdout and appended to LOG_FILE
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function: execute_stage
# Purpose: Executes a validation stage script and updates its status
# Parameters:
#   $1 - stage_name: Human-readable name of the stage (e.g., "Stage A: Infrastructure Health Check")
#   $2 - stage_script: Script command with arguments (e.g., "stageA.sh" or "stageC.sh $ORDER_ID")
#   $3 - status_var: Name of the global variable to update (e.g., "STAGE_A_STATUS")
# Returns: 0 on success, 1 on failure
# Side effects: Updates the global status variable and logs results
execute_stage() {
    local stage_name=$1      # First parameter: stage display name
    local stage_script=$2    # Second parameter: script command with arguments
    local status_var=$3      # Third parameter: global variable name for status tracking

    log "Starting $stage_name"    # Log the beginning of stage execution

    # Execute the stage script and check return code
    # Use eval to properly handle scripts with arguments and capture output to log
    local stage_output
    stage_output=$(eval bash $stage_script 2>&1)
    local exit_code=$?
    
    # Append stage output to log file
    echo "$stage_output" | tee -a "$LOG_FILE" >/dev/null
    
    if [ $exit_code -eq 0 ]; then
        eval "$status_var=PASS"    # Set status to PASS if script succeeded
        log "$stage_name PASSED"   # Log successful completion
    else
        eval "$status_var=FAIL"    # Set status to FAIL if script failed
        log "$stage_name FAILED"   # Log failure
        return 1                   # Return failure code to caller
    fi
}

# Function: perform_rca (Root Cause Analysis)
# Purpose: Performs diagnostic analysis when a stage fails to help identify the root cause
# Parameters: $1 - failed_stage: The stage that failed (e.g., "STAGE_A", "STAGE_D")
# Currently only implements RCA for STAGE_D (Performance) failures
# Future enhancement: Add RCA logic for other stages
perform_rca() {
    local failed_stage=$1    # The stage identifier that failed

    log "Performing Root Cause Analysis for $failed_stage"

    # Currently only STAGE_D (Performance) has specific RCA logic
    if [ "$failed_stage" = "STAGE_D" ]; then
        # Performance failures require checking system resources
        log "Checking system resources via SSH..."

        # Use SSH to connect to remote host and gather diagnostic information
        ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" << EOF
            echo "=== TOP OUTPUT ==="          # Process list with CPU/memory usage
            top -b -n1 | head -20               # Run top in batch mode, show first 20 lines
            echo "=== NETSTAT OUTPUT ==="       # Network connections and ports
            netstat -tuln | head -10            # Show listening ports and connections
            echo "=== DISK I/O ==="             # Disk input/output statistics
            iostat -x 1 1 | head -10            # Extended I/O stats for 1 second
EOF
        # Log guidance for interpreting the diagnostic data
        log "RCA: Suspected component - Check logs for CPU-bound (App Server) or I/O-bound (Network/DB) issues"
    fi
}

# Function: generate_report
# Purpose: Creates a comprehensive final report summarizing all validation stages
# Parameters: None (uses global status variables)
# Output: Formatted report written to both console and LOG_FILE
# Logic:
# - Builds a report header with stage statuses
# - Determines overall PASS/FAIL based on all stages passing
# - Lists failed stages if any exist
# - Provides actionable next steps based on results
generate_report() {
    # Initialize report with header
    REPORT="FQGE Validation Report\n"
    REPORT+="======================\n\n"

    # Add individual stage results with descriptions
    REPORT+="Stage A (Infrastructure): $STAGE_A_STATUS\n"      # Infrastructure health check
    REPORT+="Stage B (API Integrity): $STAGE_B_STATUS\n"       # API functionality tests
    REPORT+="Stage C (Data Persistence): $STAGE_C_STATUS\n"    # Data consistency validation
    REPORT+="Stage D (Performance): $STAGE_D_STATUS\n\n"       # Load testing results

    # Determine overall validation result
    if [ "$STAGE_A_STATUS" = "PASS" ] && [ "$STAGE_B_STATUS" = "PASS" ] && \
       [ "$STAGE_C_STATUS" = "PASS" ] && [ "$STAGE_D_STATUS" = "PASS" ]; then
        # All stages passed - approve for promotion
        REPORT+="FINAL DECISION: APPROVAL - Ready for UAT/Production Promotion\n"
    else
        # One or more stages failed - build failure summary
        local failed_stages=""
        [ "$STAGE_A_STATUS" = "FAIL" ] && failed_stages+="A "    # Infrastructure failure
        [ "$STAGE_B_STATUS" = "FAIL" ] && failed_stages+="B "    # API failure
        [ "$STAGE_C_STATUS" = "FAIL" ] && failed_stages+="C "    # Data failure
        [ "$STAGE_D_STATUS" = "FAIL" ] && failed_stages+="D "    # Performance failure

        # Rejection message with failed stages and rollback instruction
        REPORT+="FINAL DECISION: REJECTION - ${failed_stages}Failure(s) - Immediate Rollback Required\n"
        REPORT+="\nFull console output available in $LOG_FILE\n"
    fi

    # Output report to both console and log file
    echo -e "$REPORT" | tee "$LOG_FILE"
}

# ========================================================================================
# MAIN EXECUTION SECTION
# ========================================================================================
# This section orchestrates the 4-stage validation pipeline in sequence.
# Each stage is executed conditionally, and failures trigger RCA analysis.
# The pipeline uses a progressive approach where later stages depend on earlier ones.
# ========================================================================================

log "FQGE Starting - Quality Gate Validation"

# ========================================================================================
# STAGE A: INFRASTRUCTURE HEALTH CHECK
# ========================================================================================
# Validates that all required infrastructure components are operational:
# - Database connectivity and availability
# - Application server responsiveness
# - Network connectivity between components
# ========================================================================================
if execute_stage "Stage A: Infrastructure Health Check" "stageA.sh" "STAGE_A_STATUS"; then
    :  # No additional actions needed on success
else
    perform_rca "STAGE_A"  # Perform root cause analysis on failure
fi

# ========================================================================================
# STAGE B: CORE FUNCTIONAL & API INTEGRITY
# ========================================================================================
# Tests the core business functionality and API endpoints:
# - Business logic validation
# - API response correctness
# - Data processing accuracy
# - Captures ORDER_ID for Stage C validation
# ========================================================================================
if execute_stage "Stage B: Core Functional & API Integrity" "stageB.sh" "STAGE_B_STATUS"; then
    # Extract ORDER_ID from Stage B logs for use in Stage C
    # This creates a dependency chain between stages
    ORDER_ID=$(grep "ORDER_ID:" "$LOG_FILE" | tail -1 | cut -d: -f2 | tr -d ' ')
else
    perform_rca "STAGE_B"  # Perform root cause analysis on failure
fi

# ========================================================================================
# STAGE C: DATA PERSISTENCE & CONSISTENCY
# ========================================================================================
# Validates data integrity and relationships:
# - Database constraint validation
# - Data consistency checks
# - Foreign key relationships
# - Uses ORDER_ID from Stage B to verify specific data
# ========================================================================================
if execute_stage "Stage C: Data Persistence & Consistency" "stageC.sh $ORDER_ID" "STAGE_C_STATUS"; then
    :  # No additional actions needed on success
else
    perform_rca "STAGE_C"  # Perform root cause analysis on failure
fi

# ========================================================================================
# STAGE D: PERFORMANCE LOAD TEST
# ========================================================================================
# Validates system performance under load:
# - Response time validation
# - Throughput testing
# - Resource utilization monitoring
# - Scalability assessment
# ========================================================================================
if execute_stage "Stage D: Performance Load Test" "stageD.sh" "STAGE_D_STATUS"; then
    :  # No additional actions needed on success
else
    perform_rca "STAGE_D"  # Perform root cause analysis on failure
fi

# ========================================================================================
# FINAL REPORT GENERATION
# ========================================================================================
# Compile all stage results into a comprehensive report
# Determine overall PASS/FAIL status
# Provide actionable recommendations
# ========================================================================================
generate_report

log "FQGE Completed"