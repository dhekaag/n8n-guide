FROM n8nio/n8n:latest

# Install additional dependencies if needed
USER root
RUN apk add --no-cache \
    curl \
    wget \
    jq

# Switch back to n8n user
USER node

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5678/healthz || exit 1

# Expose port
EXPOSE 5678

# Default command
CMD ["n8n", "start"]