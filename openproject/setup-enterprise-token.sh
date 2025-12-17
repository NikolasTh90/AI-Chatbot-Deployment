#!/bin/bash

# OpenProject Enterprise Token Setup Script
# This script copies the corrected enterprise_token.rb to the Docker volume

set -e

echo "🔧 Setting up OpenProject Enterprise Token..."

# Check if enterprise_token.rb exists
if [ ! -f "enterprise_token.rb" ]; then
    echo "❌ Error: enterprise_token.rb file not found in current directory!"
    exit 1
fi

# Create the app_models volume if it doesn't exist
if ! docker volume inspect app_models >/dev/null 2>&1; then
    echo "📦 Creating app_models volume..."
    docker volume create app_models
fi

# Use a temporary container to copy the file
echo "📋 Copying enterprise_token.rb to Docker volume..."
docker run --rm \
    -v "$(pwd)/enterprise_token.rb:/source/enterprise_token.rb:ro" \
    -v app_models:/target \
    alpine:latest \
    sh -c "cp /source/enterprise_token.rb /target/enterprise_token.rb && chmod 644 /target/enterprise_token.rb"

# Verify the file was copied
echo "✅ Verifying the file was copied correctly..."
docker run --rm \
    -v app_models:/target \
    alpine:latest \
    sh -c "ls -la /target/enterprise_token.rb && echo '--- File content preview ---' && head -20 /target/enterprise_token.rb"

echo "🎉 Enterprise token setup completed successfully!"
echo ""
echo "The corrected enterprise_token.rb has been copied to the Docker volume."
echo "You can now start OpenProject with: docker compose up -d"