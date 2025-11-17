# Complete Migration Architecture Guide
## Ubuntu 24.04 + Docker + Portainer for Full AWS → Hetzner Migration

## 📁 Proposed Directory Structure

```
AI-Chatbot-Deployment/
├── README.md                           # Main documentation
├── setup.sh                           # Master setup script (✅ EXISTS)
├── migration-setup.sh                 # NEW: Migration-specific setup
├── quick-migrate.sh                   # NEW: One-command migration
│
├── scripts/                           # ✅ EXISTS (Enhanced)
│   ├── setup-system-packages.sh       # ✅ EXISTS
│   ├── setup-docker.sh                # ✅ EXISTS
│   ├── setup-nvidia.sh                # ✅ EXISTS
│   ├── setup-portainer.sh             # ✅ EXISTS
│   ├── setup-databases.sh             # NEW: Database setup
│   ├── setup-django-apps.sh           # NEW: Django apps deployment
│   ├── setup-wordpress.sh             # NEW: WordPress setup
│   ├── setup-backups.sh               # NEW: Backup automation
│   ├── migrate-databases.sh           # NEW: Database migration
│   └── verify-migration.sh            # NEW: Post-migration verification
│
├── portainer/                         # ✅ EXISTS (No changes needed)
│   ├── docker-compose.yml
│   ├── setup-portainer.sh
│   └── README.md
│
├── proxy/                             # ✅ EXISTS (Enhanced)
│   ├── nginx-proxy-manager/
│   │   └── docker-compose.yml         # ✅ EXISTS
│   └── cloudflare-config/             # NEW: Cloudflare setup
│       ├── cloudflare-tunnel.yml
│       └── setup-tunnel.sh
│
├── stacks/                            # ✅ EXISTS (Enhanced)
│   ├── ai/
│   │   └── docker-compose.yml         # ✅ EXISTS
│   ├── infrastructure/
│   │   └── docker-compose.yml         # ✅ EXISTS
│   ├── databases/                     # NEW
│   │   ├── docker-compose.yml
│   │   ├── init-scripts/
│   │   └ backups/
│   ├── django/                        # NEW
│   │   ├── docker-compose.yml
│   │   ├── jopi/
│   │   │   ├── Dockerfile
│   │   │   └── requirements.txt
│   │   └── synergas/
│   │       ├── Dockerfile
│   │       └── requirements.txt
│   ├── wordpress/                     # NEW
│   │   ├── docker-compose.yml
│   │   ├── multisite/
│   │   ├── single1/
│   │   └── single2/
│   ├── openproject/                   # NEW
│   │   └── docker-compose.yml
│   └── backup/                        # NEW
│       ├── docker-compose.yml
│       └── scripts/
│
├── migration/                         # NEW: Migration tools
│   ├── pre-migration-checks.sh        # AWS readiness validation
│   ├── export-data.sh                 # Data export from AWS
│   ├── import-data.sh                 # Data import to Hetzner
│   ├── dns-cutover.sh                 # Automated DNS management
│   └── rollback.sh                    # Emergency rollback procedures
│
├── monitoring/                        # NEW: Enhanced monitoring
│   ├── docker-compose.yml             # Grafana + Prometheus
│   ├── dashboards/
│   └── alerts/
│
└── docs/                              # Enhanced documentation
    ├── migration-checklist.md
    ├── troubleshooting.md
    ├── performance-tuning.md
    └── security-hardening.md
```

## 🚀 New Scripts Overview

### 1. Migration Master Script (`migration-setup.sh`)
```bash
#!/bin/bash
# Complete migration automation
# Uses existing setup.sh + NEW migration components

# Phases:
# 1. Pre-migration validation
# 2. Base infrastructure setup (uses existing setup.sh)
# 3. Database stack deployment
# 4. Application containers deployment
# 5. Data migration
# 6. DNS cutover
# 7. Post-migration verification
```

### 2. Database Setup (`scripts/setup-databases.sh`)
```bash
#!/bin/bash
# Deploys PostgreSQL + MySQL using existing Docker setup
# Creates databases for jopi, synergas, WordPress sites
# Sets up users and permissions
# Configures backup schedules
```

