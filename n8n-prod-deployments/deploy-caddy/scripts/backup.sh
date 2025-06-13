#!/bin/bash

# N8N Backup Script
# Creates backups of n8n data, database, and configuration

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
BACKUP_DIR="$PROJECT_DIR/backups"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_NAME="n8n_backup_$TIMESTAMP"

echo -e "${GREEN}📦 Starting N8N Backup Process...${NC}"

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

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create backup subdirectory
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
mkdir -p "$BACKUP_PATH"

echo -e "${BLUE}📁 Backup directory: $BACKUP_PATH${NC}"

# Backup PostgreSQL database
echo -e "${BLUE}🗄️ Backing up PostgreSQL database...${NC}"
docker exec n8n-postgres pg_dump -U "$DATABASE_USER" -d "$DATABASE_NAME" > "$BACKUP_PATH/database.sql"
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Database backup completed${NC}"
else
    echo -e "${RED}❌ Database backup failed${NC}"
fi

# Backup n8n data volume
echo -e "${BLUE}📂 Backing up n8n data volume...${NC}"
docker run --rm \
    -v "$(basename "$PROJECT_DIR")_n8n_data":/data \
    -v "$BACKUP_PATH":/backup \
    alpine:latest \
    tar czf /backup/n8n_data.tar.gz -C /data .

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ n8n data backup completed${NC}"
else
    echo -e "${RED}❌ n8n data backup failed${NC}"
fi

# Backup Redis data (optional)
echo -e "${BLUE}🔄 Backing up Redis data...${NC}"
docker run --rm \
    -v "$(basename "$PROJECT_DIR")_redis_data":/data \
    -v "$BACKUP_PATH":/backup \
    alpine:latest \
    tar czf /backup/redis_data.tar.gz -C /data .

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Redis data backup completed${NC}"
else
    echo -e "${RED}❌ Redis data backup failed${NC}"
fi

# Backup configuration files
echo -e "${BLUE}⚙️ Backing up configuration files...${NC}"
cp -r "$PROJECT_DIR/config" "$BACKUP_PATH/"
cp -r "$PROJECT_DIR/env" "$BACKUP_PATH/"
cp "$PROJECT_DIR/docker/docker-compose.yml" "$BACKUP_PATH/"

# Create backup metadata
cat > "$BACKUP_PATH/backup_info.txt" << EOF
N8N Backup Information
======================
Backup Date: $(date)
Backup Name: $BACKUP_NAME
N8N Host: $N8N_HOST
Database: $DATABASE_NAME
Database User: $DATABASE_USER

Files Included:
- database.sql (PostgreSQL dump)
- n8n_data.tar.gz (n8n workflows and settings)
- redis_data.tar.gz (Redis cache data)
- config/ (configuration files)
- env/ (environment files)
- docker-compose.yml (Docker Compose configuration)

Restore Instructions:
1. Extract backup files
2. Run restore.sh script
3. Update environment variables if needed
4. Deploy using deploy.sh script
EOF

# Create compressed archive of entire backup
echo -e "${BLUE}🗜️ Creating compressed backup archive...${NC}"
cd "$BACKUP_DIR"
tar czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"

# Remove uncompressed backup directory
rm -rf "$BACKUP_NAME"

# Get backup size
BACKUP_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)

echo -e "${GREEN}🎉 Backup completed successfully!${NC}"
echo -e "${GREEN}📊 Backup Information:${NC}"
echo -e "   📁 Backup file: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"
echo -e "   📏 Backup size: $BACKUP_SIZE"
echo -e "   🕐 Backup time: $(date)"
echo -e ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo -e "   1. Store backup file in a secure location"
echo -e "   2. Test restore process periodically"
echo -e "   3. Consider automated backup scheduling"
echo -e ""
echo -e "${BLUE}🔄 To restore from this backup:${NC}"
echo -e "   ./restore.sh $BACKUP_DIR/${BACKUP_NAME}.tar.gz"

# Cleanup old backups (keep last 5)
echo -e "${BLUE}🧹 Cleaning up old backups...${NC}"
cd "$BACKUP_DIR"
ls -t n8n_backup_*.tar.gz | tail -n +6 | xargs -r rm -f
echo -e "${GREEN}✅ Cleanup completed${NC}"