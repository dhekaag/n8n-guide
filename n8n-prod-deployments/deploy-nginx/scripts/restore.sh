#!/bin/bash

# Check if a backup file is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <backup-file>"
  exit 1
fi

BACKUP_FILE=$1

# Check if the backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found: $BACKUP_FILE"
  exit 1
fi

# Restore the backup
echo "Restoring n8n data from $BACKUP_FILE..."

# Assuming the backup file is a tar.gz archive
tar -xzf "$BACKUP_FILE" -C /path/to/n8n/data

echo "Restore completed successfully."