#!/bin/bash
# ==============================================================================
# bastion-init.sh — Centralized monitoring bootstrap script for Bastion host
# ==============================================================================
set -euo pipefail

# 1. System updates and Docker installation
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user
chkconfig docker on

# 2. Network configuration
docker network create monitoring || true

# 3. Create Nginx reverse proxy configuration
mkdir -p /opt/nginx
cat << 'NGINX_CONF' > /opt/nginx/nginx.conf
events {}
http {
    server {
        listen 80;

        location /prometheus/ {
            proxy_pass http://prometheus:9090;
        }

        location /grafana/ {
            proxy_set_header Host $http_host;
            proxy_pass http://grafana:3000;
        }

        location /jaeger/ {
            proxy_pass http://jaeger:16686;
        }

        location /loki/ {
            proxy_pass http://loki:3100/;
        }
        
        location / {
            return 301 /grafana/;
        }
    }
}
NGINX_CONF

# 4. Start Prometheus with remote write enabled
docker run -d --name prometheus --restart always --network monitoring \
  prom/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --web.console.libraries=/usr/share/prometheus/console_libraries \
  --web.console.templates=/usr/share/prometheus/consoles \
  --web.external-url=/prometheus/ \
  --web.enable-remote-write-receiver

# 5. Create Grafana datasources provisioning configuration
mkdir -p /opt/grafana/provisioning/datasources
cat << 'GRAFANA_DS' > /opt/grafana/provisioning/datasources/datasources.yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    editable: true
  - name: Jaeger
    type: jaeger
    access: proxy
    url: http://jaeger:16686
    editable: true
GRAFANA_DS

# 6. Start Grafana with mounted provisioning configs
docker run -d --name grafana --restart always --network monitoring \
  -e "GF_SERVER_ROOT_URL=%(protocol)s://%(domain)s:%(http_port)s/grafana/" \
  -e "GF_SERVER_SERVE_FROM_SUB_PATH=true" \
  -v /opt/grafana/provisioning/datasources:/etc/grafana/provisioning/datasources:ro \
  grafana/grafana

# 7. Start Jaeger all-in-one with telemetry ingest ports exposed
docker run -d --name jaeger --restart always --network monitoring \
  -p 4317:4317 -p 4318:4318 -p 14250:14250 -p 14268:14268 -p 9411:9411 \
  -e "QUERY_BASE_PATH=/jaeger" \
  jaegertracing/all-in-one:latest

# 8. Start Loki for log aggregation
docker run -d --name loki --restart always --network monitoring \
  grafana/loki:latest

# 9. Start Nginx reverse proxy
docker run -d --name nginx --restart always --network monitoring -p 80:80 \
  -v /opt/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
  nginx
