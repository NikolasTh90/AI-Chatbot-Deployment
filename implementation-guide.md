# Complete Implementation Guide
## AWS → Hetzner Migration with Your Existing Infrastructure

## 🎯 Quick Start Summary

**Your Migration Status: 80% Complete** ✅
- You already have enterprise-grade Docker + Portainer automation
- AI stack is production-ready with GPU support
- Only need 4 missing stack files and Django Dockerfiles
- Total additional work: ~8-16 hours

## 🚀 Implementation Options

### **Option 1: Fast Track (1 Week)**
> Recommended: Use existing automation + create minimal missing components

```bash
Day 1-2: Create missing Docker files (4 hours)
Day 3-4: Test on staging Hetzner server (6 hours)  
Day 5-6: Execute migration (4 hours)
Day 7: Final verification and optimization (2 hours)
```

### **Option 2: Comprehensive (2 Weeks)**
> Includes enhanced monitoring, backup strategies, and security hardening

```bash
Week 1: Complete development and testing
Week 2: Production migration with full validation
```

### **Option 3: Phased (4 Weeks)**
> Gradual migration with extended parallel operation

## 📋 Step-by-Step Implementation

### **Phase 1: Create Missing Components (Day 1-2)**

#### **1.1 Create Database Stack**
```bash
# Create directory
mkdir -p stacks/databases/{init-scripts,backups}

# Create docker-compose.yml
cat > stacks/databases/docker-compose.yml << 'EOF'
version: "3.8"

services:
  postgres:
    image: postgres:15
    container_name: postgres-main
    environment:
      POSTGRES_USER: django
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: default_db
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
      - ./backups:/backups
    networks:
      - db_net
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U django"]
      interval: 30s
      timeout: 10s
      retries: 3

  mysql:
    image: mysql:8.0
    container_name: mysql-main
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - mysql_data:/var/lib/mysql
      - ./init-scripts:/docker-entrypoint-initdb.d
      - ./backups:/backups
    networks:
      - db_net
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
  mysql_data:

networks:
  db_net:
    external: true
EOF
```

#### **1.2 Create Database Init Scripts**
```bash
# PostgreSQL initialization
cat > stacks/databases/init-scripts/01-create-databases.sql << 'EOF'
CREATE DATABASE jopi_db;
CREATE DATABASE synergas_db;
EOF

# MySQL initialization  
cat > stacks/databases/init-scripts/02-create-databases.sql << 'EOF'
CREATE DATABASE wp_multisite CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE wp_single1 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE wp_single2 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOF
```

#### **1.3 Create Django Stack**
```bash
mkdir -p stacks/django/{jopi,synergas}

# Main docker-compose.yml
cat > stacks/django/docker-compose.yml << 'EOF'
version: "3.8"

services:
  jopi:
    image: ${DOCKER_REGISTRY}/jopi:latest
    container_name: jopi_app
    env_file:
      - .env.jopi
    networks:
      - proxy
      - db_net
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health/"]
      interval: 30s
      timeout: 10s
      retries: 3

  synergas:
    image: ${DOCKER_REGISTRY}/synergas:latest
    container_name: synergas_app
    env_file:
      - .env.synergas
    networks:
      - proxy
      - db_net
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health/"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  proxy:
    external: true
  db_net:
    external: true
EOF
```

#### **1.4 Create Dockerfiles for Django Apps**
```bash
# Jopi Dockerfile
cat > stacks/django/jopi/Dockerfile << 'EOF'
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Install gunicorn
RUN pip install gunicorn

# Create non-root user
RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app
USER app

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health/ || exit 1

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "config.wsgi:application"]
EOF

# Jopi requirements.txt template
cat > stacks/django/jopi/requirements.txt << 'EOF'
Django>=4.2,<5.0
psycopg2-binary
gunicorn
whitenoise
django-environ
Wagtail>=5.0
# Add your project-specific dependencies here
EOF
```

