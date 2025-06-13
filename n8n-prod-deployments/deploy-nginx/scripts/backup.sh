#!/bin/bash

# Define backup directory
BACKUP_DIR="/path/to/backup/directory"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/n8n_backup_$TIMESTAMP.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Stop n8n service
docker-compose -f /path/to/docker-compose.yml down

# Create a backup of the n8n data
tar -czf "$BACKUP_FILE" -C /path/to/n8n/data .

# Restart n8n service
docker-compose -f /path/to/docker-compose.yml up -d

echo "Backup created at $BACKUP_FILE"