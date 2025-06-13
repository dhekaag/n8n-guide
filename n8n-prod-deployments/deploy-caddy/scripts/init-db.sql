-- N8N Database Initialization Script
-- This script sets up the initial database configuration for n8n

-- Create database if it doesn't exist (already handled by docker-compose)
-- CREATE DATABASE IF NOT EXISTS n8n;

-- Create additional user if specified
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'n8n_user') THEN
        RAISE NOTICE 'Role "n8n_user" already exists. Skipping.';
    ELSE
        CREATE ROLE n8n_user WITH LOGIN PASSWORD 'your-user-password';
    END IF;
END
$$;

-- Grant necessary permissions
GRANT CONNECT ON DATABASE n8n TO n8n_user;
GRANT USAGE ON SCHEMA public TO n8n_user;
GRANT CREATE ON SCHEMA public TO n8n_user;

-- Create extensions that might be useful for n8n
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Set up proper permissions for n8n user
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO n8n_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO n8n_user;

-- Log the initialization
INSERT INTO pg_stat_user_tables (schemaname, relname) 
SELECT 'public', 'n8n_init_log' 
WHERE NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'n8n_init_log');

-- Create a simple log table for tracking initialization
CREATE TABLE IF NOT EXISTS n8n_init_log (
    id SERIAL PRIMARY KEY,
    initialized_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    version VARCHAR(50) DEFAULT 'v1.0.0'
);

-- Insert initialization record
INSERT INTO n8n_init_log (initialized_at) VALUES (CURRENT_TIMESTAMP);