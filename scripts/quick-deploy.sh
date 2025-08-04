#!/bin/bash

# Quick Deploy Script for Krea.ai Proxy
# For servers with existing NGINX + SSL certificates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Quick Deploy: Krea.ai Proxy${NC}"
echo "=================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    exit 1
fi

# Detect OS and install OpenResty
echo -e "${BLUE}📦 Installing OpenResty...${NC}"

if command -v apt-get &> /dev/null; then
    # Ubuntu/Debian
    echo "Detected Ubuntu/Debian"
    
    # Remove existing nginx if present
    if systemctl is-active --quiet nginx; then
        echo -e "${YELLOW}⚠️  Stopping existing nginx...${NC}"
        systemctl stop nginx
        systemctl disable nginx
    fi
    
    # Add OpenResty repository
    wget -qO - https://openresty.org/package/pubkey.gpg | apt-key add -
    echo "deb http://openresty.org/package/ubuntu $(lsb_release -sc) openresty" | tee /etc/apt/sources.list.d/openresty.list
    
    # Install OpenResty
    apt-get update
    apt-get install -y openresty
    
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    echo "Detected CentOS/RHEL"
    
    # Remove existing nginx if present
    if systemctl is-active --quiet nginx; then
        echo -e "${YELLOW}⚠️  Stopping existing nginx...${NC}"
        systemctl stop nginx
        systemctl disable nginx
    fi
    
    # Install OpenResty
    yum install -y yum-utils
    yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
    yum install -y openresty
    
else
    echo -e "${RED}❌ Unsupported OS. Please install OpenResty manually.${NC}"
    exit 1
fi

# Create directories
echo -e "${BLUE}📁 Creating directories...${NC}"
mkdir -p /etc/nginx/lua
mkdir -p /var/log/nginx

# Copy configuration files
echo -e "${BLUE}📋 Copying configuration files...${NC}"

# Check if we're in the project directory
if [[ ! -f "nginx.conf" ]]; then
    echo -e "${RED}❌ nginx.conf not found. Please run this script from the project directory.${NC}"
    exit 1
fi

cp nginx.conf /etc/nginx/nginx.conf
cp lua/cookie_filter.lua /etc/nginx/lua/
cp lua/body_filter.lua /etc/nginx/lua/

# Set permissions
echo -e "${BLUE}🔐 Setting permissions...${NC}"
chown -R nginx:nginx /etc/nginx/lua
chmod 755 /etc/nginx/lua
chmod 644 /etc/nginx/lua/*.lua

# SSL certificate check
echo -e "${BLUE}🔒 Checking SSL certificates...${NC}"

if [[ -f "/etc/letsencrypt/live/krea.acm-ai.ru/fullchain.pem" ]]; then
    echo -e "${GREEN}✅ SSL certificates found${NC}"
else
    echo -e "${YELLOW}⚠️  SSL certificates not found for krea.acm-ai.ru${NC}"
    echo -e "${YELLOW}⚠️  Please update SSL paths in nginx.conf or install certificates${NC}"
    echo "Current paths in nginx.conf:"
    grep -n "ssl_certificate" /etc/nginx/nginx.conf
fi

# Test configuration
echo -e "${BLUE}🧪 Testing configuration...${NC}"
if nginx -t; then
    echo -e "${GREEN}✅ Configuration test passed${NC}"
else
    echo -e "${RED}❌ Configuration test failed${NC}"
    echo "Please check the configuration and SSL certificate paths"
    exit 1
fi

# Start OpenResty
echo -e "${BLUE}🚀 Starting OpenResty...${NC}"
systemctl enable openresty
systemctl restart openresty

# Wait for service to start
sleep 3

# Check service status
if systemctl is-active --quiet openresty; then
    echo -e "${GREEN}✅ OpenResty started successfully${NC}"
else
    echo -e "${RED}❌ OpenResty failed to start${NC}"
    systemctl status openresty
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
echo -e "${GREEN}🎉 Quick deployment completed!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Configure DNS: krea.acm-ai.ru → $(curl -s ifconfig.me)"
echo "2. Test the proxy: curl -I https://krea.acm-ai.ru/"
echo "3. Check test page: https://krea.acm-ai.ru/krea-test.html"
echo ""
echo -e "${BLUE}🔧 Useful commands:${NC}"
echo "  View logs:     tail -f /var/log/nginx/error.log"
echo "  Reload config: nginx -t && systemctl reload openresty"
echo "  Status:        systemctl status openresty"
echo ""
echo -e "${YELLOW}⚠️  If SSL certificates are missing:${NC}"
echo "  sudo certbot --nginx -d krea.acm-ai.ru --non-interactive --agree-tos --email admin@acm-ai.ru" 