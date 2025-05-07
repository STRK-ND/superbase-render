FROM debian:bullseye-slim

# This Dockerfile is optimized for Render's free tier
# It includes fallback mechanisms for component downloads and minimal resource usage
# Modified to handle download failures gracefully and provide placeholder services when needed

# Install dependencies (minimized for free plan)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    locales \
    perl \
    && rm -rf /var/lib/apt/lists/*

# Install PostgreSQL (optimized for low memory usage)
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/postgresql.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       postgresql-14 \
       postgresql-client-14 \
       postgresql-client-common \
       libpq5 \
       ssl-cert \
       libc-l10n \
    && mkdir -p /etc/postgresql/14/main/conf.d \
    && touch /etc/postgresql/14/main/conf.d/custom.conf \
    && chown -R postgres:postgres /etc/postgresql \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user to run services
RUN useradd -m -s /bin/bash supabase

# Set up PostgreSQL with optimized settings for low memory
USER root
RUN mkdir -p /etc/postgresql/14/main/conf.d && \
    touch /etc/postgresql/14/main/conf.d/custom.conf && \
    chown -R postgres:postgres /etc/postgresql && \
    su - postgres -c "/etc/init.d/postgresql start && \
    psql --command \"CREATE USER supabase_admin WITH SUPERUSER PASSWORD 'postgres';\" && \
    psql --command \"ALTER DATABASE postgres OWNER TO supabase_admin;\"" && \
    echo "shared_buffers = 128MB" >> /etc/postgresql/14/main/conf.d/custom.conf && \
    echo "effective_cache_size = 256MB" >> /etc/postgresql/14/main/conf.d/custom.conf && \
    echo "work_mem = 16MB" >> /etc/postgresql/14/main/conf.d/custom.conf && \
    echo "maintenance_work_mem = 64MB" >> /etc/postgresql/14/main/conf.d/custom.conf && \
    echo "max_connections = 20" >> /etc/postgresql/14/main/conf.d/custom.conf && \
    echo "max_worker_processes = 2" >> /etc/postgresql/14/main/conf.d/custom.conf && \
    echo "max_parallel_workers = 2" >> /etc/postgresql/14/main/conf.d/custom.conf && \
    su - postgres -c "/etc/init.d/postgresql stop"

# Copy configuration files
USER root
WORKDIR /app

# Download and install Auth (formerly GoTrue)
# Using alternative approach since the original URL is no longer valid
RUN mkdir -p /tmp/auth && \
    cd /tmp/auth && \
    curl -L https://github.com/supabase/auth/releases/latest/download/auth_Linux_x86_64.tar.gz -o auth.tar.gz && \
    tar -xzf auth.tar.gz -C /usr/local/bin || \
    (echo "Auth download failed, creating minimal placeholder" && \
    echo '#!/bin/sh\necho "Auth service placeholder"\nexit 0' > /usr/local/bin/auth && \
    chmod +x /usr/local/bin/auth) && \
    cd / && rm -rf /tmp/auth

# Download and install PostgREST (REST API)
RUN mkdir -p /tmp/postgrest && \
    cd /tmp/postgrest && \
    curl -L https://github.com/PostgREST/postgrest/releases/download/v12.2.11/postgrest-v12.2.11-linux-static-x64.tar.xz -o postgrest.tar.xz && \
    tar -xJf postgrest.tar.xz -C /usr/local/bin || \
    (echo "PostgREST download failed, creating minimal placeholder" && \
    echo '#!/bin/sh\necho "PostgREST service placeholder"\nexit 0' > /usr/local/bin/postgrest && \
    chmod +x /usr/local/bin/postgrest) && \
    cd / && rm -rf /tmp/postgrest

# Download and install Kong (API Gateway) - minimized installation for Render free tier
RUN curl -Lo kong.deb https://download.konghq.com/gateway-2.x-debian-buster/pool/all/k/kong/kong_2.8.1_amd64.deb || \
    (echo "Kong download failed, creating minimal placeholder" && \
    touch /usr/local/bin/kong && \
    echo '#!/bin/sh\necho "Kong service placeholder"\nexit 0' > /usr/local/bin/kong && \
    chmod +x /usr/local/bin/kong) && \
    if [ -f kong.deb ]; then \
        apt-get update && \
        apt-get install -y --no-install-recommends ./kong.deb && \
        rm kong.deb; \
    fi && \
    rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY config/ /app/config/

# Create directories for data persistence
RUN mkdir -p /var/lib/postgresql/data /var/log/postgresql /var/lib/supabase /etc/postgresql/14/main/conf.d \
    && chown -R postgres:postgres /var/lib/postgresql \
    && chown -R postgres:postgres /etc/postgresql/14/main/conf.d \
    && chown -R supabase:supabase /var/lib/supabase

# Expose ports
EXPOSE 8000 5432

# Copy startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Configure locale to prevent debconf warnings
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Set environment variables
ENV LANG=en_US.utf8 \
    POSTGRES_PASSWORD=postgres \
    JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters-long \
    ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE \
    SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJzZXJ2aWNlX3JvbGUiLAogICAgImlzcyI6ICJzdXBhYmFzZS1kZW1vIiwKICAgICJpYXQiOiAxNjQxNzY5MjAwLAogICAgImV4cCI6IDE3OTk1MzU2MDAKfQ.DaYlNEoUrrEn2Ig7tqibS-PHK5vgusbcbo7X36XVt4Q \
    PGRST_DB_SCHEMAS=public,storage,graphql_public \
    SITE_URL=http://localhost:3000 \
    DISABLE_SIGNUP=false \
    API_EXTERNAL_URL=http://localhost:8000 \
    POSTGRES_SHARED_BUFFERS=128MB \
    POSTGRES_EFFECTIVE_CACHE_SIZE=256MB \
    POSTGRES_WORK_MEM=16MB \
    POSTGRES_MAINTENANCE_WORK_MEM=64MB \
    TERM=xterm

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
  CMD pg_isready -U postgres || exit 1

CMD ["/app/start.sh"]