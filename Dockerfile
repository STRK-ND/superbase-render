FROM debian:bullseye-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install PostgreSQL
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/postgresql.list \
    && apt-get update \
    && apt-get install -y postgresql-14 postgresql-contrib-14 \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js for GoTrue and other services
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user to run services
RUN useradd -m -s /bin/bash supabase

# Set up PostgreSQL
USER postgres
RUN /etc/init.d/postgresql start && \
    psql --command "CREATE USER supabase_admin WITH SUPERUSER PASSWORD 'postgres';" && \
    createdb -O supabase_admin postgres && \
    /etc/init.d/postgresql stop

# Copy configuration files
USER root
WORKDIR /app

# Download and install GoTrue (Auth)
RUN curl -L https://github.com/supabase/gotrue/releases/download/v2.171.0/gotrue_Linux_x86_64.tar.gz | tar xz -C /usr/local/bin

# Download and install PostgREST (REST API)
RUN curl -L https://github.com/PostgREST/postgrest/releases/download/v12.2.11/postgrest-v12.2.11-linux-static-x64.tar.xz | tar xJ -C /usr/local/bin

# Download and install Kong (API Gateway)
RUN curl -Lo kong.deb https://download.konghq.com/gateway-2.x-debian-buster/pool/all/k/kong/kong_2.8.1_amd64.deb \
    && apt-get update \
    && apt-get install -y ./kong.deb \
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
    API_EXTERNAL_URL=http://localhost:8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
  CMD pg_isready -U postgres || exit 1

CMD ["/app/start.sh"]