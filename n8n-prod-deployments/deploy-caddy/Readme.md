# n8n Production Deployment with Caddy

This repository contains the configuration and scripts necessary for deploying n8n in a production environment using Docker and Caddy as reverse proxy.

## Project Structure

- **docker/**: Contains the Dockerfile and docker-compose.yml for building and running the n8n application.
- **config/**: Holds configuration files for n8n and Caddy.
  - **n8n/**: Configuration settings for n8n, including database connection details.
  - **caddy/**: Caddy configuration for reverse proxying n8n with automatic HTTPS.
- **scripts/**: Contains scripts for deployment, backup, and restoration of n8n data.
  - **deploy.sh**: Automates the deployment process.
  - **backup.sh**: Creates backups of n8n data.
  - **restore.sh**: Restores n8n data from a backup.
- **env/**: Contains environment variable files.
  - **.env.production**: Environment variables for the production environment.
  - **.env.example**: Template for required environment variables.
- **ssl/**: Directory for storing SSL certificates (optional with Caddy).
- **data/**: Directory for storing application data.

## Features

- **Automatic HTTPS**: Caddy automatically obtains and renews SSL certificates
- **PostgreSQL Database**: Reliable database backend
- **Redis Cache**: Performance optimization
- **Health Checks**: Monitoring for all services
- **Backup System**: Automated backup and restore scripts
- **Security Headers**: Built-in security configuration
- **Logging**: Structured logging for monitoring

## Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd n8n-prod-deployments/deploy-caddy
   ```

2. **Configure Environment Variables**
   - Copy the example environment file:
     ```bash
     cp env/.env.example env/.env.production
     ```
   - Edit `env/.env.production` to include your production-specific settings.

3. **Update Caddy Configuration**
   - Edit `config/caddy/Caddyfile` and replace `your-domain.com` with your actual domain.

4. **Build and Start the Application**
   - Use Docker Compose to build and start the services:
     ```bash
     chmod +x scripts/deploy.sh
     ./scripts/deploy.sh
     ```

5. **Access n8n**
   - Once the services are running, you can access n8n at `https://your-domain.com`.

## Backup and Restore

- To create a backup of your n8n data, run:
  ```bash
  ./scripts/backup.sh
  ```

- To restore from a backup, use:
  ```bash
  ./scripts/restore.sh
  ```

## Security Considerations

- Change all default passwords in `.env.production`
- Use strong encryption keys
- Regularly update Docker images
- Monitor logs for suspicious activity
- Set up firewall rules

## Monitoring

- Check service status: `docker-compose ps`
- View logs: `docker-compose logs -f`
- Monitor resource usage: `docker stats`

## Troubleshooting

### Common Issues

1. **SSL Certificate Issues**
   - Ensure domain points to your server
   - Check DNS propagation
   - Verify ports 80 and 443 are open

2. **Database Connection Issues**
   - Check PostgreSQL logs: `docker-compose logs postgres`
   - Verify database credentials in `.env.production`

3. **Service Health Checks Failing**
   - Wait for services to fully start (30-60 seconds)
   - Check individual service logs

## Contributing

Feel free to submit issues or pull requests for improvements or bug fixes.

## License

This project is licensed under the MIT License.