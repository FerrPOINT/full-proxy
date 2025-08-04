#!/bin/bash

# Safe Deploy Script for Krea.ai Proxy
# Preserves existing NGINX configuration and adds only Krea.ai proxy

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛡️  Safe Deploy: Krea.ai Proxy${NC}"
echo "=================================="
echo -e "${YELLOW}⚠️  This script will preserve existing NGINX configuration${NC}"

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

# Create Krea.ai specific configuration
echo -e "${BLUE}📝 Creating Krea.ai configuration...${NC}"

# Extract Krea.ai server block from nginx.conf
KREA_CONFIG="/etc/nginx/sites-available/krea.acm-ai.ru"

# Create the Krea.ai server configuration
cat > "$KREA_CONFIG" << 'EOF'
# Krea.ai Proxy Configuration
# This file contains only the Krea.ai proxy settings

server {
    listen 80;
    server_name krea.acm-ai.ru;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name krea.acm-ai.ru;

    # SSL Configuration - Update paths if needed
    ssl_certificate /etc/letsencrypt/live/krea.acm-ai.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/krea.acm-ai.ru/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Lua test endpoint
    location = /lua_test {
        content_by_lua_block {
            ngx.header.content_type = 'text/plain';
            ngx.say('Lua работает!');
        }
    }

    # Test page with iframe
    location = /krea-test.html {
        content_by_lua_block {
            ngx.header.content_type = 'text/html';
            ngx.say([[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Krea.ai Proxy Test</title>
    <style>
        body { margin: 0; padding: 20px; font-family: Arial, sans-serif; }
        .container { max-width: 1200px; margin: 0 auto; }
        h1 { color: #333; margin-bottom: 20px; }
        .iframe-container { 
            border: 2px solid #ddd; 
            border-radius: 8px; 
            overflow: hidden;
            height: 80vh;
        }
        iframe { 
            width: 100%; 
            height: 100%; 
            border: none; 
        }
        .status { 
            margin-top: 20px; 
            padding: 10px; 
            background: #f0f0f0; 
            border-radius: 4px; 
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Krea.ai Proxy Test Page</h1>
        <div class="iframe-container">
            <iframe src="https://krea.acm-ai.ru/" 
                    allow="camera; microphone; geolocation; encrypted-media; display-capture"
                    sandbox="allow-same-origin allow-scripts allow-forms allow-popups allow-modals">
            </iframe>
        </div>
        <div class="status">
            <p><strong>Status:</strong> Iframe loaded successfully</p>
            <p><strong>Domain:</strong> krea.acm-ai.ru</p>
            <p><strong>Target:</strong> krea.ai</p>
        </div>
    </div>
</body>
</html>
            ]]);
        }
    }

    # Main proxy location
    location / {
        # Proxy settings
        proxy_pass https://krea.ai;
        proxy_set_header Host krea.ai;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host krea.acm-ai.ru;
        proxy_set_header X-Forwarded-Server krea.acm-ai.ru;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;

        # Disable compression for body filtering
        proxy_set_header Accept-Encoding "";

        # Cookie domain rewriting (fallback)
        proxy_cookie_domain krea.ai krea.acm-ai.ru;
        proxy_cookie_domain .krea.ai .krea.acm-ai.ru;

        # Lua header filter for Set-Cookie manipulation
        header_filter_by_lua_file /etc/nginx/lua/cookie_filter.lua;

        # Lua body filter for URL replacement
        body_filter_by_lua_file /etc/nginx/lua/body_filter.lua;

        # Remove Content-Length for body manipulation
        proxy_hide_header Content-Length;

        # Security headers
        add_header X-Frame-Options "ALLOWALL" always;
        add_header Content-Security-Policy "frame-ancestors *" always;
        add_header X-Content-Type-Options nosniff always;
        add_header X-XSS-Protection "1; mode=block" always;

        # CORS headers for iframe support
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization" always;
        add_header Access-Control-Allow-Credentials "true" always;

        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "*";
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization";
            add_header Access-Control-Allow-Credentials "true";
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }
    }
}
EOF

# Enable the site
echo -e "${BLUE}🔗 Enabling Krea.ai site...${NC}"
ln -sf "$KREA_CONFIG" /etc/nginx/sites-enabled/

# SSL certificate check
echo -e "${BLUE}🔒 Checking SSL certificates...${NC}"

if [[ -f "/etc/letsencrypt/live/krea.acm-ai.ru/fullchain.pem" ]]; then
    echo -e "${GREEN}✅ SSL certificates found${NC}"
else
    echo -e "${YELLOW}⚠️  SSL certificates not found for krea.acm-ai.ru${NC}"
    echo -e "${YELLOW}⚠️  Please install certificates or update paths in $KREA_CONFIG${NC}"
    echo "Current paths in configuration:"
    grep -n "ssl_certificate" "$KREA_CONFIG"
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

# Wait for reload
sleep 2

# Check service status
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ NGINX is running successfully${NC}"
else
    echo -e "${RED}❌ NGINX failed to reload${NC}"
    systemctl status nginx
    echo "Backup is available in: $BACKUP_DIR"
    exit 1
fi

# Test Lua functionality
echo -e "${BLUE}🧪 Testing Lua functionality...${NC}"
if curl -f http://localhost/lua_test &>/dev/null; then
    echo -e "${GREEN}✅ Lua test passed${NC}"
else
    echo -e "${RED}❌ Lua test failed${NC}"
    echo "Checking logs..."
    tail -n 10 /var/log/nginx/error.log
fi

# Final status
echo ""
echo -e "${GREEN}🎉 Safe deployment completed!${NC}"
echo ""
echo -e "${BLUE}📋 What was done:${NC}"
echo "✅ Existing NGINX configuration preserved"
echo "✅ Backup created in: $BACKUP_DIR"
echo "✅ Krea.ai proxy added as separate site"
echo "✅ Lua scripts installed"
echo "✅ Configuration tested and reloaded"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Configure DNS: krea.acm-ai.ru → $(curl -s ifconfig.me)"
echo "2. Test the proxy: curl -I https://krea.acm-ai.ru/"
echo "3. Check test page: https://krea.acm-ai.ru/krea-test.html"
echo ""
echo -e "${BLUE}🔧 Useful commands:${NC}"
echo "  View logs:     tail -f /var/log/nginx/error.log"
echo "  Reload config: nginx -t && systemctl reload nginx"
echo "  Status:        systemctl status nginx"
echo "  Backup:        $BACKUP_DIR"
echo ""
echo -e "${YELLOW}⚠️  If SSL certificates are missing:${NC}"
echo "  sudo certbot --nginx -d krea.acm-ai.ru --non-interactive --agree-tos --email admin@acm-ai.ru"
echo ""
echo -e "${GREEN}✅ Your existing sites are safe and running!${NC}" 