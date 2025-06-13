FROM n8n/n8n:latest

# Set environment variables
ENV DB_TYPE=postgresdb
ENV DB_POSTGRESDB_HOST=db
ENV DB_POSTGRESDB_PORT=5432
ENV DB_POSTGRESDB_DATABASE=n8n
ENV DB_POSTGRESDB_USER=n8n
ENV DB_POSTGRESDB_PASSWORD=n8n_password
ENV N8N_BASIC_AUTH_ACTIVE=true
ENV N8N_BASIC_AUTH_USER=admin
ENV N8N_BASIC_AUTH_PASSWORD=admin_password
ENV N8N_HOST=n8n
ENV N8N_PORT=5678
ENV N8N_PROTOCOL=http
ENV N8N_PUBLIC_API=true
ENV N8N_EDITOR_BASE_URL=http://localhost:5678
ENV NODE_ENV=production

# Install any additional dependencies if needed
# RUN npm install <additional-dependencies>

# Expose the port
EXPOSE 5678

# Start n8n
CMD ["n8n", "start"]