#### **1.5 Create WordPress Stack**
```bash
mkdir -p stacks/wordpress/{multisite,single1,single2}

cat > stacks/wordpress/docker-compose.yml << 'EOF'
version: "3.8"

services:
  wp_multisite:
    image: wordpress:php8.2-apache
    container_name: wp_multisite
    environment:
      WORDPRESS_DB_HOST: mysql-main
      WORDPRESS_DB_USER: wp_multi_user
      WORDPRESS_DB_PASSWORD: ${WP_MULTI_PASSWORD}
      WORDPRESS_DB_NAME: wp_multisite
      WORDPRESS_TABLE_PREFIX: wp_multi_
    volumes:
      - ./multisite/html:/var/www/html
      - ./multisite/plugins:/var/www/html/wp-content/plugins
    networks:
      - proxy
      - db_net
    restart: unless-stopped

  wp_single1:
    image: wordpress:php8.2-apache
    container_name: wp_single1
    environment:
      WORDPRESS_DB_HOST: mysql-main
      WORDPRESS_DB_USER: wp_single1_user
      WORDPRESS_DB_PASSWORD: ${WP_SINGLE1_PASSWORD}
      WORDPRESS_DB_NAME: wp_single1
    volumes:
      - ./single1/html:/var/www/html
    networks:
      - proxy
      - db_net
    restart: unless-stopped

  wp_single2:
    image: wordpress:php8.2-apache
    container_name: wp_single2
    environment:
      WORDPRESS_DB_HOST: mysql-main
      WORDPRESS_DB_USER: wp_single2_user
      WORDPRESS_DB_PASSWORD: ${WP_SINGLE2_PASSWORD}
      WORDPRESS_DB_NAME: wp_single2
    volumes:
      - ./single2/html:/var/www/html
    networks:
      - proxy
      - db_net
    restart: unless-stopped

networks:
  proxy:
    external: true
  db_net:
    external: true
EOF
```

#### **1.6 Create Setup Scripts**
```bash
# Database setup script
cat > scripts/setup-databases.sh << 'EOF'
#!/bin/bash
set -e

source "$(dirname "$0")/../scripts/utils.sh"

log "Setting up database stack..."

# Create network if not exists
docker network create db_net 2>/dev/null || true

# Deploy databases
cd "$(dirname "$0")/../stacks/databases"
docker-compose up -d

# Wait for databases to be ready
log "Waiting for databases to start..."
sleep 30

# Create users
docker exec -it postgres-main psql -U django -c "CREATE USER wp_multi_user WITH PASSWORD 'WP_MULTI_PASSWORD';"
docker exec -it postgres-main psql -U django -c "CREATE USER wp_single1_user WITH PASSWORD 'WP_SINGLE1_PASSWORD';"
docker exec -it postgres-main psql -U django -c "CREATE USER wp_single2_user WITH PASSWORD 'WP_SINGLE2_PASSWORD';"

success "Database stack deployed successfully"
EOF

# Django setup script
cat > scripts/setup-django-apps.sh << 'EOF'
#!/bin/bash
set -e

source "$(dirname "$0")/../scripts/utils.sh"

log "Setting up Django applications..."

# Create .env files from templates
cp "$(dirname "$0")/../stacks/django/.env.jopi.template" "$(dirname "$0")/../stacks/django/.env.jopi"
cp "$(dirname "$0")/../stacks/django/.env.synergas.template" "$(dirname "$0")/../stacks/django/.env.synergas"

# Deploy Django apps
cd "$(dirname "$0")/../stacks/django"
docker-compose up -d

success "Django applications deployed successfully"
EOF
```

### **Phase 2: Testing & Validation (Day 3-4)**

#### **2.1 Staging Environment Test**
```bash
# Create cheap Hetzner server for testing (CPX11: €4/month)
hcloud server create --name staging-server --type cpx11 --image ubuntu-24.04

# SSH into staging server
ssh root@STAGING_IP

# Clone and setup
git clone <your-repo> && cd AI-Chatbot-Deployment

# Test base setup (your existing automation)
./setup.sh --nvidia

# Test new stacks
./scripts/setup-databases.sh
./scripts/setup-django-apps.sh
./scripts/setup-wordpress.sh

# Verify everything works
docker ps  # Should show all containers running
./scripts/verify-setup.sh
```

#### **2.2 Migration Testing**
```bash
# Test database migration process
./migration/test-database-migration.sh

# Test Django app functionality
./migration/test-django-apps.sh

# Test WordPress functionality
./migration/test-wordpress-sites.sh

# Performance testing
./migration/performance-test.sh
```

### **Phase 3: Production Migration (Day 5-6)**

