# VPC 2 AZ: public (ALB + NAT) / private (ECS + data). 1 NAT duy nhất để rẻ:
#   nat_mode = "instance" (t4g.nano, ~$4/mo, dev) | "gateway" (managed, prod).
# VPC endpoints: S3 + DynamoDB (gateway, free) luôn bật; interface endpoints
# (ECR/Logs/SSM/Secrets) tùy chọn — cắt data qua NAT nhưng ~$7.3/mo mỗi cái.

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "name" { type = string }
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "nat_mode" {
  type    = string
  default = "instance" # instance | gateway
  validation {
    condition     = contains(["instance", "gateway"], var.nat_mode)
    error_message = "nat_mode must be 'instance' or 'gateway'."
  }
}
variable "enable_interface_endpoints" {
  type    = bool
  default = false
}
variable "region" { type = string }

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs            = slice(data.aws_availability_zones.available.names, 0, 2)
  public_cidrs   = [cidrsubnet(var.vpc_cidr, 8, 0), cidrsubnet(var.vpc_cidr, 8, 1)]
  private_cidrs  = [cidrsubnet(var.vpc_cidr, 8, 10), cidrsubnet(var.vpc_cidr, 8, 11)]
  interface_svcs = ["ecr.api", "ecr.dkr", "logs", "ssm", "secretsmanager"]
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.name }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = var.name }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name}-public-${count.index}", tier = "public" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_cidrs[count.index]
  availability_zone = local.azs[count.index]
  tags              = { Name = "${var.name}-private-${count.index}", tier = "private" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-public" }
}

resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 1 route table private chung (1 NAT — chấp nhận single-AZ NAT để rẻ)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-private" }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ── NAT Gateway (prod) ───────────────────────────────────────────────────────
resource "aws_eip" "nat" {
  count  = var.nat_mode == "gateway" ? 1 : 0
  domain = "vpc"
  tags   = { Name = "${var.name}-nat" }
}

resource "aws_nat_gateway" "this" {
  count         = var.nat_mode == "gateway" ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Name = var.name }
  depends_on    = [aws_internet_gateway.this]
}

resource "aws_route" "private_natgw" {
  count                  = var.nat_mode == "gateway" ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

# ── NAT instance (dev, t4g.nano ~$4/mo) ─────────────────────────────────────
data "aws_ssm_parameter" "al2023_arm" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

resource "aws_security_group" "nat_instance" {
  count       = var.nat_mode == "instance" ? 1 : 0
  name        = "${var.name}-nat-instance"
  description = "NAT instance - allow all from VPC"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "All from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nat" {
  count                       = var.nat_mode == "instance" ? 1 : 0
  ami                         = data.aws_ssm_parameter.al2023_arm.value
  instance_type               = "t4g.nano"
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.nat_instance[0].id]
  associate_public_ip_address = true
  source_dest_check           = false

  user_data = <<-EOF
    #!/bin/bash
    set -e
    sysctl -w net.ipv4.ip_forward=1
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-nat.conf
    IFACE=$(ip route show default | awk '{print $5}' | head -1)
    dnf install -y iptables-services
    iptables -t nat -A POSTROUTING -o "$IFACE" -j MASQUERADE
    service iptables save || iptables-save > /etc/sysconfig/iptables
    systemctl enable --now iptables
  EOF

  tags = { Name = "${var.name}-nat-instance" }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_route" "private_nat_instance" {
  count                  = var.nat_mode == "instance" ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat[0].primary_network_interface_id
}

# ── VPC Endpoints ────────────────────────────────────────────────────────────
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id, aws_route_table.public.id]
  tags              = { Name = "${var.name}-s3" }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = { Name = "${var.name}-dynamodb" }
}

resource "aws_security_group" "endpoints" {
  count       = var.enable_interface_endpoints ? 1 : 0
  name        = "${var.name}-vpc-endpoints"
  description = "HTTPS from VPC to interface endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each            = var.enable_interface_endpoints ? toset(local.interface_svcs) : []
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoints[0].id]
  private_dns_enabled = true
  tags                = { Name = "${var.name}-${each.value}" }
}

output "vpc_id" { value = aws_vpc.this.id }
output "vpc_cidr" { value = var.vpc_cidr }
output "public_subnet_ids" { value = aws_subnet.public[*].id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }
