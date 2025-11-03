# Quality Gate Pipeline Simulator (FQGE)

[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-blue)](https://github.com/andreeamiut/Quality-Pipeline-Simulator)
[![Docker](https://img.shields.io/badge/Container-Docker-blue)](https://www.docker.com/)
[![Oracle](https://img.shields.io/badge/Database-Oracle%2023ai-red)](https://www.oracle.com/database/)
[![JMeter](https://img.shields.io/badge/Performance-Apache%20JMeter-brightgreen)](https://jmeter.apache.org/)

A comprehensive **Full-Stack Quality Gate Expert (FQGE)** validation pipeline that simulates enterprise-grade quality assurance processes using Docker Compose, Oracle Database, and Apache JMeter.

## 🎯 Project Overview

The FQGE pipeline implements a **4-stage quality validation system** designed to ensure application readiness before production deployment. It validates infrastructure health, API integrity, data persistence, and performance under load.

### Key Features

- **🏗️ Infrastructure Validation**: Database connectivity, disk space, memory usage
- **🔌 API Integrity Testing**: Mock API endpoints, functional validation
- **📊 Data Persistence**: Order processing, referential integrity checks
- **⚡ Performance Testing**: JMeter load testing with configurable thresholds
- **🐳 Docker Containerization**: Complete environment isolation
- **🔄 CI/CD Integration**: GitHub Actions pipeline support
- **📈 Comprehensive Reporting**: Detailed logs and validation reports

## 📁 Project Structure

```
qualityGate/
├── 📋 Core Pipeline Scripts
│   ├── fqge.sh                    # Main orchestration script
│   ├── stageA.sh                  # Infrastructure health checks
│   ├── stageB.sh                  # API integrity & order creation
│   ├── stageC.sh                  # Data persistence validation
│   └── stageD.sh                  # Performance load testing
│
├── 🐳 Docker Configuration
│   ├── Dockerfile                 # FQGE application image
│   ├── docker-compose.yml         # Service definitions
│   └── docker-compose.override.yml # Local development overrides
│
├── 🗄️ Database Setup
│   ├── oracle_setup.sql           # Schema creation and test data
│   ├── oracle_queries.sql         # Sample validation queries
│   ├── oracle_tests.sql          # Database test cases
│   └── oracle_validation.sql     # Data integrity checks
│
├── 🔧 Testing & Configuration
│   ├── load_test.jmx             # JMeter performance test plan
│   ├── mock-api.conf             # Mock API service configuration
│   └── mock-api/                 # Mock API implementation
│
├── 📚 Documentation
│   ├── README.md                 # This comprehensive guide
│   ├── docker_setup.md           # Docker installation guide
│   ├── oracle_documentation.md   # Database setup documentation
│   └── install_docker_windows.md # Windows-specific Docker setup
│
└── 🚀 Automation Scripts
    ├── test_fqge.sh              # Pipeline testing utilities
    ├── run_docker_test.sh        # Docker environment testing
    └── stage[A-D].sh             # Individual stage execution scripts
```

## 🏃‍♂️ Quick Start

### Prerequisites

- **Docker Desktop**: Version 20.10+ with Compose V2
- **Memory**: Minimum 8GB RAM (Oracle Database requirement)
- **Storage**: 10GB+ available disk space
- **OS**: Windows 10/11, macOS, or Linux

### 1. Clone and Setup

```bash
git clone https://github.com/andreeamiut/Quality-Pipeline-Simulator.git
cd Quality-Pipeline-Simulator
```

### 2. Start the Environment

```bash
# Start all services (Oracle DB + FQGE App + Mock API)
docker-compose up -d

# Verify services are running
docker-compose ps
```

### 3. Initialize Database Schema

```bash
# Run database setup (creates tables and test data)
docker exec fqge-app sqlplus fqge_user/fqge_password@oracle-db/freepdb1 @oracle_setup.sql
```

### 4. Run Quality Gate Validation

```bash
# Execute complete 4-stage pipeline
docker exec fqge-app ./fqge.sh
```

## 🔍 Detailed Stage Breakdown

### Stage A: Infrastructure Health Check 🏗️

**Purpose**: Validates the foundational infrastructure components required for application operation.

**Validations**:
- **Database Connectivity**: Oracle connection via SQL*Plus
- **Disk Space**: Ensures < 80% usage on critical partitions
- **Memory Usage**: Validates < 85% system memory consumption
- **Network Connectivity**: Internal service communication

**Success Criteria**:
```bash
✅ Database connectivity: PASS
✅ Disk space (2% used): PASS  
✅ Memory usage (15% used): PASS
```

**Configuration**:
- Database: `oracle-db:1521/freepdb1`
- User: `fqge_user/fqge_password`
- Thresholds: Disk 80%, Memory 85%

### Stage B: API Integrity & Functional Testing 🔌

**Purpose**: Validates API endpoints and creates test data for subsequent stages.

**Key Functions**:
1. **Database Connectivity**: Validates SQL*Plus connection
2. **Mock API Testing**: HTTP endpoints for order processing
3. **Order Creation**: Generates test orders with invoices
4. **Data Persistence**: Inserts into `orders` and `invoices` tables

**Order Creation Process**:
```sql
-- Creates both order and corresponding invoice
INSERT INTO orders (id, customer_id, order_status, total, created_date, updated_date)
VALUES (ORDER_ID, 1, 'COMPLETED', 99.99, SYSDATE, SYSDATE);

INSERT INTO invoices (id, order_id, invoice_number, amount, created_date)
VALUES (ORDER_ID, ORDER_ID, 'INV-' || ORDER_ID, 99.99, SYSDATE);
```

**Output**: `ORDER_ID` for Stage C validation

### Stage C: Data Persistence & Consistency 📊

**Purpose**: Validates data integrity and referential consistency across database tables.

**Validation Tests**:

1. **Order Status Verification**:
```sql
SELECT order_status FROM orders WHERE id = 'ORDER_ID';
-- Expected: 'COMPLETED'
```

2. **Referential Integrity Check**:
```sql
-- Find orders without corresponding invoices
SELECT id FROM orders WHERE order_status = 'COMPLETED'
MINUS
SELECT order_id FROM invoices;
-- Expected: No results (0 inconsistencies)
```

**Data Consistency Rules**:
- All COMPLETED orders must have corresponding invoices
- No orphaned invoice records
- Proper foreign key relationships maintained

### Stage D: Performance Load Testing ⚡

**Purpose**: Validates application performance under simulated production load.

**JMeter Test Configuration**:
- **Duration**: 9.5 minutes (570 seconds)
- **Ramp-up Pattern**: 1→10 concurrent users over 5 minutes
- **Total Requests**: 3,000 transactions
- **Target Endpoints**: Mock API service

**Performance Thresholds**:
```bash
✅ Throughput: ≥ 100 transactions/sec (Achieved: 150/sec)
✅ Response Time: ≤ 500ms average (Achieved: 300ms)
✅ Error Rate: ≤ 1% (Achieved: 0.5%)
```

**Test Scenarios**:
- Order creation API calls
- Database query operations  
- Network latency simulation
- Concurrent user load patterns

## 🗄️ Database Architecture

### Schema Design

**Tables Structure**:

```sql
-- Orders: Core business transactions
CREATE TABLE orders (
    id NUMBER PRIMARY KEY,
    customer_id NUMBER,
    order_status VARCHAR2(20) CHECK (order_status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'CANCELLED')),
    total NUMBER(10,2) CHECK (total >= 0),
    created_date DATE DEFAULT SYSDATE,
    updated_date DATE DEFAULT SYSDATE
);

-- Invoices: Financial records linked to orders
CREATE TABLE invoices (
    id NUMBER PRIMARY KEY,
    order_id NUMBER,
    invoice_number VARCHAR2(50) UNIQUE,
    amount NUMBER(10,2),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_invoice_order FOREIGN KEY (order_id) REFERENCES orders(id)
);

-- Customers: User information
CREATE TABLE customers (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    email VARCHAR2(100) UNIQUE,
    created_date DATE DEFAULT SYSDATE
);
```

**Indexes for Performance**:
```sql
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_invoices_order ON invoices(order_id);
```

### Test Data

**Initial Dataset**:
- **3 Customers**: Test user accounts
- **Dynamic Orders**: Created by Stage B during validation
- **Matching Invoices**: 1:1 relationship with completed orders

## 🐳 Docker Architecture

### Service Architecture

```yaml
services:
  # Oracle Database 23ai Free Edition
  oracle-db:
    image: gvenzl/oracle-free:latest
    environment:
      - ORACLE_PASSWORD=oracle_password
      - APP_USER=fqge_user
      - APP_USER_PASSWORD=fqge_password
    ports:
      - "1521:1521"
    
  # FQGE Application Container
  fqge-app:
    build: .
    depends_on:
      - oracle-db
      - fqge-mock-api
    environment:
      - DB_HOST=oracle-db
      - DB_SID=freepdb1
      - API_BASE_URL=http://fqge-mock-api:80
    
  # Mock API Service
  fqge-mock-api:
    image: nginx:alpine
    ports:
      - "8080:80"
```

### Container Specifications

**FQGE Application**:
- **Base**: Ubuntu 20.04 LTS
- **Java**: OpenJDK 11 (for JMeter)
- **JMeter**: 5.6.3 for performance testing
- **Oracle Client**: Instant Client for database connectivity
- **Tools**: bash, curl, bc, ssh-client

**Resource Requirements**:
- **Memory**: 6GB+ (primarily for Oracle Database)
- **CPU**: 2+ cores recommended
- **Storage**: 8GB+ for Oracle data files

## 🔄 CI/CD Integration

### GitHub Actions Workflow

The pipeline includes a comprehensive GitHub Actions workflow for automated validation:

```yaml
name: FQGE Quality Gate Pipeline

on: [push, pull_request]

jobs:
  quality-gate:
    runs-on: ubuntu-latest
    
    services:
      oracle:
        image: gvenzl/oracle-free:latest
        env:
          ORACLE_PASSWORD: oracle_password
          APP_USER: fqge_user
          APP_USER_PASSWORD: fqge_password
        ports:
          - 1521:1521
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Build FQGE Container
        run: docker build -t fqge-app .
        
      - name: Setup Database Schema
        run: |
          docker run --network host fqge-app \
            sqlplus fqge_user/fqge_password@localhost/freepdb1 @oracle_setup.sql
            
      - name: Run Quality Gate Validation
        run: |
          docker run --network host \
            -e GITHUB_ACTIONS=true \
            -e CI=true \
            fqge-app ./fqge.sh
```

### Pipeline vs Local Execution

**Environment Detection**:
```bash
# Pipeline mode detection in stages
if [ "$GITHUB_ACTIONS" = "true" ] || [ "$CI" = "true" ]; then
    # Use simplified validation for CI environment
    PERFORMANCE_MODE="simulation"
    DB_HOST="localhost"
else
    # Full validation for local development
    PERFORMANCE_MODE="full_jmeter"
    DB_HOST="oracle-db"
fi
```

## 📊 Monitoring and Reporting

### Validation Reports

**Success Output**:
```
FQGE Validation Report
======================

Stage A (Infrastructure): PASS
Stage B (API Integrity): PASS  
Stage C (Data Persistence): PASS
Stage D (Performance): PASS

FINAL DECISION: APPROVAL - Ready for UAT/Production Promotion
```

**Failure Output**:
```
FQGE Validation Report
======================

Stage A (Infrastructure): PASS
Stage B (API Integrity): PASS
Stage C (Data Persistence): FAIL
Stage D (Performance): PASS

FINAL DECISION: REJECTION - C Failure(s) - Immediate Rollback Required
```

### Detailed Logging

**Log Files Generated**:
- `fqge_report.log`: Complete execution log
- `jmeter.log`: JMeter execution details
- `jmeter_results.jtl`: Performance test results (CSV format)

**Log Analysis Examples**:
```bash
# View complete pipeline execution
docker exec fqge-app cat fqge_report.log

# Analyze performance metrics
docker exec fqge-app cat jmeter_results.jtl | grep "HTTP Request"

# Check database operations
docker logs oracle-db-container
```

## 🛠️ Troubleshooting Guide

### Common Issues and Solutions

#### 1. Database Connection Failures
```
ERROR: ORA-12514: TNS:listener does not currently know of service requested
```
**Solution**: Wait for Oracle Database initialization (2-3 minutes)
```bash
# Check Oracle container status
docker logs oracle-db-container

# Verify database is ready
docker exec fqge-app sqlplus fqge_user/fqge_password@oracle-db/freepdb1
```

#### 2. Memory Issues
```
ERROR: Container killed due to memory limit
```
**Solution**: Increase Docker Desktop memory allocation
- Windows/Mac: Docker Desktop → Settings → Resources → Memory (8GB+)
- Linux: Modify daemon configuration

#### 3. Stage C Data Inconsistency
```
ERROR: Found X data inconsistencies between Orders and Invoices tables
```
**Solution**: Clean test data between runs
```bash
# Reset database to clean state
docker exec fqge-app sqlplus fqge_user/fqge_password@oracle-db/freepdb1 << EOF
DELETE FROM invoices WHERE order_id > 1004;
DELETE FROM orders WHERE id > 1004;
COMMIT;
EOF
```

#### 4. Performance Test Failures
```
ERROR: Performance criteria not met (Throughput: 50/sec, expected ≥100/sec)
```
**Solution**: Check system resources and mock API availability
```bash
# Verify mock API is responding
curl http://localhost:8080/api/order

# Check container resource usage
docker stats
```

### Debug Mode Execution

**Enable Verbose Logging**:
```bash
# Run individual stages with debug output
docker exec fqge-app bash -x ./stageA.sh
docker exec fqge-app bash -x ./stageB.sh
docker exec fqge-app bash -x ./stageC.sh ORDER_ID
docker exec fqge-app bash -x ./stageD.sh
```

**Manual Database Testing**:
```bash
# Connect to database manually
docker exec -it fqge-app sqlplus fqge_user/fqge_password@oracle-db/freepdb1

# Check table contents
SQL> SELECT COUNT(*) FROM orders;
SQL> SELECT COUNT(*) FROM invoices;
SQL> SELECT * FROM orders WHERE rownum <= 5;
```

## 🔧 Configuration Reference

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | `oracle-db` | Oracle database hostname |
| `DB_USER` | `fqge_user` | Database username |
| `DB_PASS` | `fqge_password` | Database password |
| `DB_SID` | `FREEPDB1` | Oracle service identifier |
| `API_BASE_URL` | `http://fqge-mock-api:80` | Mock API base URL |
| `GITHUB_ACTIONS` | `false` | CI environment detection |
| `CI` | `false` | Generic CI detection |

### Performance Thresholds

**Customizable in `stageD.sh`**:
```bash
# Performance criteria (modify as needed)
MIN_THROUGHPUT=100          # transactions/second
MAX_RESPONSE_TIME=500       # milliseconds
MAX_ERROR_RATE=1           # percentage (0-100)
```

### JMeter Configuration

**Load Test Parameters** (`load_test.jmx`):
- **Thread Groups**: 10 concurrent users
- **Ramp-up Period**: 300 seconds (5 minutes)
- **Test Duration**: 570 seconds (9.5 minutes)
- **HTTP Requests**: Order creation endpoints
- **Assertions**: Response time and status code validation

## 📈 Performance Benchmarks

### Expected Results

**Infrastructure (Stage A)**:
- Database connection: < 5 seconds
- Health checks: < 10 seconds total
- Memory/disk validation: < 2 seconds

**API Testing (Stage B)**:
- Order creation: < 2 seconds
- Database insertion: < 1 second
- Mock API calls: < 500ms average

**Data Validation (Stage C)**:
- Order lookup: < 1 second
- Consistency check: < 3 seconds
- Complex queries: < 5 seconds

**Performance Testing (Stage D)**:
- JMeter startup: 30-60 seconds
- Load test execution: 9.5 minutes
- Results parsing: < 10 seconds

### Scaling Considerations

**Horizontal Scaling**:
- Multiple FQGE app instances
- Load balancer for mock API
- Oracle RAC for database clustering

**Resource Optimization**:
- JMeter heap size tuning
- Oracle SGA/PGA configuration
- Container resource limits

## 🚀 Advanced Usage

### Custom Stage Development

**Creating New Validation Stages**:

1. **Create Stage Script** (`stageE.sh`):
```bash
#!/bin/bash
set -e

# Stage E: Custom Validation
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log "Stage E: Custom validation starting..."

# Your validation logic here
# ...

log "Stage E completed successfully"
```

2. **Integrate with Main Pipeline** (`fqge.sh`):
```bash
# Add to main execution flow
execute_stage "E" "Custom Validation" "./stageE.sh"
```

### Multi-Environment Configuration

**Development Environment**:
```yaml
# docker-compose.dev.yml
services:
  fqge-app:
    environment:
      - LOG_LEVEL=DEBUG
      - PERFORMANCE_MODE=quick_test
      - DB_POOL_SIZE=5
```

**Production Simulation**:
```yaml
# docker-compose.prod.yml
services:
  fqge-app:
    environment:
      - LOG_LEVEL=INFO
      - PERFORMANCE_MODE=full_load
      - DB_POOL_SIZE=20
```

## 📚 Additional Resources

### Documentation Links

- **Oracle Database**: [Oracle 23ai Documentation](https://docs.oracle.com/en/database/)
- **Docker Compose**: [Compose Reference](https://docs.docker.com/compose/)
- **Apache JMeter**: [JMeter User Manual](https://jmeter.apache.org/usermanual/)
- **GitHub Actions**: [Workflow Syntax](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)

### Related Projects

- **Database Migration Tools**: Flyway, Liquibase
- **Performance Testing**: K6, Artillery, Gatling
- **Container Orchestration**: Kubernetes, Docker Swarm
- **CI/CD Platforms**: Jenkins, GitLab CI, Azure DevOps

## 🤝 Contributing

### Development Setup

1. **Fork and Clone**:
```bash
git clone https://github.com/YOUR_USERNAME/Quality-Pipeline-Simulator.git
cd Quality-Pipeline-Simulator
```

2. **Create Feature Branch**:
```bash
git checkout -b feature/new-validation-stage
```

3. **Development Environment**:
```bash
# Start development environment
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Run tests
docker exec fqge-app ./test_fqge.sh
```

### Contribution Guidelines

- **Code Style**: Follow existing bash scripting conventions
- **Documentation**: Update README for new features
- **Testing**: Ensure all stages pass validation
- **Commit Messages**: Use conventional commit format

### Pull Request Process

1. Update documentation for new features
2. Add test cases for new validation logic
3. Ensure CI pipeline passes
4. Request review from maintainers

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Andreea Miut** - *Initial work* - [@andreeamiut](https://github.com/andreeamiut)

## 🙏 Acknowledgments

- Oracle Corporation for the free Oracle Database container
- Apache Software Foundation for JMeter
- Docker Inc. for containerization platform
- GitHub for CI/CD infrastructure

---

**💡 Need Help?** 

- Check the [Troubleshooting Guide](#-troubleshooting-guide)
- Review [Configuration Reference](#-configuration-reference)
- Open an [Issue](https://github.com/andreeamiut/Quality-Pipeline-Simulator/issues)
- Join our [Discussions](https://github.com/andreeamiut/Quality-Pipeline-Simulator/discussions)

---

*Last Updated: November 3, 2025*
*Project Status: ✅ Production Ready*