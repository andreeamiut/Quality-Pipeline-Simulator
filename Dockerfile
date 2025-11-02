FROM alpine:3.19

# Install required packages
RUN apk add --no-cache \
    bash \
    curl \
    openjdk11-jre \
    openssh-client \
    unzip \
    wget \
    && rm -rf /var/cache/apk/*

# Install JMeter and Oracle Instant Client (for SQL*Plus)
ENV JMETER_VERSION=5.6.3
RUN set -e && \
    wget -q https://downloads.apache.org/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz && \
    tar -xzf apache-jmeter-${JMETER_VERSION}.tgz && \
    mv apache-jmeter-${JMETER_VERSION} /opt/jmeter && \
    rm apache-jmeter-${JMETER_VERSION}.tgz && \
    ln -s /opt/jmeter/bin/jmeter /usr/local/bin/jmeter && \
    wget -q https://download.oracle.com/otn_software/linux/instantclient/1923000/instantclient-basic-linux.x64-19.23.0.0.0dbru.zip && \
    wget -q https://download.oracle.com/otn_software/linux/instantclient/1923000/instantclient-sqlplus-linux.x64-19.23.0.0.0dbru.zip && \
    unzip instantclient-basic-linux.x64-19.23.0.0.0dbru.zip && \
    unzip instantclient-sqlplus-linux.x64-19.23.0.0.0dbru.zip && \
    mv instantclient_19_23 /opt/oracle && \
    rm ./*.zip && \
    ln -s /opt/oracle/sqlplus /usr/local/bin/sqlplus && \
    echo /opt/oracle > /etc/ld-musl-x86_64.path

# Set environment variables
ENV PATH="/opt/jmeter/bin:/opt/oracle:${PATH}"
ENV LD_LIBRARY_PATH="/opt/oracle:${LD_LIBRARY_PATH}"
ENV ORACLE_HOME="/opt/oracle"

# Create app directory
WORKDIR /app

# Copy FQGE files
COPY . .

# Make scripts executable
RUN chmod +x ./*.sh

# Default command
CMD ["bash"]