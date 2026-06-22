data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = module.inspection_vpc.vpc_id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Nginx HTTP Reverse Proxy"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "bastion-sg"
  })
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  instance_market_options {
    market_type = "spot"
  }
  
  # Deploy to the first public subnet of the shared inspection VPC
  subnet_id     = module.inspection_vpc.public_subnets[0]

  vpc_security_group_ids = [aws_security_group.bastion.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              chkconfig docker on

              docker network create monitoring

              # Create Nginx config
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
                      
                      location / {
                          return 301 /grafana/;
                      }
                  }
              }
              NGINX_CONF

              # Start Prometheus with subpath
              docker run -d --name prometheus --restart always --network monitoring \
                prom/prometheus \
                --config.file=/etc/prometheus/prometheus.yml \
                --storage.tsdb.path=/prometheus \
                --web.console.libraries=/usr/share/prometheus/console_libraries \
                --web.console.templates=/usr/share/prometheus/consoles \
                --web.external-url=/prometheus/

              # Start Grafana with subpath
              docker run -d --name grafana --restart always --network monitoring \
                -e "GF_SERVER_ROOT_URL=%(protocol)s://%(domain)s:%(http_port)s/grafana/" \
                -e "GF_SERVER_SERVE_FROM_SUB_PATH=true" \
                grafana/grafana

              # Start Jaeger all-in-one with subpath
              docker run -d --name jaeger --restart always --network monitoring \
                -e "QUERY_BASE_PATH=/jaeger" \
                jaegertracing/all-in-one:latest

              # Start Nginx
              docker run -d --name nginx --restart always --network monitoring -p 80:80 \
                -v /opt/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
                nginx
              EOF

  tags = merge(local.common_tags, {
    Name = "bastion-server"
  })
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = merge(local.common_tags, {
    Name = "bastion-eip"
  })
}
