# Dockerfile for Krea.ai Reverse Proxy
# Based on OpenResty official image

FROM openresty/openresty:alpine

# Install required packages
RUN apk add --no-cache \
    curl \
    openssl \
    certbot \
    python3 \
    py3-pip \
    && pip3 install certbot-nginx

# Create necessary directories
RUN mkdir -p /etc/nginx/lua \
    && mkdir -p /var/log/nginx \
    && mkdir -p /etc/letsencrypt/live/krea.acm-ai.ru

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY lua/cookie_filter.lua /etc/nginx/lua/
COPY lua/body_filter.lua /etc/nginx/lua/

# Copy scripts
COPY scripts/ /opt/scripts/
RUN chmod +x /opt/scripts/*.sh

# Set permissions
RUN chown -R nginx:nginx /etc/nginx/lua \
    && chmod 755 /etc/nginx/lua \
    && chmod 644 /etc/nginx/lua/*.lua

# Create health check script
RUN echo '#!/bin/sh' > /usr/local/bin/healthcheck.sh \
    && echo 'curl -f http://localhost/lua_test || exit 1' >> /usr/local/bin/healthcheck.sh \
    && chmod +x /usr/local/bin/healthcheck.sh

# Expose ports
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

# Start OpenResty
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"] 