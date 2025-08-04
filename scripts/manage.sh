#!/bin/bash

# OpenResty Management Script for Krea.ai Proxy
# Provides easy commands for managing the proxy service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service name
SERVICE="openresty"

show_help() {
    echo "OpenResty Management Script for Krea.ai Proxy"
    echo "============================================="
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     - Start OpenResty service"
    echo "  stop      - Stop OpenResty service"
    echo "  restart   - Restart OpenResty service"
    echo "  reload    - Reload configuration without stopping"
    echo "  status    - Show service status"
    echo "  logs      - Show recent logs"
    echo "  test      - Test configuration"
    echo "  ssl       - Install/renew SSL certificate"
    echo "  backup    - Backup current configuration"
    echo "  restore   - Restore configuration from backup"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 reload"
    echo "  $0 logs"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root${NC}"
        exit 1
    fi
}

start_service() {
    echo -e "${BLUE}🚀 Starting OpenResty...${NC}"
    systemctl start $SERVICE
    systemctl enable $SERVICE
    echo -e "${GREEN}✅ OpenResty started successfully${NC}"
}

stop_service() {
    echo -e "${BLUE}🛑 Stopping OpenResty...${NC}"
    systemctl stop $SERVICE
    echo -e "${GREEN}✅ OpenResty stopped successfully${NC}"
}

restart_service() {
    echo -e "${BLUE}🔄 Restarting OpenResty...${NC}"
    systemctl restart $SERVICE
    echo -e "${GREEN}✅ OpenResty restarted successfully${NC}"
}

reload_config() {
    echo -e "${BLUE}📋 Reloading configuration...${NC}"
    nginx -t
    if [[ $? -eq 0 ]]; then
        systemctl reload $SERVICE
        echo -e "${GREEN}✅ Configuration reloaded successfully${NC}"
    else
        echo -e "${RED}❌ Configuration test failed${NC}"
        exit 1
    fi
}

show_status() {
    echo -e "${BLUE}📊 Service Status:${NC}"
    systemctl status $SERVICE --no-pager -l
}

show_logs() {
    echo -e "${BLUE}📝 Recent Logs:${NC}"
    echo "=== Access Log ==="
    tail -n 20 /var/log/nginx/access.log
    echo ""
    echo "=== Error Log ==="
    tail -n 20 /var/log/nginx/error.log
}

test_config() {
    echo -e "${BLUE}🧪 Testing configuration...${NC}"
    nginx -t
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Configuration is valid${NC}"
    else
        echo -e "${RED}❌ Configuration has errors${NC}"
        exit 1
    fi
}

install_ssl() {
    echo -e "${BLUE}🔒 Installing SSL certificate...${NC}"
    
    # Check if certbot is installed
    if ! command -v certbot &> /dev/null; then
        echo -e "${YELLOW}⚠️  Certbot not found. Installing...${NC}"
        if command -v apt-get &> /dev/null; then
            apt-get update
            apt-get install -y certbot python3-certbot-nginx
        elif command -v yum &> /dev/null; then
            yum install -y certbot python3-certbot-nginx
        else
            echo -e "${RED}❌ Cannot install certbot automatically${NC}"
            exit 1
        fi
    fi
    
    # Install certificate
    certbot --nginx -d krea.acm-ai.ru --non-interactive --agree-tos --email admin@acm-ai.ru
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ SSL certificate installed successfully${NC}"
        echo -e "${YELLOW}⚠️  Remember to set up automatic renewal:${NC}"
        echo "sudo crontab -e"
        echo "0 12 * * * /usr/bin/certbot renew --quiet"
    else
        echo -e "${RED}❌ SSL certificate installation failed${NC}"
        exit 1
    fi
}

backup_config() {
    echo -e "${BLUE}💾 Creating backup...${NC}"
    local backup_dir="/etc/nginx/backup"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p $backup_dir
    cp /etc/nginx/nginx.conf $backup_dir/nginx.conf.$timestamp
    cp -r /etc/nginx/lua $backup_dir/lua.$timestamp
    
    echo -e "${GREEN}✅ Backup created: $backup_dir/nginx.conf.$timestamp${NC}"
}

restore_config() {
    echo -e "${BLUE}📥 Restoring configuration...${NC}"
    local backup_dir="/etc/nginx/backup"
    
    if [[ ! -d $backup_dir ]]; then
        echo -e "${RED}❌ No backup directory found${NC}"
        exit 1
    fi
    
    # Find latest backup
    local latest_backup=$(ls -t $backup_dir/nginx.conf.* | head -1)
    
    if [[ -z $latest_backup ]]; then
        echo -e "${RED}❌ No backup files found${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}⚠️  Restoring from: $latest_backup${NC}"
    cp $latest_backup /etc/nginx/nginx.conf
    
    # Restore Lua files
    local lua_backup=$(echo $latest_backup | sed 's/nginx.conf/lua/')
    if [[ -d $lua_backup ]]; then
        cp -r $lua_backup/* /etc/nginx/lua/
    fi
    
    echo -e "${GREEN}✅ Configuration restored successfully${NC}"
    reload_config
}

# Main script logic
case "${1:-help}" in
    start)
        check_root
        start_service
        ;;
    stop)
        check_root
        stop_service
        ;;
    restart)
        check_root
        restart_service
        ;;
    reload)
        check_root
        reload_config
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    test)
        check_root
        test_config
        ;;
    ssl)
        check_root
        install_ssl
        ;;
    backup)
        check_root
        backup_config
        ;;
    restore)
        check_root
        restore_config
        ;;
    help|*)
        show_help
        ;;
esac 