FROM nginx:1.31-alpine

# Custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy static assets directly to Nginx document root
COPY public/ /usr/share/nginx/html/

# Entrypoint injects $API_URL into /env-config.js at container start
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
