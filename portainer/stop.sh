#!/bin/bash
cd ./../portainer
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose down
elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose down
else
    docker stop portainer 2>/dev/null || true
    docker rm portainer 2>/dev/null || true
fi
