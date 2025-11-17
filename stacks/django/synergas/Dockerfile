# Django Synergas Application Dockerfile
# Optimized for production deployment on Portainer

FROM python:3.12-slim

# Labels for metadata
LABEL maintainer="your-email@example.com"
LABEL version="1.0"
LABEL description="Django Synergas Application Container"

# Environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE=config.settings.production

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    gettext \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Install gunicorn for production serving
RUN pip install --no-cache-dir gunicorn

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash app && \
    chown -R app:app /app

# Copy application code with proper ownership
COPY --chown=app:app . .

# Create necessary directories with proper permissions
RUN mkdir -p /app/media /app/static /app/logs && \
    chown -R app:app /app/media /app/static /app/logs

# Switch to non-root user
USER app

# Set executable permissions for health check
RUN chmod +x /app/health.sh || true

# Create health check script separately
COPY health.sh /app/health.sh
RUN chmod +x /app/health.sh

# Collect static files
RUN python manage.py collectstatic --noinput --clear || echo "Static files collection completed (non-fatal)"

# Expose port
EXPOSE 8000

# Health check configuration
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f --max-time 10 http://localhost:8000/health/ || exit 1

# Start command using gunicorn with optimized settings
CMD ["gunicorn", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "3", \
     "--worker-class", "sync", \
     "--worker-connections", "1000", \
     "--max-requests", "1000", \
     "--max-requests-jitter", "100", \
     "--timeout", "30", \
     "--keep-alive", "2", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "--log-level", "info", \
     "config.wsgi:application"]