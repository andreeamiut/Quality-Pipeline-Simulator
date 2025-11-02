#!/bin/bash

# FullStack_Quality_Gate_Expert (FQGE)
# Autonomous Quality Gate for CI/CD Pipeline

set -e  # Exit on any error

# Configuration
REMOTE_HOST="${REMOTE_HOST:-fqge-app}"
REMOTE_USER="${REMOTE_USER:-root}"
SSH_KEY="${SSH_KEY:-/root/.ssh/id_rsa}"
DB_HOST="${DB_HOST:-oracle-db}"
DB_USER="${DB_USER:-fqge_user}"
DB_PASS="${DB_PASS:-fqge_password}"
DB_SID="${DB_SID:-XE}"
JMETER_SCRIPT="load_test.jmx"
LOG_FILE="fqge_report.log"

# Global variables
STAGE_A_STATUS="PENDING"
STAGE_B_STATUS="PENDING"
STAGE_C_STATUS="PENDING"
STAGE_D_STATUS="PENDING"
ORDER_ID=""
REPORT=""

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to execute stage and update status
execute_stage() {
    local stage_name=$1
    local stage_script=$2
    local status_var=$3

    log "Starting $stage_name"
    if bash "$stage_script"; then
        eval "$status_var=PASS"
        log "$stage_name PASSED"
    else
        eval "$status_var=FAIL"
        log "$stage_name FAILED"
        return 1
    fi
}

# Function to perform RCA on failure
perform_rca() {
    local failed_stage=$1
    log "Performing Root Cause Analysis for $failed_stage"

    if [ "$failed_stage" = "STAGE_D" ]; then
        # For performance failure, check CPU and I/O
        log "Checking system resources via SSH..."
        ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" << EOF
            echo "=== TOP OUTPUT ==="
            top -b -n1 | head -20
            echo "=== NETSTAT OUTPUT ==="
            netstat -tuln | head -10
            echo "=== DISK I/O ==="
            iostat -x 1 1 | head -10
EOF
        log "RCA: Suspected component - Check logs for CPU-bound (App Server) or I/O-bound (Network/DB) issues"
    fi
}

# Function to generate final report
generate_report() {
    REPORT="FQGE Validation Report\n"
    REPORT+="======================\n\n"
    REPORT+="Stage A (Infrastructure): $STAGE_A_STATUS\n"
    REPORT+="Stage B (API Integrity): $STAGE_B_STATUS\n"
    REPORT+="Stage C (Data Persistence): $STAGE_C_STATUS\n"
    REPORT+="Stage D (Performance): $STAGE_D_STATUS\n\n"

    if [ "$STAGE_A_STATUS" = "PASS" ] && [ "$STAGE_B_STATUS" = "PASS" ] && [ "$STAGE_C_STATUS" = "PASS" ] && [ "$STAGE_D_STATUS" = "PASS" ]; then
        REPORT+="FINAL DECISION: APPROVAL - Ready for UAT/Production Promotion\n"
    else
        local failed_stages=""
        [ "$STAGE_A_STATUS" = "FAIL" ] && failed_stages+="A "
        [ "$STAGE_B_STATUS" = "FAIL" ] && failed_stages+="B "
        [ "$STAGE_C_STATUS" = "FAIL" ] && failed_stages+="C "
        [ "$STAGE_D_STATUS" = "FAIL" ] && failed_stages+="D "
        REPORT+="FINAL DECISION: REJECTION - ${failed_stages}Failure(s) - Immediate Rollback Required\n"
        REPORT+="\nFull console output available in $LOG_FILE\n"
    fi

    echo -e "$REPORT" | tee "$LOG_FILE"
}

# Main execution
log "FQGE Starting - Quality Gate Validation"

# Stage A: Infrastructure Health Check
if execute_stage "Stage A: Infrastructure Health Check" "stageA.sh" "STAGE_A_STATUS"; then
    :
else
    perform_rca "STAGE_A"
fi

# Stage B: Core Functional & API Integrity
if execute_stage "Stage B: Core Functional & API Integrity" "stageB.sh" "STAGE_B_STATUS"; then
    # Capture ORDER_ID from Stage B for Stage C
    ORDER_ID=$(grep "ORDER_ID:" "$LOG_FILE" | tail -1 | cut -d: -f2 | tr -d ' ')
else
    perform_rca "STAGE_B"
fi

# Stage C: Data Persistence & Consistency
if execute_stage "Stage C: Data Persistence & Consistency" "stageC.sh" "STAGE_C_STATUS"; then
    :
else
    perform_rca "STAGE_C"
fi

# Stage D: Performance Load Test
if execute_stage "Stage D: Performance Load Test" "stageD.sh" "STAGE_D_STATUS"; then
    :
else
    perform_rca "STAGE_D"
fi

# Generate final report
generate_report

log "FQGE Completed"