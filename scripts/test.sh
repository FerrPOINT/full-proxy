#!/bin/bash

# Test Script for Krea.ai Proxy
# Performs comprehensive testing of the proxy functionality

set -e

echo "🧪 Testing Krea.ai Proxy..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test functions
test_lua_working() {
    echo -n "Testing Lua functionality... "
    local response=$(curl -s https://krea.acm-ai.ru/lua_test)
    if [[ "$response" == "Lua работает!" ]]; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

test_ssl_certificate() {
    echo -n "Testing SSL certificate... "
    local ssl_check=$(echo | openssl s_client -servername krea.acm-ai.ru -connect krea.acm-ai.ru:443 2>/dev/null | openssl x509 -noout -dates)
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

test_cookie_rewrite() {
    echo -n "Testing cookie domain rewrite... "
    local cookie_header=$(curl -I https://krea.acm-ai.ru/ 2>/dev/null | grep -i "set-cookie" | head -1)
    if [[ "$cookie_header" == *"Domain=krea.acm-ai.ru"* ]]; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  WARNING (no cookies found)${NC}"
        return 0
    fi
}

test_url_replacement() {
    echo -n "Testing URL replacement in body... "
    local response=$(curl -s https://krea.acm-ai.ru/ | grep -o "krea.acm-ai.ru" | head -1)
    if [[ "$response" == "krea.acm-ai.ru" ]]; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

test_cors_headers() {
    echo -n "Testing CORS headers... "
    local cors_headers=$(curl -I https://krea.acm-ai.ru/ 2>/dev/null | grep -i "access-control-allow")
    if [[ -n "$cors_headers" ]]; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

test_security_headers() {
    echo -n "Testing security headers... "
    local security_headers=$(curl -I https://krea.acm-ai.ru/ 2>/dev/null | grep -E "(X-Frame-Options|Content-Security-Policy)" | wc -l)
    if [[ "$security_headers" -ge 2 ]]; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

test_websocket_support() {
    echo -n "Testing WebSocket support... "
    local upgrade_header=$(curl -I https://krea.acm-ai.ru/ 2>/dev/null | grep -i "upgrade")
    if [[ -n "$upgrade_header" ]]; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  WARNING (no upgrade header found)${NC}"
        return 0
    fi
}

test_proxy_headers() {
    echo -n "Testing proxy headers... "
    local proxy_headers=$(curl -I https://krea.acm-ai.ru/ 2>/dev/null | grep -E "(X-Forwarded|X-Real-IP)" | wc -l)
    if [[ "$proxy_headers" -ge 2 ]]; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Main test execution
echo "Starting comprehensive proxy tests..."
echo "=================================="

tests=(
    "test_lua_working"
    "test_ssl_certificate"
    "test_cookie_rewrite"
    "test_url_replacement"
    "test_cors_headers"
    "test_security_headers"
    "test_websocket_support"
    "test_proxy_headers"
)

passed=0
total=${#tests[@]}

for test in "${tests[@]}"; do
    if $test; then
        ((passed++))
    fi
done

echo "=================================="
echo "Test Results: $passed/$total tests passed"

if [[ $passed -eq $total ]]; then
    echo -e "${GREEN}🎉 All tests passed! Proxy is working correctly.${NC}"
    echo ""
    echo "📋 Manual verification checklist:"
    echo "1. Visit https://krea.acm-ai.ru/krea-test.html"
    echo "2. Check DevTools → Network tab for requests to krea.acm-ai.ru"
    echo "3. Check DevTools → Application → Cookies for krea.acm-ai.ru domain"
    echo "4. Verify no Mixed Content errors in DevTools → Security"
    echo "5. Test login functionality in the iframe"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please check the configuration.${NC}"
    exit 1
fi 