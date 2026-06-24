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

  ingress {
    description = "Allow all traffic from private CIDRs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8", "192.178.0.0/16"]
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
  instance_type = "c5.2xlarge"
  key_name      = "prab-key-pair"

  instance_market_options {
    market_type = "spot"
  }



  subnet_id     = module.inspection_vpc.public_subnets[0]

  vpc_security_group_ids = [aws_security_group.bastion.id]

  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  user_data = file("${path.module}/bastion-init.sh")
  user_data_replace_on_change = true




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


resource "aws_iam_role" "bastion" {
  name = "bastion-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "bastion-server-role"
  })
}


resource "aws_iam_policy" "bastion_s3" {
  name        = "bastion-s3-logs-read-policy"
  description = "Allows Bastion host to read logs from prab-infrastrcuture-logs bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::prab-infrastrcuture-logs",
          "arn:aws:s3:::prab-infrastrcuture-logs/*"
        ]
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "bastion-s3-logs-read-policy"
  })
}


resource "aws_iam_role_policy_attachment" "bastion_s3" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.bastion_s3.arn
}


resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_instance_profile" "bastion" {
  name = "bastion-server-instance-profile"
  role = aws_iam_role.bastion.name

  tags = merge(local.common_tags, {
    Name = "bastion-server-instance-profile"
  })
}