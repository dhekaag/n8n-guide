#!/bin/bash

# Navigate to the directory containing the Docker Compose file
cd "$(dirname "$0")/../docker"

# Build the Docker images
docker-compose build

# Start the services in detached mode
docker-compose up -d

# Wait for the n8n service to be ready
echo "Waiting for n8n to be ready..."
sleep 10

# Check the status of the n8n service
if [ "$(docker-compose ps -q n8n | xargs docker inspect -f '{{.State.Status}}')" != "running" ]; then
  echo "n8n service failed to start."
  exit 1
fi

echo "n8n has been deployed successfully."