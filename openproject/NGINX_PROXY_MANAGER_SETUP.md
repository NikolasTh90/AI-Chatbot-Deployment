# nginx Proxy Manager Setup Guide for OpenProject

This guide covers how to configure nginx Proxy Manager to expose OpenProject using your domain `openproject-dev.caonyx.com`.

## Prerequisites

1. ✅ DNS record `openproject-dev.caonyx.com` pointing to your server's IP
2. ✅ OpenProject docker-compose stack running
3. ✅ nginx Proxy Manager installed and connected to `proxy-network`
4. ✅ SSL certificate (Let's Encrypt recommended)

## Step 1: Verify Network Setup

Ensure your nginx Proxy Manager is connected to the same `proxy-network` as OpenProject:

```bash
# Check if proxy-network exists
docker network ls | grep proxy-network

# If not, create it
docker network create proxy-network

# Connect your nginx proxy manager to the network
docker network connect proxy-network <nginx-proxy-manager-container-name>

# Verify the connection
docker network inspect proxy-network
```

The output should show both your nginx Proxy Manager container and the OpenProject containers connected to the network.

## Step 2: Configure OpenProject Environment

Update your `.env` file to match your domain:

```bash
# Edit the .env file
nano .env
```

Add/update these settings:

```env
# Domain configuration
OPENPROJECT_HTTPS=true
OPENPROJECT_HOST__NAME=openproject-dev.caonyx.com
OPENPROJECT_HSTS=true
OPENPROJECT_RAILS__RELATIVE__URL__ROOT=

# Keep other settings as is
DATABASE_URL=postgres://postgres:p4ssw0rd@db/openproject?pool=20&encoding=unicode&reconnect=true
RAILS_MIN_THREADS=4
RAILS_MAX_THREADS=16
IMAP_ENABLED=false
```

Restart OpenProject with the new settings:

```bash
docker compose down
docker compose up -d
```

## Step 3: nginx Proxy Manager Configuration

### 3.1 Access nginx Proxy Manager

Open your web browser and navigate to your nginx Proxy Manager instance:
- **URL**: `http://your-server-ip:8080` (or your configured port)
- **Default Email**: `admin@example.com`
- **Default Password**: `changeme`

Change the default password on first login.

### 3.2 Add SSL Certificate

1. **Navigate to SSL Certificates**
   - Click on the **SSL Certificates** tab in the top navigation
   - Click the **Add SSL Certificate** button

2. **Configure Let's Encrypt Certificate**
   - **Certificate Source**: Select **Let's Encrypt**
   - **Domain Names**: Enter `openproject-dev.caonyx.com`
   - **Email**: Enter your email address for certificate notifications
   - **Agree to Terms**: Check the box for Let's Encrypt Terms of Service
   - **Use a DNS Challenge**: Leave unchecked (HTTP challenge works fine)
   - **Propagation Seconds**: Leave as default

3. **Save and Wait**
   - Click **Save**
   - Wait for the certificate to be issued (usually 1-2 minutes)
   - You should see a green checkmark when successful

### 3.3 Create Proxy Host

1. **Navigate to Hosts**
   - Click on the **Hosts** tab
   - Click on **Proxy Hosts**
   - Click the **Add Proxy Host** button

2. **Configure Details Tab**
   - **Domain Names**: `openproject-dev.caonyx.com`
   - **Scheme**: `http`
   - **Forward Hostname/IP**: `proxy` (exact container name)
   - **Forward Port**: `80`
   - **Block Common Exploits**: ✅ Checked
   - **Websockets Support**: ✅ Checked
   - **Access List**: Leave as `Public` (or configure authentication if needed)

3. **Configure SSL Tab**
   - **SSL Certificate**: Select the certificate you created in step 3.2
   - **SSL Force SSL**: ✅ Checked (redirect HTTP to HTTPS)
   - **HTTP/2 Support**: ✅ Checked
   - **HSTS Enabled**: ✅ Checked
   - **HSTS Subdomains**: ✅ Checked
   - **HSTS Preload**: Leave unchecked
   - **Custom Nginx Configuration**: Leave empty for now

4. **Configure Advanced Tab**
   Add these settings in the Custom Nginx Configuration box:

   ```nginx
   # Increase client body size for file uploads
   client_max_body_size 100M;
   
   # Enhanced proxy headers for OpenProject
   proxy_set_header X-Forwarded-Proto $scheme;
   proxy_set_header X-Forwarded-Host $host;
   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
   proxy_set_header X-Real-IP $remote_addr;
   proxy_set_header X-Forwarded-Port $server_port;
   
   # Timeout settings for long-running operations
   proxy_connect_timeout 30s;
   proxy_send_timeout 300s;
   proxy_read_timeout 300s;
   
   # Buffer settings
   proxy_buffering on;
   proxy_buffer_size 4k;
   proxy_buffers 8 4k;
   
   # WebSocket support
   proxy_http_version 1.1;
   proxy_set_header Upgrade $http_upgrade;
   proxy_set_header Connection "upgrade";
   
   # Security headers
   add_header X-Frame-Options "SAMEORIGIN" always;
   add_header X-Content-Type-Options "nosniff" always;
   add_header X-XSS-Protection "1; mode=block" always;
   add_header Referrer-Policy "strict-origin-when-cross-origin" always;
   ```

5. **Save Configuration**
   - Click **Save** to create the proxy host
   - Wait for the configuration to be applied (usually 30 seconds)

## Step 4: Verify Configuration

### 4.1 Check nginx Proxy Manager Status

1. **Proxy Host Status**
   - Go to **Hosts** → **Proxy Hosts**
   - Verify your OpenProject host shows as **Running** (green status)
   - Check for any error messages

2. **SSL Certificate Status**
   - Go to **SSL Certificates**
   - Verify your certificate shows as **Active**
   - Check the expiry date

3. **Check Logs**
   - Click on your proxy host to view details
   - Click the **Logs** tab to check for any errors

### 4.2 Test DNS Resolution

```bash
# Test DNS resolution
nslookup openproject-dev.caonyx.com

# Should return your server's IP address
dig openproject-dev.caonyx.com
```

### 4.3 Test SSL Certificate

```bash
# Test SSL certificate
openssl s_client -connect openproject-dev.caonyx.com:443 -servername openproject-dev.caonyx.com

# Check certificate details and verify return code is 0 (ok)
```

### 4.4 Test OpenProject Access

1. **Open Browser**
   - Navigate to: `https://openproject-dev.caonyx.com`
   - You should see the OpenProject login page

2. **Verify HTTPS**
   - Check for the padlock icon in the browser
   - Verify the certificate details match your domain

3. **Test Login**
   - Default credentials:
     - Username: `admin`
     - Password: `admin`
   - Change the default password immediately after first login

## Step 5: Security Hardening

### 5.1 Change Default Passwords

1. **OpenProject Admin Password**
   - Log in as admin
   - Go to **My account** → **Change password**
   - Set a strong, unique password

2. **nginx Proxy Manager Password**
   - Use the admin interface to change the default email/password
   - Enable 2FA if available

### 5.2 Firewall Configuration

Ensure only necessary ports are open:

```bash
# Allow HTTP/HTTPS traffic
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow nginx Proxy Manager admin interface (optional, restrict to your IP)
sudo ufw allow from YOUR_IP to any port 8080

# Block direct access to OpenProject ports
sudo ufw deny 8080/tcp
sudo ufw enable
```

### 5.3 Additional Security Headers

Add these headers to the **Advanced** tab in nginx Proxy Manager:

```nginx
# Enhanced security headers
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self'; frame-ancestors 'self';" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;

# Hide server information
server_tokens off;
proxy_hide_header X-Powered-By;
proxy_hide_header X-Drupal-Cache;
```

## Step 6: Monitoring and Maintenance

### 6.1 Monitor Logs

Regularly check both nginx Proxy Manager and OpenProject logs:

```bash
# nginx Proxy Manager logs
docker logs -f <nginx-proxy-manager-container-name>

# OpenProject logs
docker compose logs -f web
docker compose logs -f proxy
```

### 6.2 Performance Monitoring

Monitor site performance with these tools:

1. **nginx Proxy Manager Dashboard**
   - Monitor bandwidth usage
   - Check active connections
   - Review access patterns

2. **OpenProject Health Checks**
   - Monitor at: `https://openproject-dev.caonyx.com/health_checks/default`
   - Set up external monitoring (UptimeRobot, Pingdom, etc.)

### 6.3 SSL Certificate Renewal

Let's Encrypt certificates automatically renew, but monitor:

1. **Auto-Renewal**: nginx Proxy Manager handles this automatically
2. **Email Alerts**: Ensure your email address is correct for renewal notices
3. **Manual Check**: Verify certificate expiry dates in the SSL Certificates tab

## Troubleshooting

### Common Issues and Solutions

#### Page Not Loading / 502 Bad Gateway

1. **Check Container Status**
   ```bash
   docker compose ps
   docker compose logs proxy
   ```

2. **Verify Network Connectivity**
   ```bash
   docker exec -it <nginx-container> ping proxy
   docker exec -it <nginx-container> curl http://proxy:80
   ```

3. **Check nginx Proxy Manager Configuration**
   - Verify Forward Hostname is exactly `proxy`
   - Check that Forward Port is `80`
   - Review logs for specific error messages

#### SSL Certificate Issues

1. **DNS Problems**
   ```bash
   nslookup openproject-dev.caonyx.com
   dig openproject-dev.caonyx.com +trace
   ```

2. **Port 80/443 Accessibility**
   ```bash
   # Test from external server
   curl -I http://openproject-dev.caonyx.com
   telnet openproject-dev.caonyx.com 80
   telnet openproject-dev.caonyx.com 443
   ```

3. **Certificate Validation**
   ```bash
   openssl s_client -connect openproject-dev.caonyx.com:443 -servername openproject-dev.caonyx.com
   ```

#### Login Issues

1. **Direct Access Test**
   - Temporarily expose port 8080 to test direct access
   - Ensure OpenProject is working internally

2. **Check OpenProject Logs**
   ```bash
   docker compose logs web | tail -50
   ```

3. **Database Connectivity**
   ```bash
   docker compose exec db psql -U postgres -d openproject -c "SELECT 1;"
   ```

#### File Upload Issues

1. **Check nginx Configuration**
   - Verify `client_max_body_size` is set to `100M`
   - Check available disk space on server

2. **OpenProject Configuration**
   - Verify asset directory permissions
   - Check available storage in `opdata` volume

### Performance Issues

1. **High Memory Usage**
   - Monitor container resource usage
   - Consider increasing Docker memory limits
   - Optimize OpenProject configuration

2. **Slow Response Times**
   - Check database query performance
   - Enable caching in nginx Proxy Manager
   - Review OpenProject performance settings

## Advanced Configuration

### Custom Error Pages

Add to nginx Proxy Manager Advanced tab:

```nginx
error_page 502 503 504 /50x.html;
location = /50x.html {
    root /usr/share/nginx/html;
}
```

### Rate Limiting

Add to nginx Proxy Manager Advanced tab:

```nginx
# Rate limiting to prevent abuse
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req zone=api burst=20 nodelay;
```

### Caching Configuration

Enable caching in nginx Proxy Manager:

1. Go to **Proxy Host** → **Advanced**
2. Add caching configuration:

```nginx
# Enable caching for static assets
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

## Final Verification Checklist

- [ ] DNS resolves correctly to server IP
- [ ] SSL certificate is valid and auto-renewing
- [ ] HTTPS redirection works properly
- [ ] OpenProject loads without errors
- [ ] Login functions correctly
- [ ] File uploads work (test with small file)
- [ ] Security headers are present
- [ ] Performance is acceptable
- [ ] Monitoring and logging configured
- [ ] Backup procedures documented

Your OpenProject instance should now be securely accessible at `https://openproject-dev.caonyx.com` with proper SSL encryption, security headers, and performance optimization through nginx Proxy Manager!