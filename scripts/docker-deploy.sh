#!/bin/bash

# Docker Deployment Script for Krea.ai Proxy
# Deploys the proxy using Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 Deploying Krea.ai Proxy with Docker...${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Create necessary directories
echo -e "${BLUE}📁 Creating directories...${NC}"
mkdir -p ssl logs backups

# Build and start the containers
echo -e "${BLUE}🔨 Building containers...${NC}"
docker-compose build

echo -e "${BLUE}🚀 Starting containers...${NC}"
docker-compose up -d

# Wait for containers to be ready
echo -e "${BLUE}⏳ Waiting for containers to be ready...${NC}"
sleep 10

# Check container status
echo -e "${BLUE}📊 Checking container status...${NC}"
docker-compose ps

# Test the proxy
echo -e "${BLUE}🧪 Testing the proxy...${NC}"

# Wait for health check to pass
echo -e "${YELLOW}⏳ Waiting for health check to pass...${NC}"
for i in {1..30}; do
    if docker-compose exec krea-proxy /usr/local/bin/healthcheck.sh &>/dev/null; then
        echo -e "${GREEN}✅ Health check passed!${NC}"
        break
    fi
    if [[ $i -eq 30 ]]; then
        echo -e "${RED}❌ Health check failed after 30 attempts${NC}"
        exit 1
    fi
    sleep 2
done

# Test Lua functionality
echo -e "${BLUE}🧪 Testing Lua functionality...${NC}"
if curl -f http://localhost/lua_test &>/dev/null; then
    echo -e "${GREEN}✅ Lua test passed!${NC}"
else
    echo -e "${RED}❌ Lua test failed${NC}"
    exit 1
fi

# SSL certificate setup
echo -e "${BLUE}🔒 Setting up SSL certificate...${NC}"
echo -e "${YELLOW}⚠️  Make sure your domain krea.acm-ai.ru points to this server${NC}"
echo -e "${YELLOW}⚠️  You can run the following command to get SSL certificate:${NC}"
echo "docker-compose run --rm certbot certonly --webroot --webroot-path=/var/www/html --email admin@acm-ai.ru --agree-tos --no-eff-email -d krea.acm-ai.ru"

# Show useful commands
echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Useful commands:${NC}"
echo "  View logs:          docker-compose logs -f"
echo "  Stop containers:    docker-compose down"
echo "  Restart containers: docker-compose restart"
echo "  Update containers:  docker-compose pull && docker-compose up -d"
echo "  Access container:   docker-compose exec krea-proxy sh"
echo ""
echo -e "${BLUE}🔗 Test URLs:${NC}"
echo "  Lua test:           http://localhost/lua_test"
echo "  Test page:          http://localhost/krea-test.html"
echo "  Main proxy:         http://localhost/"
echo ""
echo -e "${YELLOW}⚠️  Remember to:${NC}"
echo "  1. Configure DNS: krea.acm-ai.ru → $(curl -s ifconfig.me)"
echo "  2. Install SSL certificate using the certbot command above"
echo "  3. Test the proxy: ./scripts/test.sh" 