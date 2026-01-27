terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1" # 東京リージョン (必要に応じて変更してください)
}

locals {
  name_prefix = "otel-on-ec2-test"
}

# ------------------------------------------------------------
# 1. VPC & Networking
# ------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${local.name_prefix}-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"
  tags = { Name = "${local.name_prefix}-subnet" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${local.name_prefix}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${local.name_prefix}-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------
# 2. Security Group
# ------------------------------------------------------------
resource "aws_security_group" "main" {
  name        = "${local.name_prefix}-sg"
  description = "Allow Grafana and outbound traffic"
  vpc_id      = aws_vpc.main.id

  # Grafana UIへのアクセス (テスト用: 全開放)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # アウトバウンド (AMP API, SSM, Docker install等に必須)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------
# 3. IAM Role & Policies
# ------------------------------------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "${local.name_prefix}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# SSM接続用 (Session Manager)
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "main" {
  name = "${local.name_prefix}-profile"
  role = aws_iam_role.ec2_role.name
}

# ------------------------------------------------------------
# 5. EC2 Instance
# ------------------------------------------------------------
# 最新のAmazon Linux 2023 AMIを取得
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

resource "aws_instance" "main" {
  ami           = data.aws_ssm_parameter.al2023.value
  instance_type = "t3.small" # Grafanaを動かすためmicroよりsmall推奨
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.main.id]
  iam_instance_profile   = aws_iam_instance_profile.main.name

  # User Data: Dockerインストール -> Grafana起動
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user ssm-user
              mkdir -p /usr/local/lib/docker/cli-plugins
              curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m) -o /usr/local/lib/docker/cli-plugins/docker-compose
              chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
              EOF

  tags = { Name = "${local.name_prefix}-ec2" }
}

# ------------------------------------------------------------
# Outputs
# ------------------------------------------------------------
output "grafana_url" {
  description = "GrafanaへのアクセスURL"
  value       = "http://${aws_instance.main.public_ip}:3000"
}
