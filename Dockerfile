FROM debian:bullseye-slim

# Install dependencies (minimized for free plan)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install PostgreSQL (optimized for low memory usage)
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/postgresql.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-14 \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user to run services
RUN useradd -m -s /bin/bash supabase

# Set up PostgreSQL with optimized settings for low memory
USER postgres
RUN /etc/init.d/postgresql start && \
    psql --command "CREATE USER supabase_admin WITH SUPERUSER PASSWORD 'postgres';" && \
    psql --command "ALTER DATABASE postgres OWNER TO supabase_admin;" && \
    echo "shared_buffers = 128MB" >> /etc/postgresql/14/main/conf.d/custom.conf && \
    echo "effective_cache_size = 256MB" >> /etc/postgresql/14/main/conf.d/custom.conf && \
    echo "work_mem = 16MB" >> /etc/postgresql/14/main/conf.d/custom.conf && \
    echo "maintenance_work_mem = 64MB" >> /etc/postgresql/14/main/conf.d/custom.conf && \
    echo "max_connections = 20" >> /etc/postgresql/14/main/conf.d/custom.conf && \
    echo "max_worker_processes = 2" >> /etc/postgresql/14/main/conf.d/custom.conf && \
    echo "max_parallel_workers = 2" >> /etc/postgresql/14/main/conf.d/custom.conf && \
    /etc/init.d/postgresql stop

# Copy configuration files
USER root
WORKDIR /app

# Download and install GoTrue (Auth)
RUN curl -L https://github.com/supabase/gotrue/releases/download/v2.171.0/gotrue_Linux_x86_64.tar.gz | tar xz -C /usr/local/bin

# Download and install PostgREST (REST API)
RUN curl -L https://github.com/PostgREST/postgrest/releases/download/v12.2.11/postgrest-v12.2.11-linux-static-x64.tar.xz | tar xJ -C /usr/local/bin

# Download and install Kong (API Gateway) - minimized installation
RUN curl -Lo kong.deb https://download.konghq.com/gateway-2.x-debian-buster/pool/all/k/kong/kong_2.8.1_amd64.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends ./kong.deb \
    && rm kong.deb \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY config/ /app/config/

# Create directories for data persistence
RUN mkdir -p /var/lib/postgresql/data /var/log/postgresql /var/lib/supabase \
    && chown -R postgres:postgres /var/lib/postgresql \
    && chown -R supabase:supabase /var/lib/supabase

# Expose ports
EXPOSE 8000 5432

# Copy startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Set environment variables
ENV POSTGRES_PASSWORD=postgres \
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
    POSTGRES_MAINTENANCE_WORK_MEM=64MB

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
  CMD pg_isready -U postgres || exit 1

CMD ["/app/start.sh"]