#!/bin/bash

# Test script to validate project structure

set -e

echo "🧪 Testing Project Structure..."

# Test script executability
echo "✓ Checking script permissions..."
find scripts/ -name "*.sh" -exec test -x {} \; || echo "❌ Some scripts not executable"
test -x portainer/setup-portainer.sh || echo "❌ Portainer setup script not executable"

# Test file existence
echo "✓ Checking required files..."
test -f README.md || echo "❌ Main README missing"
test -f portainer/README.md || echo "❌ Portainer README missing"
test -f portainer/docker-compose.yml || echo "❌ Portainer compose file missing"
test -f scripts/setup-datacenter.sh || echo "❌ Main setup script missing"

# Test Docker Compose syntax
echo "✓ Validating Docker Compose file..."
cd portainer
docker compose config > /dev/null 2>&1 && echo "✓ Docker Compose file is valid" || echo "❌ Docker Compose file has syntax errors"
cd ..

echo "✅ Structure validation completed!"