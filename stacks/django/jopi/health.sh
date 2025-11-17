#!/bin/bash
# Health check script for Django Jopi application
# Returns 0 if healthy, 1 if unhealthy

# Health check endpoint
HEALTH_URL="http://localhost:8000/health/"
TIMEOUT=10

# Check if Django process is running
if ! pgrep -f "gunicorn" > /dev/null; then
    echo "ERROR: Gunicorn process not running"
    exit 1
fi

# Check HTTP health endpoint
if curl -f --max-time "$TIMEOUT" "$HEALTH_URL" > /dev/null 2>&1; then
    echo "SUCCESS: Health check passed"
    exit 0
else
    echo "ERROR: Health check failed"
    exit 1
fi