### 3. Django Apps Deployment (`scripts/setup-django-apps.sh`)
```bash
#!/bin/bash
# Builds and deploys Django containers
# Configures environment variables
# Sets up GitHub Actions CI/CD integration
# Configures Portainer GitOps
```

### 4. WordPress Setup (`scripts/setup-wordpress.sh`)
```bash
#!/bin/bash
# Deploys WordPress containers
# Configures multisite and single sites
# Sets up volume mounts and permissions
# Installs migration plugins
```

### 5. Migration Utilities (`migration/`)
```bash
# pre-migration-checks.sh    - Validate AWS environment
# export-data.sh             - Export databases and files
# import-data.sh             - Import to Hetzner environment
# dns-cutover.sh             - Manage DNS migration
# rollback.sh                - Emergency procedures
```

## 🔧 Required New Stack Files

### 1. Database Stack (`stacks/databases/docker-compose.yml`)
- PostgreSQL 15 for Django apps
- MySQL 8.0 for WordPress sites
- Persistent volumes and backup automation
- Network isolation with `db_net`

### 2. Django Stack (`stacks/django/docker-compose.yml`)
- jopi and synergas containers
- Environment variable management
- GitHub Actions integration
- Health checks and monitoring

### 3. WordPress Stack (`stacks/wordpress/docker-compose.yml`)
- Multisite configuration
- Single site configurations
- Volume mounts for plugins/themes
- Database connectivity

### 4. Backup Stack (`stacks/backup/docker-compose.yml`)
- Automated database backups
- File system backups
- Offsite backup integration
- Retention policies

## 📋 Migration Execution Flow

### Phase 1: Preparation (AWS - Current Environment)
```bash
# 1. Run pre-migration checks
./migration/pre-migration-checks.sh

# 2. Export all data
./migration/export-data.sh

# 3. Create migration package
tar -czf migration-package-$(date +%Y%m%d).tar.gz \
    migration/data/ \
    stacks/django/ \
    stacks/wordpress/
```

### Phase 2: Hetzner Setup (New Environment)
```bash
# 1. Base setup (uses existing scripts)
./setup.sh --nvidia

# 2. Migration-specific setup
./migration-setup.sh --full

# 3. Data import
./migration/import-data.sh

# 4. Verification
./migration/verify-migration.sh
```

### Phase 3: DNS Cutover
```bash
# 1. Reduce TTL values
./migration/dns-cutover.sh --prepare

# 2. Execute cutover
./migration/dns-cutover.sh --execute

# 3. Verify services
./migration/verify-migration.sh --post-cutover
```

## 🎯 Integration with Existing Components

### Leverages Existing Infrastructure:
- ✅ `setup.sh` - Base Ubuntu and Docker setup
- ✅ `portainer/` - Container management platform
- ✅ `proxy/nginx-proxy-manager/` - Reverse proxy
- ✅ `stacks/ai/` - AI services (OpenWebUI, Ollama)
- ✅ `scripts/setup-docker.sh` - Docker installation
- ✅ `scripts/setup-nvidia.sh` - GPU support
- ✅ All system utilities and monitoring tools

### New Components Add:
- Database stack (PostgreSQL + MySQL)
- Django application containers
- WordPress multisite/single sites
- OpenProject deployment
- Backup automation
- Migration utilities and verification

## 🚀 One-Command Migration Option

```bash
# Complete migration in single command (after data export)
./quick-migrate.sh --from-aws --to-hetzner --verify
```

This script orchestrates:
1. Hetzner server setup
2. All stack deployments
3. Data migration
4. DNS cutover
5. Post-migration verification
6. AWS decommission (optional)

## 🔒 Security & Monitoring Enhancements

### Security:
- Cloudflare tunnel setup for secure access
- Firewall rules using Hetzner API
- SSL certificate automation via Nginx Proxy Manager
- Container security scanning

### Monitoring:
- Enhanced monitoring stack (Prometheus + Grafana)
- Performance baselining before migration
- Real-time migration progress tracking
- Automated health checks

This architecture provides a complete, production-ready migration solution that builds upon your excellent existing infrastructure while adding the missing components for full AWS → Hetzner migration.