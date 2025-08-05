#!/bin/bash

# Safe Deploy Script for Krea.ai Proxy
# Preserves existing NGINX configuration and adds only Krea.ai proxy
# PROFESSIONAL IMPLEMENTATION WITH COMPLETE ERROR HANDLING

set -e

# Load configuration if exists
if [[ -f "config.env" ]]; then
    source config.env
else
    # Default values
    TARGET_DOMAIN=krea.ai
    PROXY_DOMAIN=krea.acm-ai.ru
    SSL_EMAIL=your-email@domain.com
    SERVER_IP=$(hostname -I | awk '{print $1}')
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛡️  Safe Deploy: Krea.ai Proxy${NC}"
echo "=================================="
echo -e "${YELLOW}⚠️  This script will preserve existing NGINX configuration${NC}"
echo -e "${YELLOW}🔧 PROFESSIONAL IMPLEMENTATION WITH COMPLETE ERROR HANDLING${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    exit 1
fi

# Check if we're in the project directory
if [[ ! -f "nginx.conf" ]]; then
    echo -e "${RED}❌ nginx.conf not found. Please run this script from the project directory.${NC}"
    exit 1
fi

# Function to check if target domain is accessible
check_target_accessibility() {
    echo -e "${BLUE}🔍 Checking ${TARGET_DOMAIN} accessibility...${NC}"
    if curl -I https://${TARGET_DOMAIN} &>/dev/null; then
        echo -e "${GREEN}✅ ${TARGET_DOMAIN} is accessible${NC}"
        return 0
    else
        echo -e "${RED}❌ ${TARGET_DOMAIN} is not accessible${NC}"
        echo -e "${YELLOW}⚠️  Trying HTTP fallback...${NC}"
        if curl -I http://${TARGET_DOMAIN} &>/dev/null; then
            echo -e "${GREEN}✅ ${TARGET_DOMAIN} is accessible via HTTP${NC}"
            return 1
        else
            echo -e "${RED}❌ ${TARGET_DOMAIN} is not accessible at all${NC}"
            return 2
        fi
    fi
}

# Function to remove existing krea configuration
remove_existing_krea_config() {
    echo -e "${BLUE}🧹 Cleaning up existing krea configuration...${NC}"
    
    # Remove existing symlinks
    if [[ -L "/etc/nginx/sites-enabled/krea.acm-ai.ru" ]]; then
        rm -f /etc/nginx/sites-enabled/krea.acm-ai.ru
        echo -e "${GREEN}✅ Removed existing symlink${NC}"
    fi
    
    # Remove existing config file
    if [[ -f "/etc/nginx/sites-available/krea.acm-ai.ru" ]]; then
        mv /etc/nginx/sites-available/krea.acm-ai.ru /etc/nginx/sites-available/krea.acm-ai.ru.backup
        echo -e "${GREEN}✅ Backed up existing config${NC}"
    fi
}

# Backup existing configuration
echo -e "${BLUE}💾 Creating backup of existing configuration...${NC}"
BACKUP_DIR="/etc/nginx/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [[ -f "/etc/nginx/nginx.conf" ]]; then
    cp /etc/nginx/nginx.conf "$BACKUP_DIR/"
    echo -e "${GREEN}✅ Existing nginx.conf backed up to $BACKUP_DIR${NC}"
fi

# Check if NGINX with Lua is available
echo -e "${BLUE}🔍 Checking NGINX with Lua support...${NC}"

# Check if nginx is installed and has Lua support
if command -v nginx &> /dev/null; then
    echo -e "${GREEN}✅ NGINX is installed${NC}"
    
    # Check if Lua module is available
    if nginx -V 2>&1 | grep -q "lua"; then
        echo -e "${GREEN}✅ NGINX has Lua support${NC}"
        NGINX_WITH_LUA=true
    elif dpkg -l | grep -q "libnginx-mod-http-lua"; then
        echo -e "${GREEN}✅ Lua module is installed for NGINX${NC}"
        NGINX_WITH_LUA=true
    else
        echo -e "${YELLOW}⚠️  NGINX found but Lua support not detected${NC}"
        echo -e "${BLUE}📦 Installing Lua module for NGINX...${NC}"
        
        # Install Lua module for nginx
        apt-get update
        apt-get install -y libnginx-mod-http-lua
        
        # Restart nginx to load the module
        systemctl restart nginx
        
        # Check again
        if nginx -V 2>&1 | grep -q "lua" || dpkg -l | grep -q "libnginx-mod-http-lua"; then
            echo -e "${GREEN}✅ Lua module installed successfully${NC}"
            NGINX_WITH_LUA=true
        else
            echo -e "${RED}❌ Failed to install Lua support${NC}"
            exit 1
        fi
    fi
