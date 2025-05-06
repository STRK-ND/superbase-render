#!/bin/bash
set -e

echo "Starting Supabase services..."

# Create necessary directories
mkdir -p /var/lib/supabase/storage

# Start PostgreSQL
echo "Starting PostgreSQL..."
service postgresql start

# Wait for PostgreSQL to be ready
until pg_isready -U postgres; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 1
done

# Initialize database with Supabase schema
echo "Initializing Supabase schema..."
psql -U postgres -d postgres -f /app/config/init.sql

# Start PostgREST (REST API)
echo "Starting PostgREST..."
postgrest /app/config/postgrest.conf &

# Start GoTrue (Auth)
echo "Starting GoTrue..."
cd /app/config && gotrue serve &

# Start Kong (API Gateway)
echo "Starting Kong..."
kong start -c /app/config/kong.yml &

echo "All Supabase services started successfully!"
echo "API is available at http://localhost:8000"

# Keep container running
tail -f /var/log/postgresql/postgresql-14-main.log