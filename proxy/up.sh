#!/usr/bin/env bash
# up.sh — Start the reverse-proxy + container-management stack.
#
# Brings up, in order:
#   1. The shared "proxy" Docker network (created if missing).
#   2. Nginx Proxy Manager (NPM)  — owns ports 80/443 and admin UI on 81.
#   3. Portainer BE + Portainer Agent — UI on 9000/9443, agent internal-only.
#
# Order matters: NPM comes up first so it claims 80/443, and the agent
# starts before Portainer because Portainer's compose depends_on it.

set -euo pipefail

# Resolve the directory this script lives in so paths work no matter
# where it's invoked from (cron, systemd, another shell, etc.).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NETWORK_NAME="proxy"
NPM_DIR="${SCRIPT_DIR}/nginx-proxy-manager"
PORTAINER_DIR="${SCRIPT_DIR}/portainer"

log()  { printf '\033[0;34m[%s]\033[0m %s\n' "$(date '+%H:%M:%S')" "$*"; }
ok()   { printf '\033[0;32m[ OK ]\033[0m %s\n' "$*"; }
fail() { printf '\033[0;31m[FAIL]\033[0m %s\n' "$*" >&2; }

# Fail fast if the Docker CLI or the compose plugin is missing — the rest
# of the script is meaningless without them.
command -v docker >/dev/null 2>&1 || { fail "docker not found in PATH"; exit 1; }
docker compose version >/dev/null 2>&1 || { fail "'docker compose' plugin not available"; exit 1; }

# The "proxy" network is declared as external: true in both compose files,
# so it must exist before either stack starts. Create it if missing.
if ! docker network inspect "${NETWORK_NAME}" >/dev/null 2>&1; then
    log "Creating docker network '${NETWORK_NAME}'..."
    docker network create "${NETWORK_NAME}" >/dev/null
    ok "Network '${NETWORK_NAME}' created"
else
    ok "Network '${NETWORK_NAME}' already exists"
fi

# Start NPM first. It binds the host's 80/443/81 ports, so if anything
# else on the host is grabbing those, this is where we'll learn about it.
log "Starting Nginx Proxy Manager..."
docker compose --project-directory "${NPM_DIR}" up -d
ok "NPM started"

# Start Portainer stack (server + agent). The compose file sets
# depends_on so the agent container is created before the server.
log "Starting Portainer BE + Agent..."
docker compose --project-directory "${PORTAINER_DIR}" up -d
ok "Portainer stack started"

# Final status summary so the operator can see everything at a glance.
echo
log "Current container status:"
docker ps --filter "name=nginx-proxy-manager" --filter "name=portainer" \
    --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

echo
ok "Stack is up."
echo "  NPM admin UI : http://\$HOST:81   (default: admin@example.com / changeme)"
echo "  Portainer    : https://\$HOST:9443"
echo "  Agent        : internal only (portainer-agent:9001 on '${NETWORK_NAME}' network)"
