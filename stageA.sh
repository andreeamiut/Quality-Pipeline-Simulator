#!/bin/bash

# Stage A: Infrastructure Health Check
# Linux (Bash) & Deployments

set -e

# Configuration (inherited from fqge.sh)
REMOTE_HOST="${REMOTE_HOST:-fqge-app}"
REMOTE_USER="${REMOTE_USER:-root}"
SSH_KEY="${SSH_KEY:-/root/.ssh/id_rsa}"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log "Stage A: Checking Infrastructure Health"

# 1. Check database connectivity
log "Checking database connectivity..."
if ! sqlplus -s "$DB_USER/$DB_PASS@$DB_HOST/$DB_SID" << EOF > /dev/null 2>&1
SELECT 1 FROM dual;
EXIT;
EOF
then
    log "ERROR: Database connectivity check failed"
    exit 1
fi
log "Database connectivity check passed"

# 2. Check available disk space
log "Checking disk space..."
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    log "ERROR: Disk usage is ${DISK_USAGE}%, which is above 90%"
    exit 1
fi
log "Disk space check passed (${DISK_USAGE}%)"

# 3. Check system memory
log "Checking system memory..."
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
if [ "$MEMORY_USAGE" -gt 95 ]; then
    log "ERROR: Memory usage is ${MEMORY_USAGE}%, which is above 95%"
    exit 1
fi
log "Memory usage check passed (${MEMORY_USAGE}%)"

log "Stage A completed successfully"