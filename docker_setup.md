# FQGE Docker Environment Setup

This document provides instructions for setting up and running the FullStack Quality Gate Expert (FQGE) system in a Docker environment for testing and development.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 4GB RAM available for containers
- At least 10GB free disk space

## Architecture

The Docker environment includes:

- **Oracle DB**: Oracle XE 21c database with pre-loaded test data
- **FQGE App**: Alpine Linux container with all required tools (JMeter, SQL*Plus, curl, SSH)
- **Mock API**: Nginx-based mock API server for testing API endpoints

## Quick Start

1. **Clone or ensure all files are present**:
   ```bash
   ls -la
   # Should see: docker-compose.yml, Dockerfile, oracle_setup.sql, etc.
   ```

2. **Run the automated setup**:
   ```bash
   chmod +x run_docker_test.sh
   ./run_docker_test.sh
   ```

3. **Manual setup (alternative)**:
   ```bash
   # Start services
   docker-compose up -d

   # Wait for Oracle DB (about 30 seconds)
   sleep 30

   # Check services
   docker-compose ps

   # Run FQGE test
   docker-compose exec fqge-app ./test_fqge.sh
   ```

## Configuration

### Environment Variables

The following environment variables are configured in `docker-compose.override.yml`:

```yaml
environment:
  - DB_HOST=oracle-db
  - DB_USER=fqge_user
  - DB_PASS=fqge_password
  - DB_SID=XE
  - REMOTE_HOST=fqge-app
  - REMOTE_USER=root
  - SSH_KEY=/root/.ssh/id_rsa
  - JMETER_HOME=/opt/jmeter
```

### Database Connection

- **Host**: oracle-db (Docker service name)
- **Port**: 1521
- **SID**: XE
- **Username**: fqge_user
- **Password**: fqge_password

### Mock API Endpoints

- **Status Check**: `GET http://localhost:8080/api/status`
- **Order Creation**: `POST http://localhost:8080/api/order`

## Database Setup

The Oracle database is automatically initialized with:

- **Tables**: ORDERS, INVOICES, CUSTOMERS
- **Indexes**: Primary keys and foreign key indexes
- **Test Data**: Sample orders, invoices, and customers
- **Validation Scripts**: Pre-loaded SQL validation queries

### Connecting to Database

```bash
# From host machine
sqlplus fqge_user/fqge_password@//localhost:1521/XE

# From FQGE container
docker-compose exec fqge-app sqlplus fqge_user/fqge_password@//oracle-db:1521/XE
```

## Running Tests

### Basic System Test

```bash
docker-compose exec fqge-app ./test_fqge.sh
```

### Oracle Validation Tests

```bash
docker-compose exec fqge-app sqlplus fqge_user/fqge_password@//oracle-db:1521/XE @oracle_test_runner.sql
```

### API Tests

```bash
# Test status endpoint
curl http://localhost:8080/api/status

# Test order creation
curl -X POST http://localhost:8080/api/order \
  -H "Content-Type: application/json" \
  -d '{"customer_id": 123, "items": [{"product_id": 456, "quantity": 2}], "total": 100.00}'
```

### Performance Tests

```bash
docker-compose exec fqge-app /opt/jmeter/bin/jmeter -n -t load_test.jmx -l results.jtl
```

## Troubleshooting

### Common Issues

1. **Oracle DB won't start**:
   ```bash
   docker-compose logs oracle-db
   # Check for memory or disk space issues
   ```

2. **SQL*Plus connection fails**:
   ```bash
   # Test connection
   docker-compose exec fqge-app sqlplus -s fqge_user/fqge_password@//oracle-db:1521/XE <<< "SELECT 1 FROM dual;"
   ```

3. **Mock API not responding**:
   ```bash
   docker-compose logs mock-api
   curl http://localhost:8080/api/status
   ```

4. **JMeter not found**:
   ```bash
   docker-compose exec fqge-app which jmeter
   docker-compose exec fqge-app ls -la /opt/jmeter/
   ```

### Logs and Debugging

```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs oracle-db
docker-compose logs fqge-app
docker-compose logs mock-api

# Access container shell
docker-compose exec fqge-app bash
docker-compose exec oracle-db bash
```

### Reset Environment

```bash
# Stop and remove everything
docker-compose down -v

# Rebuild and restart
docker-compose up -d --build
```

## Performance Considerations

- **Memory**: Oracle XE requires at least 2GB RAM
- **Disk**: Database files may grow to several GB
- **CPU**: JMeter tests benefit from multiple cores
- **Network**: All services communicate via Docker network

## Security Notes

- Default passwords are used for testing only
- SSH keys are auto-generated for container communication
- No external ports exposed except for testing (1521, 8080)
- All services run in isolated Docker network

## Customization

### Adding Custom Test Data

1. Modify `oracle_setup.sql`
2. Rebuild the environment:
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

### Modifying Mock API

1. Edit `mock-api.conf`
2. Restart mock-api service:
   ```bash
   docker-compose restart mock-api
   ```

### Custom JMeter Tests

1. Modify `load_test.jmx`
2. Rebuild FQGE container:
   ```bash
   docker-compose up -d --build fqge-app
   ```

## Production Deployment

For production use:

1. Use production-grade Oracle database
2. Configure proper authentication and authorization
3. Set up monitoring and logging
4. Implement backup and recovery procedures
5. Configure network security (firewalls, SSL/TLS)
6. Use environment-specific configuration files

## Support

For issues with the Docker environment:

1. Check logs: `docker-compose logs`
2. Verify system requirements
3. Ensure no port conflicts (1521, 8080)
4. Test individual components before running full system