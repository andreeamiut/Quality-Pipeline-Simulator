#!/bin/bash

# FQGE Docker Test Runner
# This script sets up and runs the complete FQGE system in Docker

set -e

echo "FQGE Docker Test Environment Setup"
echo "==================================="

# Check if Docker and Docker Compose are available
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed or not in PATH"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "ERROR: Docker Compose is not installed or not in PATH"
    exit 1
fi

echo "✓ Docker and Docker Compose found"

# Clean up any existing containers
echo "Cleaning up existing containers..."
docker-compose down -v 2>/dev/null || true

# Start the services
echo "Starting FQGE services..."
docker-compose up -d

# Wait for Oracle DB to be ready
echo "Waiting for Oracle DB to be ready..."
sleep 30

# Check if Oracle DB is healthy
echo "Checking Oracle DB health..."
max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
    if docker-compose exec -T oracle-db sqlplus -s sys/oracle123@//localhost:1521/XE as sysdba <<< "SELECT 1 FROM dual;" &>/dev/null; then
        echo "✓ Oracle DB is ready"
        break
    fi
    echo "Waiting for Oracle DB... (attempt $attempt/$max_attempts)"
    sleep 10
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    echo "ERROR: Oracle DB failed to start"
    docker-compose logs oracle-db
    exit 1
fi

# Check if mock API is responding
echo "Checking Mock API..."
if curl -f -s http://localhost:8080/api/status &>/dev/null; then
    echo "✓ Mock API is responding"
else
    echo "ERROR: Mock API is not responding"
    docker-compose logs mock-api
    exit 1
fi

# Run FQGE test
echo "Running FQGE validation..."
docker-compose exec -T fqge-app ./test_fqge.sh

if [ $? -eq 0 ]; then
    echo "✓ FQGE system test passed"
else
    echo "✗ FQGE system test failed"
    exit 1
fi

# Optional: Run full FQGE (commented out as it requires SSH setup)
# echo "Running full FQGE validation..."
# docker-compose exec fqge-app ./fqge.sh

echo ""
echo "Test environment is ready!"
echo "To run the full FQGE system:"
echo "  docker-compose exec fqge-app ./fqge.sh"
echo ""
echo "To access individual services:"
echo "  Oracle DB: sqlplus fqge_user/fqge_password@//localhost:1521/XE"
echo "  Mock API: curl http://localhost:8080/api/status"
echo ""
echo "To clean up: docker-compose down -v"