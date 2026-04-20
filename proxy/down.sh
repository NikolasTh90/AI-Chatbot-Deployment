#!/usr/bin/env bash
# down.sh — Stop the reverse-proxy + container-management stack.
#
# Stops in reverse-dependency order:
#   1. Portainer + Agent   (so they release the proxy network cleanly).
#   2. Nginx Proxy Manager (last — nothing else should be using 80/443).
#
# NOTE: Volumes are *not* removed. Portainer data (./portainer/data) and
# NPM data (./nginx-proxy-manager/data, ./letsencrypt) are preserved so
# the next `up.sh` resumes with the same users, certs, and proxy hosts.
# To wipe state, pass --volumes (forwarded to `docker compose down -v`).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NPM_DIR="${SCRIPT_DIR}/nginx-proxy-manager"
PORTAINER_DIR="${SCRIPT_DIR}/portainer"

# Pass-through flag: `./down.sh --volumes` also removes named volumes.
# Useful for a clean reset; destructive, hence opt-in only.
COMPOSE_DOWN_ARGS=()
if [[ "${1:-}" == "--volumes" ]]; then
    COMPOSE_DOWN_ARGS+=("-v")
fi

log()  { printf '\033[0;34m[%s]\033[0m %s\n' "$(date '+%H:%M:%S')" "$*"; }
ok()   { printf '\033[0;32m[ OK ]\033[0m %s\n' "$*"; }
fail() { printf '\033[0;31m[FAIL]\033[0m %s\n' "$*" >&2; }

command -v docker >/dev/null 2>&1 || { fail "docker not found in PATH"; exit 1; }

# Stop Portainer first. If we stopped NPM first, Portainer would still be
# running and listening on the host ports, which is harmless but noisy.
log "Stopping Portainer BE + Agent..."
docker compose --project-directory "${PORTAINER_DIR}" down "${COMPOSE_DOWN_ARGS[@]}"
ok "Portainer stack stopped"

log "Stopping Nginx Proxy Manager..."
docker compose --project-directory "${NPM_DIR}" down "${COMPOSE_DOWN_ARGS[@]}"
ok "NPM stopped"

# We deliberately do NOT remove the "proxy" network here. Other stacks
# (openproject, databases, etc.) may attach to it, and re-creating it on
# each cycle would force them to restart too. Remove it manually with
# `docker network rm proxy` if you truly want a clean slate.
echo
ok "Stack is down."
