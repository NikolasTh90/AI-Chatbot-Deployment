# Guide: Exposing OpenProject to the Internet

This guide will walk you through configuring your nginx proxy manager to expose OpenProject to the internet using your domain `openproject-dev.caonyx.com`.

## Prerequisites

1. ✅ DNS record `openproject-dev.caonyx.com` pointing to your server's IP
2. ✅ OpenProject docker-compose setup running
3. ✅ nginx proxy manager installed and connected to `proxy-network`
4. ✅ SSL certificate (Let's Encrypt recommended)

## Step 1: Verify Network Setup

Ensure your nginx proxy manager is connected to the same `proxy-network` as OpenProject:

```bash
# Check if proxy-network exists
docker network ls | grep proxy-network

# If not, create it
docker network create proxy-network

# Connect your nginx proxy manager to the network
docker network connect proxy-network <nginx-proxy-manager-container-name>
```

## Step 2: Configure OpenProject Environment

Update your `.env` file to match your domain:

```bash
# Edit the .env file
nano .env
```

Add/update these settings:

```env
OPENPROJECT_HTTPS=true
OPENPROJECT_HOST__NAME=openproject-dev.caonyx.com
OPENPROJECT_HSTS=true
OPENPROJECT_RAILS__RELATIVE__URL__ROOT=
```

Restart OpenProject with the new settings:

```bash
docker compose down
docker compose up -d
```

## Step 3: nginx Proxy Manager Configuration

### 3.1 Add SSL Certificate

1. Log into your nginx proxy manager web interface
2. Go to **SSL Certificates** tab
3. Click **Add SSL Certificate**
4. Select **Let's Encrypt** (or use your own certificate)
5. Enter:
   - **Domain Names**: `openproject-dev.caonyx.com`
   - **Email**: Your email address
   - **Agree to Let's Encrypt Terms**: ✅
6. Click **Save**

### 3.2 Create Proxy Host

1. Go to **Hosts** → **Proxy Hosts**
2. Click **Add Proxy Host**
3. Configure the **Details** tab:
   - **Domain Names**: `openproject-dev.caonyx.com`
   - **Scheme**: `http`
   - **Forward Hostname/IP**: `proxy`
   - **Forward Port**: `80`
   - **Block Common Exploits**: ✅
   - **Websockets Support**: ✅

4. Configure the **SSL** tab:
   - **SSL Certificate**: Select the certificate you created
   - **Force SSL**: ✅
   - **HTTP/2 Support**: ✅
   - **HSTS Enabled**: ✅
   - **HSTS Subdomains**: ✅

5. Configure the **Advanced** tab:
   ```nginx
   # increase client body size to handle large attachments
   client_max_body_size 100M;
   
   # proxy headers for proper OpenProject functionality
   proxy_set_header X-Forwarded-Proto $scheme;
   proxy_set_header X-Forwarded-Host $host;
   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
   proxy_set_header X-Real-IP $remote_addr;
   
   # timeout settings
   proxy_connect_timeout 30s;
   proxy_send_timeout 30s;
   proxy_read_timeout 30s;
   ```

6. Click **Save**

## Step 4: Verify Configuration

### 4.1 Check nginx Proxy Manager

1. In nginx proxy manager, check that your proxy host shows as **Running**
2. Verify SSL certificate is issued successfully
3. Check the logs for any errors

### 4.2 Test DNS Resolution

```bash
# Check if your domain resolves correctly
nslookup openproject-dev.caonyx.com
# Should return your server's IP address
```

### 4.3 Test SSL Certificate

```bash
# Test SSL certificate
openssl s_client -connect openproject-dev.caonyx.com:443 -servername openproject-dev.caonyx.com
# Should show certificate details and 'Verify return code: 0 (ok)'
```

### 4.4 Test OpenProject Access

1. Open browser and navigate to: `https://openproject-dev.caonyx.com`
2. You should see the OpenProject login page
3. Default credentials:
   - Username: `admin`
   - Password: `admin`

## Step 5: Security Hardening

### 5.1 Change Default Passwords

1. Log in to OpenProject as admin
2. Go to **My account** → **Change password**
3. Change the default admin password immediately

### 5.2 Firewall Configuration

Ensure only necessary ports are open:

```bash
# Allow HTTP/HTTPS
sudo ufw allow 80
sudo ufw allow 443

# Block direct access to OpenProject ports (if they were exposed)
sudo ufw deny 8080
sudo ufw enable
```

### 5.3 Additional nginx Security Headers

Add these to the **Advanced** tab in nginx proxy manager:

```nginx
# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

# Disable server tokens
server_tokens off;
```

## Step 6: Monitoring and Maintenance

### 6.1 Monitor Logs

Regularly check both nginx proxy manager and OpenProject logs:

```bash
# nginx proxy manager logs
docker logs -f <nginx-proxy-manager-container-name>

# OpenProject logs
docker compose logs -f web
docker compose logs -f proxy
```

### 6.2 Backup Configuration

Regularly backup your OpenProject data and configuration:

```bash
# Backup OpenProject data
docker compose down
docker run --rm -v openproject_pgdata:/data -v $(pwd):/backup alpine tar czf /backup/openproject-backup.tar.gz -C /data .
docker compose up -d
```

### 6.3 SSL Certificate Renewal

Let's Encrypt certificates auto-renew, but monitor the process:

1. Check certificate expiry dates in nginx proxy manager
2. Ensure your server time is correctly synchronized
3. Monitor email for Let's Encrypt notifications

## Troubleshooting

### Common Issues and Solutions

#### Page Not Loading / 502 Bad Gateway
1. Check if OpenProject containers are running: `docker compose ps`
2. Check if nginx proxy manager can reach the `proxy` container: `docker exec -it <nginx-container> curl http://proxy:80`
3. Verify network connectivity: `docker network inspect proxy-network`

#### SSL Certificate Issues
1. Check DNS resolution: `nslookup openproject-dev.caonyx.com`
2. Verify port 80/443 are accessible from the internet
3. Check nginx proxy manager SSL logs for specific error messages

#### Login Issues
1. Try accessing via direct IP to confirm OpenProject is working
2. Check OpenProject logs for authentication errors
3. Verify database connectivity: `docker compose exec db psql -U postgres -d openproject -c "SELECT 1;"`

#### File Upload Issues
1. Ensure `client_max_body_size` is set appropriately in nginx proxy manager
2. Check OpenProject asset configuration and permissions
3. Verify available disk space on the server

### Performance Optimization

For better performance, consider:

1. **Enable caching** in nginx proxy manager
2. **Optimize database** settings in PostgreSQL
3. **Monitor resource usage** and adjust container limits
4. **Consider Redis** for session storage instead of Memcached

## Final Verification Checklist

- [ ] DNS resolves correctly
- [ ] SSL certificate is valid and auto-renewing
- [ ] OpenProject loads via HTTPS
- [ ] All OpenProject features work properly
- [ ] Security hardening applied
- [ ] Monitoring and logging configured
- [ ] Backup procedures in place

Your OpenProject instance should now be accessible at `https://openproject-dev.caonyx.com` with proper SSL encryption and security headers!
