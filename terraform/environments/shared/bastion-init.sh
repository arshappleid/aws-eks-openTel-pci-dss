#!/bin/bash

set -euo pipefail


yum update -y
yum install git -y
amazon-linux-extras install docker -y
amazon-linux-extras install ansible2 -y
service docker start
usermod -a -G docker ec2-user
chkconfig docker on


curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose


docker network create monitoring || true


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


docker run -d --name prometheus --restart always --network monitoring \
  prom/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --web.console.libraries=/usr/share/prometheus/console_libraries \
  --web.console.templates=/usr/share/prometheus/consoles \
  --web.external-url=/prometheus/ \
  --web.enable-remote-write-receiver


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


mkdir -p /opt/grafana/provisioning/dashboards
mkdir -p /opt/grafana/provisioning/alerting


git clone https://github.com/arshappleid/aws-eks-openTel-pci-dss.git /opt/aws-eks-openTel-pci-dss

cp /opt/aws-eks-openTel-pci-dss/terraform/environments/shared/grafana/dashboards.yaml /opt/grafana/provisioning/dashboards/dashboards.yaml
cp /opt/aws-eks-openTel-pci-dss/terraform/environments/shared/grafana/eks-infrastructure.json /opt/grafana/provisioning/dashboards/eks-infrastructure.json
cp /opt/aws-eks-openTel-pci-dss/terraform/environments/shared/grafana/application-performance.json /opt/grafana/provisioning/dashboards/application-performance.json
cp /opt/aws-eks-openTel-pci-dss/terraform/environments/shared/grafana/log-analytics.json /opt/grafana/provisioning/dashboards/log-analytics.json


EMAILS=$(cat /opt/aws-eks-openTel-pci-dss/terraform/environments/shared/grafana/alert-emails.txt | tr -d '\n\r')
sed "s/\${emails}/$EMAILS/g" /opt/aws-eks-openTel-pci-dss/terraform/environments/shared/grafana/alerting.yaml > /opt/grafana/provisioning/alerting/alerting.yaml



docker run -d --name grafana --restart always --network monitoring \
  -e "GF_SERVER_ROOT_URL=%(protocol)s://%(domain)s:%(http_port)s/grafana/" \
  -e "GF_SERVER_SERVE_FROM_SUB_PATH=true" \
  -v /opt/grafana/provisioning:/etc/grafana/provisioning:ro \
  grafana/grafana



docker run -d --name jaeger --restart always --network monitoring \
  -p 4317:4317 -p 4318:4318 -p 14250:14250 -p 14268:14268 -p 9411:9411 \
  -e "QUERY_BASE_PATH=/jaeger" \
  jaegertracing/all-in-one:latest


docker run -d --name loki --restart always --network monitoring \
  grafana/loki:latest


docker run -d --name nginx --restart always --network monitoring -p 80:80 \
  -v /opt/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
  nginx
