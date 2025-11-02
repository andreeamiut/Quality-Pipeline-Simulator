# ========================================================================================
# FQGE DOCKER IMAGE BUILD CONFIGURATION
# ========================================================================================
# Purpose: Create a Docker image with all tools needed for FQGE quality validation
# Base Image: Ubuntu 20.04 (LTS with good library compatibility)
# Installed Tools:
#   - Apache JMeter 5.6.3 (for performance testing)
#   - Oracle Instant Client (for database connectivity)
#   - OpenJDK 11 (for JMeter execution)
#   - SSH client (for remote diagnostics)
#   - Various utilities (curl, wget, unzip)
# ========================================================================================

# ========================================================================================
# BASE IMAGE SELECTION
# ========================================================================================
# Ubuntu 20.04 chosen for:
# - LTS stability and security updates
# - Compatible readline libraries (fixes Stage D issues)
# - Broad package ecosystem
# ========================================================================================
FROM ubuntu:20.04

# ========================================================================================
# SYSTEM PACKAGE INSTALLATION
# ========================================================================================
# Install essential system packages required for FQGE operation
# Uses apt-get for Ubuntu/Debian package management
# ========================================================================================
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    libaio1 \
    openjdk-11-jre \
    openssh-client \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# ========================================================================================
# JMETER AND ORACLE CLIENT INSTALLATION
# ========================================================================================
# Install Apache JMeter for performance testing and Oracle Instant Client for database access
# These tools are essential for Stage D (Performance) and database connectivity validation
# ========================================================================================

# Set JMeter version as environment variable for easy updates
ENV JMETER_VERSION=5.6.3

# Download and install JMeter and Oracle Instant Client
RUN set -ex && \
    echo "Installing JMeter..." && \
    wget -q https://downloads.apache.org/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz && \
    tar -xzf apache-jmeter-${JMETER_VERSION}.tgz && \
    mv apache-jmeter-${JMETER_VERSION} /opt/jmeter && \
    rm apache-jmeter-${JMETER_VERSION}.tgz && \
    ln -s /opt/jmeter/bin/jmeter /usr/local/bin/jmeter && \
    echo "Installing Oracle Instant Client..." && \
    wget -q https://download.oracle.com/otn_software/linux/instantclient/1923000/instantclient-basic-linux.x64-19.23.0.0.0dbru.zip && \
    wget -q https://download.oracle.com/otn_software/linux/instantclient/1923000/instantclient-sqlplus-linux.x64-19.23.0.0.0dbru.zip && \
    unzip -o instantclient-basic-linux.x64-19.23.0.0.0dbru.zip && \
    unzip -o instantclient-sqlplus-linux.x64-19.23.0.0.0dbru.zip && \
    mv instantclient_19_23 /opt/oracle && \
    rm ./*.zip && \
    ln -s /opt/oracle/sqlplus /usr/local/bin/sqlplus && \
    echo /opt/oracle > /etc/ld-musl-x86_64.path

# ========================================================================================
# ENVIRONMENT CONFIGURATION
# ========================================================================================
# Set environment variables for tool accessibility and Oracle client configuration
# ========================================================================================
ENV PATH="/opt/jmeter/bin:/opt/oracle:${PATH}"
ENV LD_LIBRARY_PATH="/opt/oracle:${LD_LIBRARY_PATH}"
ENV ORACLE_HOME="/opt/oracle"

# ========================================================================================
# APPLICATION DIRECTORY SETUP
# ========================================================================================
# Create and set the working directory for FQGE application files
# ========================================================================================
WORKDIR /app

# ========================================================================================
# APPLICATION FILE COPY
# ========================================================================================
# Copy all FQGE project files into the container
# This includes scripts, configurations, and test data
# ========================================================================================
COPY . .

# ========================================================================================
# SCRIPT PERMISSIONS
# ========================================================================================
# Make all shell scripts executable for FQGE pipeline execution
# ========================================================================================
RUN chmod +x ./*.sh

# ========================================================================================
# DEFAULT CONTAINER COMMAND
# ========================================================================================
# Set default command to bash for interactive container usage
# Allows manual execution of FQGE scripts or debugging
# ========================================================================================
CMD ["bash"]