#### **3.1 Prepare Production Server**
```bash
# Create production Hetzner server (CPX32: €10/month)
hcloud server create --name prod-server --type cpx32 --image ubuntu-24.04

# SSH into production server
ssh root@PROD_IP

# Clone and setup base infrastructure
git clone <your-repo> && cd AI-Chatbot-Deployment

# Base setup (your existing automation)
./setup.sh --nvidia

# Deploy all stacks
./scripts/setup-databases.sh
docker-compose -f stacks/infrastructure/docker-compose.yml up -d
docker-compose -f stacks/ai/docker-compose.yml up -d
./scripts/setup-django-apps.sh
./scripts/setup-wordpress.sh
```

#### **3.2 Data Migration**
```bash
# Export data from AWS (on old server)
./migration/export-databases.sh
./migration/export-wordpress.sh

# Import to Hetzner (on new server)
./migration/import-databases.sh
./migration/import-wordpress.sh

# Verify data integrity
./migration/verify-data-migration.sh
```

#### **3.3 DNS Cutover**
```bash
# Prepare DNS (reduce TTL to 5 minutes)
./migration/prepare-dns.sh

# Execute cutover during low traffic
./migration/execute-dns-cutover.sh

# Verify propagation
./migration/verify-dns-propagation.sh
```

### **Phase 4: Post-Migration (Day 7)**

#### **4.1 Final Verification**
```bash
# Comprehensive health check
./migration/final-verification.sh

# Performance validation
./migration/performance-validation.sh

# Security verification
./migration/security-validation.sh
```

#### **4.2 AWS Decommission**
```bash
# Only after 48 hours of stable operation
./migration/decommission-aws.sh
```

## 🔧 Configuration Files Needed

### **Environment Variables Templates**
```bash
# stacks/django/.env.jopi.template
DJANGO_SECRET_KEY=your-secret-key-here
DATABASE_URL=postgres://django:POSTGRES_PASSWORD@postgres-main:5432/jopi_db
ALLOWED_HOSTS=jopi.yourdomain.com,www.jopi.yourdomain.com
DEBUG=False
```

### **GitHub Actions for CI/CD**
```yaml
# .github/workflows/deploy.yml
name: Deploy Django Apps

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build and push Jopi image
        uses: docker/build-push-action@v5
        with:
          context: ./stacks/django/jopi
          push: true
          tags: ${{ secrets.DOCKER_REGISTRY }}/jopi:${{ github.sha }}
          
      - name: Deploy to Portainer
        run: |
          curl -X POST "${{ secrets.PORTAINER_URL }}/api/stacks/webhooks/${{ secrets.PORTAINER_WEBHOOK }}"
```

## 🚨 Critical Success Factors

### **Must-Have Before Starting:**
1. ✅ Complete AWS backup (databases + files)
2. ✅ DNS access (Cloudflare or domain registrar)
3. ✅ Hetzner account + API token
4. ✅ Docker Hub or container registry access
5. ✅ SSL certificates ready (or use Let's Encrypt)

### **During Migration:**
1. ✅ Keep AWS running until DNS cutover complete
2. ✅ Monitor error rates continuously
3. ✅ Have rollback plan ready
4. ✅ Test all functionality before decommissioning AWS

### **After Migration:**
1. ✅ Monitor performance for 48 hours
2. ✅ Verify backup systems working
3. ✅ Update all documentation
4. ✅ Cancel AWS subscriptions

## 💰 Cost Breakdown

### **Migration Costs:**
- Hetzner staging server (CPX11): €4 for 1 week
- Hetzner production server (CPX32): €10 per month
- Container registry: €5 per month (if needed)
- **First month total**: ~€20-25

### **Ongoing Monthly Costs:**
- Server: €10-18 (depending on final size)
- Storage/backups: €2-5
- Data transfer: €1-3
- **Total**: €13-26/month = $15-30/month

### **Savings:**
- From $150-200/month (AWS) → $15-30/month (Hetzner)
- **Savings**: $120-180/month ($1,440-2,160/year)

## 🎯 Immediate Next Steps

1. **Create missing stack files** (2-4 hours)
2. **Dockerize Django apps** (4-6 hours) 
3. **Test on staging server** (6-8 hours)
4. **Execute production migration** (4-6 hours)

**Total time investment: 16-24 hours over 1-2 weeks**

Your existing automation does most of the heavy lifting - you just need to create the application-specific components and execute the migration plan.