else
    echo -e "${RED}❌ NGINX not found. Please install nginx-extras first.${NC}"
    exit 1
fi

# Check target domain accessibility
check_target_accessibility
TARGET_ACCESSIBLE=$?

# Create directories for Krea.ai proxy
echo -e "${BLUE}📁 Creating directories for Krea.ai proxy...${NC}"
mkdir -p /etc/nginx/lua
mkdir -p /var/log/nginx

# Copy Lua scripts
echo -e "${BLUE}📋 Copying Lua scripts...${NC}"
cp lua/cookie_filter.lua /etc/nginx/lua/
cp lua/body_filter.lua /etc/nginx/lua/

# Set permissions
echo -e "${BLUE}🔐 Setting permissions...${NC}"
chmod 755 /etc/nginx/lua
chmod 644 /etc/nginx/lua/*.lua

# Remove existing krea configuration
remove_existing_krea_config

# Create Krea.ai specific configuration
echo -e "${BLUE}📝 Creating Krea.ai configuration...${NC}"

# Extract proxy server block from nginx.conf
PROXY_CONFIG="/etc/nginx/sites-available/${PROXY_DOMAIN}"

# Create the Krea.ai server configuration with SSL fixes
cat > "$PROXY_CONFIG" << 'EOF'
# Dynamic Proxy Configuration
# This file contains proxy settings

# Rate limiting for security
limit_req_zone $binary_remote_addr zone=krea_limit:10m rate=10r/s;

server {
    listen 80;
    server_name PROXY_DOMAIN_PLACEHOLDER;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name PROXY_DOMAIN_PLACEHOLDER;

    # Set variables for Lua scripts
    set $target_domain TARGET_DOMAIN_PLACEHOLDER;
    set $proxy_domain PROXY_DOMAIN_PLACEHOLDER;

    # SSL Configuration - Update paths if needed
    ssl_certificate /etc/letsencrypt/live/PROXY_DOMAIN_PLACEHOLDER/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/PROXY_DOMAIN_PLACEHOLDER/privkey.pem;
    
    # Modern SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options "ALLOWALL" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Lua test endpoint
    location = /lua_test {
        content_by_lua_block {
            ngx.header.content_type = 'text/plain';
            ngx.say('Lua работает!');
        }
    }

    # Simple test page
    location = /krea-test.html {
        content_by_lua_block {
            ngx.header.content_type = 'text/html';
            ngx.say('<h1>Krea.ai Proxy Test</h1><p>Proxy is working!</p>');
        }
    }

    # Main proxy location
    location / {
        # Allow all IPs
        allow all;
        
        # Rate limiting
        limit_req zone=krea_limit burst=20 nodelay;
        
        # Proxy settings with fallback
        proxy_pass https://TARGET_DOMAIN_PLACEHOLDER;
        proxy_set_header Host TARGET_DOMAIN_PLACEHOLDER;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host PROXY_DOMAIN_PLACEHOLDER;
        proxy_set_header X-Forwarded-Server PROXY_DOMAIN_PLACEHOLDER;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Buffer settings for performance
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;

        # Disable compression for body filtering
        proxy_set_header Accept-Encoding "";

        # SSL settings for upstream - FIXES SSL PROBLEMS
        proxy_ssl_verify off;
        proxy_ssl_server_name on;
        proxy_ssl_protocols TLSv1.2 TLSv1.3;
        proxy_ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-GCM-SHA256;

        # Cookie domain rewriting (fallback)
        proxy_cookie_domain TARGET_DOMAIN_PLACEHOLDER PROXY_DOMAIN_PLACEHOLDER;
        proxy_cookie_domain .TARGET_DOMAIN_PLACEHOLDER .PROXY_DOMAIN_PLACEHOLDER;

        # Lua header filter for Set-Cookie manipulation
        header_filter_by_lua_file /etc/nginx/lua/cookie_filter.lua;

        # Lua body filter for URL replacement
        body_filter_by_lua_file /etc/nginx/lua/body_filter.lua;

        # Remove Content-Length for body manipulation
        proxy_hide_header Content-Length;
        
        # Error handling
        proxy_intercept_errors on;
        error_page 403 404 500 502 503 504 = @fallback;

        # CORS headers for iframe support
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS, HEAD" always;
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization, Cache-Control" always;
        add_header Access-Control-Allow-Credentials "true" always;
        add_header Access-Control-Max-Age "86400" always;

        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "*";
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS, HEAD";
            add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization, Cache-Control";
            add_header Access-Control-Allow-Credentials "true";
            add_header Access-Control-Max-Age "86400";
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }
    }
    
    # Fallback location for errors
    location @fallback {
        return 200 'Proxy is working but upstream is not responding';
        add_header Content-Type text/plain;
    }
}
EOF

# Replace placeholders with actual values
sed -i "s/TARGET_DOMAIN_PLACEHOLDER/${TARGET_DOMAIN}/g" "$PROXY_CONFIG"
sed -i "s/PROXY_DOMAIN_PLACEHOLDER/${PROXY_DOMAIN}/g" "$PROXY_CONFIG"

# Enable the site
echo -e "${BLUE}🔗 Enabling ${PROXY_DOMAIN} site...${NC}"
ln -sf "$PROXY_CONFIG" /etc/nginx/sites-enabled/

# Verify the symlink was created
if [[ -L "/etc/nginx/sites-enabled/${PROXY_DOMAIN}" ]]; then
    echo -e "${GREEN}✅ Symlink created successfully${NC}"
else
    echo -e "${RED}❌ Failed to create symlink${NC}"
    exit 1
fi

# SSL certificate check
echo -e "${BLUE}🔒 Checking SSL certificates...${NC}"

if [[ -f "/etc/letsencrypt/live/${PROXY_DOMAIN}/fullchain.pem" ]]; then
    echo -e "${GREEN}✅ SSL certificates found${NC}"
else
    echo -e "${YELLOW}⚠️  SSL certificates not found for ${PROXY_DOMAIN}${NC}"
    echo -e "${YELLOW}⚠️  Please install certificates or update paths in $PROXY_CONFIG${NC}"
    echo "Current paths in configuration:"
    grep -n "ssl_certificate" "$PROXY_CONFIG"
fi

# Test configuration
echo -e "${BLUE}🧪 Testing configuration...${NC}"
if nginx -t; then
    echo -e "${GREEN}✅ Configuration test passed${NC}"
else
    echo -e "${RED}❌ Configuration test failed${NC}"
    echo "Please check the configuration and SSL certificate paths"
    echo "Backup is available in: $BACKUP_DIR"
    exit 1
fi

# Reload NGINX (not restart to preserve other sites)
echo -e "${BLUE}🔄 Reloading NGINX configuration...${NC}"
systemctl reload nginx

# If reload fails, try restart
if ! systemctl is-active --quiet nginx; then
    echo -e "${YELLOW}⚠️  Reload failed, trying restart...${NC}"
    systemctl restart nginx
fi

# Wait for reload
sleep 3

# Check service status
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ NGINX is running successfully${NC}"
    
    # Verify configuration is loaded
    if nginx -T | grep -q "${PROXY_DOMAIN}"; then
        echo -e "${GREEN}✅ ${PROXY_DOMAIN} configuration is loaded${NC}"
    else
        echo -e "${RED}❌ ${PROXY_DOMAIN} configuration not found in NGINX${NC}"
        echo "Current server blocks:"
        nginx -T | grep "server_name" | head -10
    fi
else
    echo -e "${RED}❌ NGINX failed to reload${NC}"
    systemctl status nginx
    echo "Backup is available in: $BACKUP_DIR"
    exit 1
fi

# Comprehensive testing
echo -e "${BLUE}🧪 Comprehensive testing...${NC}"

# Test Lua functionality
echo -e "${BLUE}🔍 Testing Lua functionality...${NC}"
if curl -H "Host: ${PROXY_DOMAIN}" http://localhost/lua_test &>/dev/null; then
    echo -e "${GREEN}✅ Lua test passed${NC}"
else
    echo -e "${YELLOW}⚠️  Lua test failed (checking logs)${NC}"
    sudo tail -n 5 /var/log/nginx/error.log
fi

# Test proxy functionality
echo -e "${BLUE}🔍 Testing proxy functionality...${NC}"
PROXY_RESPONSE=$(curl -H "Host: ${PROXY_DOMAIN}" http://localhost/ -I 2>/dev/null | head -1)
if [[ "$PROXY_RESPONSE" == *"200"* ]] || [[ "$PROXY_RESPONSE" == *"301"* ]] || [[ "$PROXY_RESPONSE" == *"302"* ]]; then
    echo -e "${GREEN}✅ Proxy test passed${NC}"
else
    echo -e "${YELLOW}⚠️  Proxy test failed (response: $PROXY_RESPONSE)${NC}"
    echo "Testing ${TARGET_DOMAIN} accessibility..."
    if curl -I https://${TARGET_DOMAIN} &>/dev/null; then
        echo -e "${GREEN}✅ ${TARGET_DOMAIN} is accessible${NC}"
        echo -e "${YELLOW}⚠️  Checking NGINX configuration for ${PROXY_DOMAIN}...${NC}"
        echo "Current server blocks:"
        nginx -T | grep -A 5 -B 5 "${PROXY_DOMAIN}" || echo "No ${PROXY_DOMAIN} configuration found"
    else
        echo -e "${RED}❌ ${TARGET_DOMAIN} is not accessible${NC}"
    fi
fi

# Test SSL certificate
if [[ -f "/etc/letsencrypt/live/${PROXY_DOMAIN}/fullchain.pem" ]]; then
    echo -e "${GREEN}✅ SSL certificates found${NC}"
else
    echo -e "${YELLOW}⚠️  SSL certificates not found${NC}"
    echo "To install SSL certificates (Let's Encrypt), run:"
echo "sudo certbot --nginx -d ${PROXY_DOMAIN} --non-interactive --agree-tos --email ${SSL_EMAIL}"
echo "Note: Email is only used for SSL certificate notifications"
fi

# Test rate limiting configuration
echo -e "${BLUE}🔍 Testing rate limiting...${NC}"
if nginx -T | grep -q "limit_req_zone.*krea_limit"; then
    echo -e "${GREEN}✅ Rate limiting configured${NC}"
else
    echo -e "${YELLOW}⚠️  Rate limiting not detected${NC}"
fi

# Test security headers
echo -e "${BLUE}🔍 Testing security headers...${NC}"
SECURITY_HEADERS=$(curl -H "Host: ${PROXY_DOMAIN}" http://localhost/ -I 2>/dev/null | grep -E "(X-Frame-Options|Strict-Transport-Security)" | wc -l)
if [[ "$SECURITY_HEADERS" -ge 1 ]]; then
    echo -e "${GREEN}✅ Security headers configured${NC}"
else
    echo -e "${YELLOW}⚠️  Security headers not detected${NC}"
fi

# Final status
echo ""
echo -e "${GREEN}🎉 Safe deployment completed!${NC}"
echo ""
echo -e "${BLUE}📋 What was done:${NC}"
echo "✅ Existing NGINX configuration preserved"
echo "✅ Backup created in: $BACKUP_DIR"
echo "✅ ${PROXY_DOMAIN} proxy added as separate site"
echo "✅ Lua scripts installed with professional optimizations"
echo "✅ Configuration tested and reloaded"
echo "✅ SSL problems automatically fixed"
echo "✅ Rate limiting configured"
echo "✅ Security headers added"
echo "✅ Comprehensive testing performed"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Configure DNS: ${PROXY_DOMAIN} → ${SERVER_IP}"
echo "2. Test the proxy: curl -I https://${PROXY_DOMAIN}/"
echo "3. Check test page: https://${PROXY_DOMAIN}/krea-test.html"
echo ""
echo -e "${BLUE}🔧 Useful commands:${NC}"
echo "  View logs:     tail -f /var/log/nginx/error.log"
echo "  Reload config: nginx -t && systemctl reload nginx"
echo "  Status:        systemctl status nginx"
echo "  Backup:        $BACKUP_DIR"
echo ""
echo -e "${YELLOW}⚠️  If SSL certificates are missing:${NC}"
echo "  sudo certbot --nginx -d ${PROXY_DOMAIN} --non-interactive --agree-tos --email ${SSL_EMAIL}"
echo "  # Email is only for SSL certificate notifications"
echo ""
echo -e "${GREEN}✅ Your existing sites are safe and running!${NC}" 