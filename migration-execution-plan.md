# Complete Migration Execution Plan
## AWS EC2 → Hetzner Cloud with Docker + Portainer

## 🎯 Executive Summary

**Migration Timeline**: 2 weeks  
**Cost Savings**: $120-180/month ($1,440-2,160/year)  
**Risk Level**: Medium (Mitigated by existing automation)  
**Downtime**: < 30 minutes (DNS cutover only)

## 📅 Detailed Execution Timeline

### **Week 1: Preparation & Development**

#### **Day 1: Environment Analysis & Backup**
```bash
# AWS: Analyze current resource usage
./scripts/verify-setup.sh > aws-baseline-report.txt

# Export all databases and configurations
./migration/pre-migration-checks.sh
./migration/export-data.sh

# Create complete backup
aws s3 sync /var/www/html s3://migration-backup/html-$(date +%Y%m%d)
pg_dumpall > aws-databases-backup-$(date +%Y%m%d).sql
```

**Deliverables:**
- Resource usage baseline report
- Complete data export package
- Migration inventory document

#### **Day 2-3: Create Missing Infrastructure Components**

**Create New Stacks:**
```bash
# Directory structure
mkdir -p stacks/{databases,django,wordpress,openproject,backup}
mkdir -p stacks/django/{jopi,synergas}
mkdir -p stacks/wordpress/{multisite,single1,single2}
mkdir -p migration/{data,scripts}
mkdir -p monitoring/{dashboards,alerts}
```

**Create Database Stack:**
```bash
# File: stacks/databases/docker-compose.yml
# Content: PostgreSQL + MySQL with backup automation
# Networks: db_net (isolated), proxy (for management)
# Volumes: Persistent data with automated backups
```

**Create Django Application Stack:**
```bash
# File: stacks/django/docker-compose.yml
# Content: jopi + synergas with CI/CD integration
# Features: Health checks, auto-restart, monitoring
# Integration: GitHub Actions + Portainer GitOps
```

**Create WordPress Stack:**
```bash
# File: stacks/wordpress/docker-compose.yml
# Content: Multisite + 2 single sites
# Features: Volume mounts, plugin pre-installation
# Integration: Migration plugins ready
```

#### **Day 4-5: Dockerize Django Applications**

**For Each Django App (jopi & synergas):**
```dockerfile
# Dockerfile template
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "config.wsgi:application"]
```

**GitHub Actions Integration:**
```yaml
# .github/workflows/deploy.yml
# Features: Auto-build, push to registry, trigger Portainer
# Environments: staging → production
# Rollback: Automatic on failure
```

#### **Day 6-7: Testing & Validation**

**Staging Environment Setup:**
```bash
# Deploy to test Hetzner server
./migration-setup.sh --staging --test-data

# Validate all components
./scripts/verify-setup.sh
./migration/test-django-apps.sh
./migration/test-wordpress-sites.sh
```

**Performance Testing:**
```bash
# Load testing Django apps
autocannon -c 10 -d 30s http://staging-server/api/

# Database performance testing
pgbench -h localhost -U django -d jopi_db -c 5 -j 2 -t 1000
```

### **Week 2: Production Migration**

#### **Day 8: Hetzner Production Setup**

**Server Provisioning:**
```bash
# Create Hetzner CPX32 server via API/API
curl -X POST https://api.hetzner.cloud/v1/servers \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"name":"prod-server","server_type":"cpx32","image":"ubuntu-24.04"}'

# SSH into new server
ssh root@NEW_HETZNER_IP
```

**Base Infrastructure Deployment:**
```bash
# Clone repository and setup base
git clone <your-repo> && cd AI-Chatbot-Deployment

# One-command base setup (leverages existing scripts)
./setup.sh --nvidia  # ✅ Uses your existing automation

# Deploy monitoring stack
docker-compose -f monitoring/docker-compose.yml up -d
```

**Core Services Deployment:**
```bash
# Deploy databases
./scripts/setup-databases.sh

# Deploy proxy and infrastructure
docker-compose -f stacks/infrastructure/docker-compose.yml up -d

# Deploy AI services (your existing stack)
docker-compose -f stacks/ai/docker-compose.yml up -d

# Verify all services
./scripts/verify-setup.sh
```

#### **Day 9-10: Application Migration**

**Django Applications:**
```bash
# Deploy Django containers
./scripts/setup-django-apps.sh

# Migrate databases
./migration/migrate-databases.sh --from-aws --to-postgres

# Test applications
./migration/verify-django-apps.sh
```

**WordPress Sites:**
```bash
# Deploy WordPress containers
./scripts/setup-wordpress.sh

# Import WordPress sites using All-in-One WP Migration
./migration/import-wordpress.sh

# Verify sites
./migration/verify-wordpress-sites.sh
```

