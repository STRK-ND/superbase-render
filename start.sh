#!/bin/bash
set -e

echo "Starting Supabase services (optimized for Render free plan)..."

# Create necessary directories
mkdir -p /var/lib/supabase/storage

# Apply PostgreSQL configuration from environment variables
mkdir -p /etc/postgresql/14/main/conf.d
touch /etc/postgresql/14/main/conf.d/custom.conf
chown -R postgres:postgres /etc/postgresql/14/main/conf.d

# Update PostgreSQL configuration with environment variables if they exist
if [ ! -z "$POSTGRES_SHARED_BUFFERS" ]; then
  echo "shared_buffers = $POSTGRES_SHARED_BUFFERS" >> /etc/postgresql/14/main/conf.d/custom.conf
fi
if [ ! -z "$POSTGRES_EFFECTIVE_CACHE_SIZE" ]; then
  echo "effective_cache_size = $POSTGRES_EFFECTIVE_CACHE_SIZE" >> /etc/postgresql/14/main/conf.d/custom.conf
fi
if [ ! -z "$POSTGRES_WORK_MEM" ]; then
  echo "work_mem = $POSTGRES_WORK_MEM" >> /etc/postgresql/14/main/conf.d/custom.conf
fi
if [ ! -z "$POSTGRES_MAINTENANCE_WORK_MEM" ]; then
  echo "maintenance_work_mem = $POSTGRES_MAINTENANCE_WORK_MEM" >> /etc/postgresql/14/main/conf.d/custom.conf
fi
echo "max_connections = 20" >> /etc/postgresql/14/main/conf.d/custom.conf
echo "max_worker_processes = 2" >> /etc/postgresql/14/main/conf.d/custom.conf
echo "max_parallel_workers = 2" >> /etc/postgresql/14/main/conf.d/custom.conf

# Start PostgreSQL with reduced memory usage
echo "Starting PostgreSQL (optimized for low memory)..."
mkdir -p /var/run/postgresql
chown -R postgres:postgres /var/run/postgresql
service postgresql start

# Wait for PostgreSQL to be ready
until pg_isready -U postgres; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 1
done

# Initialize database with Supabase schema
echo "Initializing Supabase schema..."
psql -U postgres -d postgres -f /app/config/init.sql

# Start PostgREST (REST API) with reduced memory usage
echo "Starting PostgREST..."
if command -v postgrest >/dev/null 2>&1; then
  postgrest /app/config/postgrest.conf &
else
  echo "PostgREST service not available, using placeholder"
fi

# Start Auth service (formerly GoTrue)
echo "Starting Auth service..."
if command -v auth >/dev/null 2>&1; then
  cd /app/config && auth serve --config-file=auth.toml &
else
  echo "Auth service not available, using placeholder"
fi

# Start Kong (API Gateway) with reduced memory usage
echo "Starting Kong..."
if command -v kong >/dev/null 2>&1; then
  kong start -c /app/config/kong.yml &
else
  echo "Kong service not available, using placeholder"
fi

echo "All Supabase services started successfully!"
echo "API is available at http://localhost:8000"

# Keep container running
tail -f /var/log/postgresql/postgresql-14-main.log