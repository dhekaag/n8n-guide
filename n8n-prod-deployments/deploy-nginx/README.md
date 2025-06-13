# n8n Production Deployment

This repository contains the configuration and scripts necessary for deploying n8n in a production environment using Docker.

## Project Structure

- **docker/**: Contains the Dockerfile and docker-compose.yml for building and running the n8n application.
- **config/**: Holds configuration files for n8n and Nginx.
  - **n8n/**: Configuration settings for n8n, including database connection details.
  - **nginx/**: Nginx configuration for reverse proxying n8n.
- **scripts/**: Contains scripts for deployment, backup, and restoration of n8n data.
  - **deploy.sh**: Automates the deployment process.
  - **backup.sh**: Creates backups of n8n data.
  - **restore.sh**: Restores n8n data from a backup.
- **env/**: Contains environment variable files.
  - **.env.production**: Environment variables for the production environment.
  - **.env.example**: Template for required environment variables.
- **ssl/**: Directory for storing SSL certificates.
- **data/**: Directory for storing application data.

## Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd n8n-production-deployment
   ```

2. **Configure Environment Variables**
   - Copy the example environment file:
     ```bash
     cp env/.env.example env/.env.production
     ```
   - Edit `env/.env.production` to include your production-specific settings.

3. **Build and Start the Application**
   - Use Docker Compose to build and start the services:
     ```bash
     docker-compose up -d
     ```

4. **Access n8n**
   - Once the services are running, you can access n8n at `http://<your-domain-or-ip>:5678`.

## Backup and Restore

- To create a backup of your n8n data, run:
  ```bash
  ./scripts/backup.sh
  ```

- To restore from a backup, use:
  ```bash
  ./scripts/restore.sh
  ```

## Contributing

Feel free to submit issues or pull requests for improvements or bug fixes.

## License

This project is licensed under the MIT License.