# VPCの作成
resource "aws_vpc" "example_vpc" {
  cidr_block           = "10.0.0.0/16" # VPCのCIDRブロックを設定します
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# パブリックサブネットの作成
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-1a"
}

resource "aws_eip" "example_eip" {
  instance   = aws_instance.example_instance.id
  depends_on = [aws_internet_gateway.example_igw]
}

# パブリックサブネットのルートテーブル作成
resource "aws_route_table" "public_subnet_route" {
  vpc_id = aws_vpc.example_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example_igw.id
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_subnet_route.id
}

# インターネットゲートウェイの作成（Session Managerへの接続のために必要）
resource "aws_internet_gateway" "example_igw" {
  vpc_id = aws_vpc.example_vpc.id
}

# EC2インスタンスの作成
resource "aws_instance" "example_instance" {
  ami           = "ami-04beabd6a4fb6ab6f" # EC2インスタンスのAMI IDを設定します
  instance_type = "t2.micro"              # インスタンスタイプを設定します
  subnet_id     = aws_subnet.public_subnet.id

  # Systems Managerとsecret managerにアクセスするためのロール
  iam_instance_profile = aws_iam_instance_profile.test_profile.name
}