**OpenProject & Additional Services:**
```bash
# Deploy OpenProject
docker-compose -f stacks/openproject/docker-compose.yml up -d

# Configure backup automation
./scripts/setup-backups.sh
```

#### **Day 11: Final Testing & DNS Preparation**

**Comprehensive Testing:**
```bash
# Full stack health check
./migration/comprehensive-test.sh

# Performance validation
./migration/performance-validation.sh

# Security scan
./migration/security-validation.sh
```

**DNS Preparation:**
```bash
# Reduce TTL values
./migration/dns-cutover.sh --prepare --ttl 300

# Prepare Cloudflare configuration
./proxy/cloudflare-config/setup-tunnel.sh --prepare
```

#### **Day 12: GO LIVE - DNS Cutover**

**Execution Timeline (UTC Times):**
```
02:00 - Final backup of AWS environment
02:30 - Begin DNS TTL reduction verification
03:00 - Execute DNS cutover
03:15 - Verify DNS propagation
03:30 - Validate all services on Hetzner
04:00 - Confirm successful migration
04:30 - Begin AWS decommission (optional)
```

**Cutover Commands:**
```bash
# Execute DNS migration
./migration/dns-cutover.sh --execute

# Real-time monitoring
watch -n 30 './migration/verify-cutover-status.sh'

# Automatic rollback if issues detected
./migration/rollback.sh --automatic --threshold 5%_errors
```

#### **Day 13-14: Post-Migration Optimization**

**Performance Tuning:**
```bash
# Monitor resource usage
./migration/monitor-performance.sh --duration 24h

# Optimize based on findings
./migration/optimize-resources.sh

# Update monitoring dashboards
./monitoring/update-dashboards.sh
```

**AWS Decommission:**
```bash
# Only after 48 hours of stable operation
./migration/decommission-aws.sh --verify --backup
```

## 🚨 Critical Decision Points & Triggers

### **Go/No-Go Decision Points**

1. **After Day 7 Testing:**
   - ✅ All staging tests pass: Continue to production
   - ❌ Critical issues found: Fix before proceeding

2. **After Day 11 Final Testing:**
   - ✅ All services operational: Proceed with DNS cutover
   - ❌ Performance issues: Address before cutover

3. **During DNS Cutover (Day 12):**
   - ✅ <5% error rate: Continue migration
   - ❌ >5% error rate: Automatic rollback

### **Rollback Triggers**
```bash
# Automatic rollback conditions
- Error rate > 5% for 5 consecutive minutes
- Database connectivity loss > 2 minutes
- Response time > 5 seconds for 10 minutes
- Any critical service unavailable

# Manual rollback command
./migration/rollback.sh --manual --reason="<issue>"
```

## 📊 Success Metrics & Validation

### **Technical Metrics**
- ✅ All containers running healthy
- ✅ Database migrations successful
- ✅ SSL certificates valid
- ✅ Monitoring alerts functional
- ✅ Backup systems operational

### **Performance Metrics**
- ✅ Response times < 2 seconds
- ✅ Error rate < 1%
- ✅ CPU usage < 80%
- ✅ Memory usage < 85%
- ✅ Disk space < 70%

### **Business Metrics**
- ✅ All websites accessible
- ✅ User login functionality working
- ✅ Data integrity verified
- ✅ Email services functioning
- ✅ Third-party integrations operational

## 🔄 Post-Migration Tasks (First 30 Days)

### **Week 1: Monitoring & Optimization**
- Daily performance reviews
- Security monitoring
- Backup verification
- User feedback collection

### **Week 2: Cost Optimization**
- Right-size server if needed
- Optimize backup schedules
- Review resource allocations
- Update monitoring alerts

### **Week 3: Documentation & Training**
- Update operational documentation
- Train team on new procedures
- Create runbooks for common issues
- Document optimized configurations

### **Week 4: Final Cleanup**
- Remove AWS resources
- Final cost analysis
- Migration retrospective
- Lessons learned documentation

## 🆘 Emergency Procedures

### **Immediate Rollback (<30 minutes)**
```bash
# Automated rollback to AWS
./migration/emergency-rollback.sh --immediate

# DNS reversal
./migration/dns-rollback.sh --force

# Service status broadcast
./migration/notify-stakeholders.sh --rollback
```

### **Partial Service Recovery**
```bash
# Restart specific services
./migration/restart-service.sh --service=<service_name>

# Database recovery
./migration/recover-database.sh --from-backup --timestamp=<timestamp>

# Container recovery
./migration/recover-container.sh --container=<container_name>
```

This execution plan provides a structured, risk-managed approach to migration that leverages your existing automation while ensuring business continuity.