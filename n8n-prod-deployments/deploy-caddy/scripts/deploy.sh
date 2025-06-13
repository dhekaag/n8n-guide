#!/bin/bash

# N8N Production Deployment Script with Caddy
# Author: Generated for n8n-guide project

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

echo -e "${GREEN}🚀 Starting N8N Production Deployment with Caddy...${NC}"

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker daemon is not running${NC}"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    exit 1
fi

# Use docker-compose or docker compose based on availability
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

# Check if required files exist
if [[ ! -f "$ENV_FILE" ]]; then
    echo -e "${RED}❌ Environment file not found: $ENV_FILE${NC}"
    echo -e "${YELLOW}Please copy .env.example to .env.production and configure it${NC}"
    exit 1
fi

if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo -e "${RED}❌ Docker Compose file not found: $COMPOSE_FILE${NC}"
    exit 1
fi

# Load environment variables
source "$ENV_FILE"

# Validate required environment variables
required_vars=("N8N_HOST" "DATABASE_PASSWORD" "N8N_BASIC_AUTH_PASSWORD" "REDIS_PASSWORD")
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo -e "${RED}❌ Required environment variable $var is not set${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ Environment validation passed${NC}"

# Create required directories
echo -e "${BLUE}📁 Creating required directories...${NC}"
mkdir -p "$PROJECT_DIR/data"
mkdir -p "$PROJECT_DIR/ssl"
mkdir -p "$PROJECT_DIR/config/caddy"

# Set proper permissions
chmod 755 "$PROJECT_DIR/data"
chmod 755 "$PROJECT_DIR/config"

# Update Caddyfile with actual domain
echo -e "${BLUE}🔧 Updating Caddy configuration...${NC}"
CADDYFILE="$PROJECT_DIR/config/caddy/Caddyfile"
if [[ -f "$CADDYFILE" ]]; then
    # Create backup
    cp "$CADDYFILE" "$CADDYFILE.bak"
    # Replace domain
    sed -i.tmp "s/your-domain.com/$N8N_HOST/g" "$CADDYFILE"
    rm "$CADDYFILE.tmp" 2>/dev/null || true
    echo -e "${GREEN}✅ Caddyfile updated with domain: $N8N_HOST${NC}"
fi

# Pull latest images
echo -e "${BLUE}📥 Pulling latest Docker images...${NC}"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull

# Stop existing containers if running
echo -e "${YELLOW}🛑 Stopping existing containers...${NC}"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down

# Build custom images if needed
echo -e "${BLUE}🏗️ Building custom images...${NC}"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" build

# Start services
echo -e "${GREEN}🚀 Starting services...${NC}"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

# Function to check if service is healthy
check_service_health() {
    local service=$1
    local max_attempts=30
    local attempt=1
    
    echo -e "${BLUE}⏳ Waiting for $service to be healthy...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if $DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps | grep -q "$service.*healthy"; then
            echo -e "${GREEN}✅ $service is healthy${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}Attempt $attempt/$max_attempts: $service not ready yet...${NC}"
        sleep 10
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ $service failed to become healthy${NC}"
    return 1
}

# Wait for services to be healthy
echo -e "${BLUE}🔍 Checking service health...${NC}"
check_service_health "postgres" || exit 1
check_service_health "redis" || exit 1
check_service_health "n8n" || exit 1
check_service_health "caddy" || exit 1

# Check service status
echo -e "${BLUE}📊 Service status:${NC}"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps

# Run basic connectivity tests
echo -e "${BLUE}🧪 Running connectivity tests...${NC}"

# Test internal connectivity
if docker exec n8n-postgres pg_isready -U "$DATABASE_USER" -d "$DATABASE_NAME" &>/dev/null; then
    echo -e "${GREEN}✅ Database connectivity test passed${NC}"
else
    echo -e "${RED}❌ Database connectivity test failed${NC}"
fi

if docker exec n8n-redis redis-cli -a "$REDIS_PASSWORD" ping | grep -q "PONG"; then
    echo -e "${GREEN}✅ Redis connectivity test passed${NC}"
else
    echo -e "${RED}❌ Redis connectivity test failed${NC}"
fi

# Display connection information
echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${GREEN}📝 Connection Information:${NC}"
echo -e "   🌐 URL: https://$N8N_HOST"
echo -e "   👤 Username: $N8N_BASIC_AUTH_USER"
echo -e "   🔑 Password: [Check your .env.production file]"
echo -e ""
echo -e "${YELLOW}📋 Important Notes:${NC}"
echo -e "   1. ✅ Make sure your domain $N8N_HOST points to this server"
echo -e "   2. ✅ Caddy will automatically obtain SSL certificates from Let's Encrypt"
echo -e "   3. ✅ Monitor logs: $DOCKER_COMPOSE -f $COMPOSE_FILE logs -f"
echo -e "   4. ✅ Create backups regularly using backup.sh script"
echo -e "   5. ✅ Update your domain in the Caddyfile if needed"
echo -e ""
echo -e "${GREEN}🔧 Useful Commands:${NC}"
echo -e "   • View logs: $DOCKER_COMPOSE -f $COMPOSE_FILE logs -f"
echo -e "   • View specific service logs: $DOCKER_COMPOSE -f $COMPOSE_FILE logs -f [service]"
echo -e "   • Restart: $DOCKER_COMPOSE -f $COMPOSE_FILE restart"
echo -e "   • Stop: $DOCKER_COMPOSE -f $COMPOSE_FILE down"
echo -e "   • Update: ./deploy.sh"
echo -e "   • Backup: ./backup.sh"
echo -e "   • Service status: $DOCKER_COMPOSE -f $COMPOSE_FILE ps"
echo -e ""
echo -e "${BLUE}🔍 Troubleshooting:${NC}"
echo -e "   • If SSL fails, check DNS propagation: dig $N8N_HOST"
echo -e "   • Check Caddy logs: docker logs n8n-caddy"
echo -e "   • Check n8n logs: docker logs n8n"
echo -e "   • Verify ports 80 and 443 are open"