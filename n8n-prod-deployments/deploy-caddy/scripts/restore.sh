#!/bin/bash

# N8N Restore Script
# Restores n8n data, database, and configuration from backup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/env/.env.production"
COMPOSE_FILE="$PROJECT_DIR/docker/docker-compose.yml"

# Check if backup file is provided
if [[ $# -eq 0 ]]; then
    echo -e "${RED}❌ Usage: $0 <backup_file.tar.gz>${NC}"
    echo -e "${YELLOW}Available backups:${NC}"
    if [[ -d "$PROJECT_DIR/backups" ]]; then
        ls -la "$PROJECT_DIR/backups"/*.tar.gz 2>/dev/null || echo "No backup files found"
    else
        echo "No backup directory found"
    fi
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [[ ! -f "$BACKUP_FILE" ]]; then
    echo -e "${RED}❌ Backup file not found: $BACKUP_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}🔄 Starting N8N Restore Process...${NC}"
echo -e "${BLUE}📦 Backup file: $BACKUP_FILE${NC}"

# Confirm restore operation
echo -e "${YELLOW}⚠️  WARNING: This will overwrite existing data!${NC}"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}❌ Restore operation cancelled${NC}"
    exit 1
fi

# Check if environment file exists
if [[ ! -f "$ENV_FILE" ]]; then
    echo -e "${RED}❌ Environment file not found: $ENV_FILE${NC}"
    exit 1
fi

# Load environment variables
source "$ENV_FILE"

# Use docker-compose or docker compose based on availability
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

# Create temporary restore directory
RESTORE_DIR=$(mktemp -d)
echo -e "${BLUE}📁 Temporary restore directory: $RESTORE_DIR${NC}"

# Extract backup
echo -e "${BLUE}📦 Extracting backup...${NC}"
tar xzf "$BACKUP_FILE" -C "$RESTORE_DIR" --strip-components=1

# Check if backup contains expected files
if [[ ! -f "$RESTORE_DIR/database.sql" ]]; then
    echo -e "${RED}❌ Invalid backup: database.sql not found${NC}"
    rm -rf "$RESTORE_DIR"
    exit 1
fi

# Stop services
echo -e "${YELLOW}🛑 Stopping services...${NC}"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down

# Restore configuration files
echo -e "${BLUE}⚙️ Restoring configuration files...${NC}"
if [[ -d "$RESTORE_DIR/config" ]]; then
    cp -r "$RESTORE_DIR/config" "$PROJECT_DIR/"
    echo -e "${GREEN}✅ Configuration files restored${NC}"
fi

# Start only database and redis services
echo -e "${BLUE}🚀 Starting database and Redis services...${NC}"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d postgres redis

# Wait for database to be ready
echo -e "${BLUE}⏳ Waiting for database to be ready...${NC}"
sleep 10

# Check database health
for i in {1..30}; do
    if docker exec n8n-postgres pg_isready -U "$DATABASE_USER" -d "$DATABASE_NAME" &>/dev/null; then
        echo -e "${GREEN}✅ Database is ready${NC}"
        break
    fi
    if [[ $i -eq 30 ]]; then
        echo -e "${RED}❌ Database failed to start${NC}"
        exit 1
    fi
    sleep 2
done

# Drop and recreate database
echo -e "${BLUE}🗄️ Preparing database for restore...${NC}"
docker exec n8n-postgres psql -U "$DATABASE_USER" -d postgres -c "DROP DATABASE IF EXISTS $DATABASE_NAME;"
docker exec n8n-postgres psql -U "$DATABASE_USER" -d postgres -c "CREATE DATABASE $DATABASE_NAME;"

# Restore database
echo -e "${BLUE}📥 Restoring database...${NC}"
docker exec -i n8n-postgres psql -U "$DATABASE_USER" -d "$DATABASE_NAME" < "$RESTORE_DIR/database.sql"
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Database restored successfully${NC}"
else
    echo -e "${RED}❌ Database restore failed${NC}"
    exit 1
fi

# Stop services to restore volumes
echo -e "${YELLOW}🛑 Stopping services to restore volumes...${NC}"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down

# Restore n8n data volume
if [[ -f "$RESTORE_DIR/n8n_data.tar.gz" ]]; then
    echo -e "${BLUE}📂 Restoring n8n data volume...${NC}"
    docker run --rm \
        -v "$(basename "$PROJECT_DIR")_n8n_data":/data \
        -v "$RESTORE_DIR":/backup \
        alpine:latest \
        sh -c "rm -rf /data/* && tar xzf /backup/n8n_data.tar.gz -C /data"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ n8n data volume restored${NC}"
    else
        echo -e "${RED}❌ n8n data volume restore failed${NC}"
    fi
fi

# Restore Redis data volume
if [[ -f "$RESTORE_DIR/redis_data.tar.gz" ]]; then
    echo -e "${BLUE}🔄 Restoring Redis data volume...${NC}"
    docker run --rm \
        -v "$(basename "$PROJECT_DIR")_redis_data":/data \
        -v "$RESTORE_DIR":/backup \
        alpine:latest \
        sh -c "rm -rf /data/* && tar xzf /backup/redis_data.tar.gz -C /data"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Redis data volume restored${NC}"
    else
        echo -e "${RED}❌ Redis data volume restore failed${NC}"
    fi
fi

# Start all services
echo -e "${BLUE}🚀 Starting all services...${NC}"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

# Wait for services to be healthy
echo -e "${BLUE}⏳ Waiting for services to be healthy...${NC}"
sleep 30

# Check service status
echo -e "${BLUE}📊 Checking service status...${NC}"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps

# Cleanup
echo -e "${BLUE}🧹 Cleaning up temporary files...${NC}"
rm -rf "$RESTORE_DIR"

# Display backup info if available
if [[ -f "$RESTORE_DIR/backup_info.txt" ]]; then
    echo -e "${BLUE}📋 Backup Information:${NC}"
    cat "$RESTORE_DIR/backup_info.txt"
fi

echo -e "${GREEN}🎉 Restore completed successfully!${NC}"
echo -e "${GREEN}📝 Post-restore Information:${NC}"
echo -e "   🌐 URL: https://$N8N_HOST"
echo -e "   👤 Username: $N8N_BASIC_AUTH_USER"
echo -e "   🔑 Password: [Check your .env.production file]"
echo -e ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo -e "   1. Verify all workflows are working correctly"
echo -e "   2. Check logs: $DOCKER_COMPOSE -f $COMPOSE_FILE logs -f"
echo -e "   3. Test webhooks and integrations"
echo -e "   4. Update environment variables if needed"