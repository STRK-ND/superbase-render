#!/bin/bash
set -e

echo "Starting Supabase services (optimized for Render free plan)..."

# Create necessary directories
mkdir -p /var/lib/supabase/storage

# Apply PostgreSQL configuration from environment variables
if [ -f /etc/postgresql/14/main/conf.d/custom.conf ]; then
  # Update PostgreSQL configuration with environment variables if they exist
  if [ ! -z "$POSTGRES_SHARED_BUFFERS" ]; then
    sed -i "s/shared_buffers = .*/shared_buffers = $POSTGRES_SHARED_BUFFERS/" /etc/postgresql/14/main/conf.d/custom.conf
  fi
  if [ ! -z "$POSTGRES_EFFECTIVE_CACHE_SIZE" ]; then
    sed -i "s/effective_cache_size = .*/effective_cache_size = $POSTGRES_EFFECTIVE_CACHE_SIZE/" /etc/postgresql/14/main/conf.d/custom.conf
  fi
  if [ ! -z "$POSTGRES_WORK_MEM" ]; then
    sed -i "s/work_mem = .*/work_mem = $POSTGRES_WORK_MEM/" /etc/postgresql/14/main/conf.d/custom.conf
  fi
  if [ ! -z "$POSTGRES_MAINTENANCE_WORK_MEM" ]; then
    sed -i "s/maintenance_work_mem = .*/maintenance_work_mem = $POSTGRES_MAINTENANCE_WORK_MEM/" /etc/postgresql/14/main/conf.d/custom.conf
  fi
fi

# Start PostgreSQL with reduced memory usage
echo "Starting PostgreSQL (optimized for low memory)..."
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
postgrest /app/config/postgrest.conf &

# Start GoTrue (Auth)
echo "Starting GoTrue..."
cd /app/config && gotrue serve &

# Start Kong (API Gateway) with reduced memory usage
echo "Starting Kong..."
kong start -c /app/config/kong.yml &

echo "All Supabase services started successfully!"
echo "API is available at http://localhost:8000"

# Keep container running
tail -f /var/log/postgresql/postgresql-14-main.log