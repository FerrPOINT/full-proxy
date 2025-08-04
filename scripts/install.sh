#!/bin/bash

# OpenResty Installation Script for Krea.ai Proxy
# This script installs OpenResty and configures the environment

set -e

echo "🚀 Installing OpenResty for Krea.ai Proxy..."

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        echo "📦 Installing on Ubuntu/Debian..."
        
        # Add OpenResty repository
        wget -qO - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
        echo "deb http://openresty.org/package/ubuntu $(lsb_release -sc) openresty" | sudo tee /etc/apt/sources.list.d/openresty.list
        
        # Update and install
        sudo apt-get update
        sudo apt-get install -y openresty
        
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        echo "📦 Installing on CentOS/RHEL..."
        
        # Add OpenResty repository
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
        sudo yum install -y openresty
        
    else
        echo "❌ Unsupported Linux distribution. Please install OpenResty manually."
        exit 1
    fi
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo "📦 Installing on macOS..."
    
    if command -v brew &> /dev/null; then
        brew install openresty
    else
        echo "❌ Homebrew not found. Please install Homebrew first: https://brew.sh/"
        exit 1
    fi
    
else
    echo "❌ Unsupported OS. Please install OpenResty manually."
    exit 1
fi

# Create necessary directories
echo "📁 Creating directories..."
sudo mkdir -p /etc/nginx/lua
sudo mkdir -p /var/log/nginx
sudo mkdir -p /etc/letsencrypt/live/krea.acm-ai.ru

# Copy configuration files
echo "📋 Copying configuration files..."
sudo cp nginx.conf /etc/nginx/nginx.conf
sudo cp lua/cookie_filter.lua /etc/nginx/lua/
sudo cp lua/body_filter.lua /etc/nginx/lua/

# Set permissions
echo "🔐 Setting permissions..."
sudo chown -R nginx:nginx /etc/nginx/lua
sudo chmod 755 /etc/nginx/lua
sudo chmod 644 /etc/nginx/lua/*.lua

# Test configuration
echo "🧪 Testing configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration test passed!"
    
    # Start/restart OpenResty
    echo "🔄 Starting OpenResty..."
    sudo systemctl enable openresty
    sudo systemctl restart openresty
    
    echo "🎉 OpenResty installation completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Configure DNS: krea.acm-ai.ru -> $(curl -s ifconfig.me)"
    echo "2. Install SSL certificate: sudo certbot --nginx -d krea.acm-ai.ru"
    echo "3. Test the proxy: curl -I https://krea.acm-ai.ru/lua_test"
    echo "4. Check test page: https://krea.acm-ai.ru/krea-test.html"
    
else
    echo "❌ Configuration test failed!"
    exit 1
fi 