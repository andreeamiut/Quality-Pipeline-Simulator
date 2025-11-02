# FQGE - FullStack Quality Gate Expert

## Overview

FQGE (FullStack Quality Gate Expert) is an autonomous quality gate system for CI/CD pipelines that performs comprehensive validation across multiple dimensions:

- **Infrastructure Health Check** (Stage A)
- **API Integrity & Functional Testing** (Stage B)
- **Data Persistence & Consistency** (Stage C)
- **Performance Load Testing** (Stage D)

## Architecture

The system uses Docker containers with:
- Oracle Database 21c XE for data persistence testing
- Alpine Linux container with JMeter for performance testing
- Automated test execution and reporting

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- GitHub repository with this codebase

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd qualityGate
   ```

2. **Start the environment**
   ```bash
   docker-compose up -d
   ```

3. **Run FQGE validation**
   ```bash
   docker-compose exec fqge-app ./fqge.sh
   ```

### CI/CD Pipeline

The GitHub Actions pipeline automatically runs on:
- Push to `main` or `develop` branches
- Pull requests to `main` branch

Pipeline stages:
1. Build FQGE Docker image
2. Setup Oracle database with test data
3. Execute quality gate validation
4. Generate and upload reports
5. Fail pipeline if quality gate fails

## Project Structure

```
qualityGate/
├── .github/workflows/          # GitHub Actions pipeline
├── docker-compose.yml          # Docker Compose configuration
├── docker-compose.override.yml # Development overrides
├── Dockerfile                  # FQGE application container
├── fqge.sh                     # Main quality gate script
├── stageA.sh                   # Infrastructure health check
├── stageB.sh                   # API integrity testing
├── stageC.sh                   # Data persistence validation
├── stageD.sh                   # Performance load testing
├── oracle_setup.sql            # Database schema setup
├── oracle_tests.sql            # Test data and queries
├── oracle_validation.sql       # Data validation queries
├── load_test.jmx               # JMeter performance test
├── mock-api.conf               # Mock API configuration
└── README.md                   # This file
```

## Quality Gate Stages

### Stage A: Infrastructure Health Check
- Validates database connectivity
- Checks system resources
- Verifies service availability

### Stage B: Core Functional & API Integrity
- Tests API endpoints
- Validates business logic
- Checks data flow integrity

### Stage C: Data Persistence & Consistency
- Validates database constraints
- Checks referential integrity
- Performs data consistency tests

### Stage D: Performance Load Test
- Executes JMeter load tests
- Monitors response times
- Validates performance thresholds

## Configuration

### Environment Variables
- `DB_HOST`: Database host (default: oracle-db)
- `DB_USER`: Database user (default: fqge_user)
- `DB_PASS`: Database password (default: fqge_password)
- `DB_SID`: Database SID (default: XE)

### Test Data
The system includes sample data for testing:
- Customers, Orders, and Invoices tables
- Pre-configured test scenarios
- Validation queries for data integrity

## Reports

FQGE generates detailed reports including:
- Stage-by-stage execution results
- Failure analysis and root cause
- Performance metrics
- Data validation summaries

Reports are saved to `fqge_report.log` and uploaded as artifacts in CI/CD.

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Ensure Oracle container is healthy
   - Check network connectivity between containers

2. **Permission Denied**
   - Verify file permissions on scripts
   - Check Docker volume mounts

3. **Performance Test Failures**
   - Review JMeter configuration
   - Check system resources during testing

### Logs
- Application logs: `fqge_report.log`
- Database logs: `docker logs oracle-db`
- Container logs: `docker-compose logs`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test locally
4. Submit a pull request
5. Quality gate will run automatically

## License

This project is licensed under the MIT License - see the LICENSE file for details.