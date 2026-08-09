# MongoDB self-host (đã chốt để tiết kiệm ~$57/mo so với Atlas M10).
# ⚠️ STATEFUL: EC2 t4g.small riêng + EBS gp3 data volume + DLM snapshot daily.
# Auth bật; password TF sinh. CloudWatch agent theo dõi disk /var/lib/mongo.

terraform {
  required_providers {
    aws    = { source = "hashicorp/aws" }
    random = { source = "hashicorp/random" }
  }
}

variable "name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_id" { type = string }
variable "allowed_security_group_ids" { type = list(string) }
variable "instance_type" {
  type    = string
  default = "t4g.small"
}
variable "data_volume_gb" {
  type    = number
  default = 50
}
variable "snapshot_retain" {
  type    = number
  default = 7
}

resource "random_password" "mongo" {
  length  = 24
  special = false # tránh escape trong mongo URI
}

data "aws_ssm_parameter" "al2023_arm" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

data "aws_subnet" "target" {
  id = var.private_subnet_id
}

resource "aws_security_group" "this" {
  name        = "${var.name}-mongo"
  description = "MongoDB from ECS"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      description     = "MongoDB"
      from_port       = 27017
      to_port         = 27017
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Instance role: SSM (quản trị không cần SSH) + CloudWatch agent
data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name}-mongo"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cw_agent" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-mongo"
  role = aws_iam_role.this.name
}

locals {
  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    # ── MongoDB 8.0 repo (ARM64) ──
    cat > /etc/yum.repos.d/mongodb-org-8.0.repo <<'REPO'
    [mongodb-org-8.0]
    name=MongoDB Repository
    baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/8.0/aarch64/
    gpgcheck=1
    enabled=1
    gpgkey=https://pgp.mongodb.com/server-8.0.asc
    REPO
    dnf install -y mongodb-org amazon-cloudwatch-agent

    # ── Data volume (EBS attach /dev/sdf → nvme1n1) ──
    DEV=/dev/nvme1n1
    for i in $(seq 1 30); do [ -b "$DEV" ] && break; sleep 2; done
    if ! blkid "$DEV" >/dev/null 2>&1; then mkfs.xfs "$DEV"; fi
    mkdir -p /var/lib/mongo
    UUID=$(blkid -s UUID -o value "$DEV")
    grep -q "$UUID" /etc/fstab || echo "UUID=$UUID /var/lib/mongo xfs defaults,nofail 0 2" >> /etc/fstab
    mount -a
    chown -R mongod:mongod /var/lib/mongo

    # ── mongod config: bind all (private subnet + SG chặn), auth bật sau khi tạo user ──
    sed -i 's/^  bindIp:.*/  bindIp: 0.0.0.0/' /etc/mongod.conf
    systemctl enable --now mongod
    for i in $(seq 1 30); do mongosh --quiet --eval 'db.runCommand({ping:1})' >/dev/null 2>&1 && break; sleep 2; done

    mongosh admin --quiet --eval '
      if (db.getUser("syncapp") == null) {
        db.createUser({user: "syncapp", pwd: "${random_password.mongo.result}", roles: [{role: "root", db: "admin"}]});
      }'

    grep -q "^security:" /etc/mongod.conf || printf "\nsecurity:\n  authorization: enabled\n" >> /etc/mongod.conf
    systemctl restart mongod

    # ── CloudWatch agent: disk /var/lib/mongo + mem ──
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CW'
    {
      "metrics": {
        "namespace": "SyncMongo",
        "append_dimensions": {"InstanceId": "$${aws:InstanceId}"},
        "metrics_collected": {
          "disk": {"measurement": ["used_percent"], "resources": ["/var/lib/mongo"], "metrics_collection_interval": 60},
          "mem": {"measurement": ["mem_used_percent"], "metrics_collection_interval": 60}
        }
      }
    }
    CW
    systemctl enable --now amazon-cloudwatch-agent
  EOF
}

resource "aws_instance" "this" {
  ami                    = data.aws_ssm_parameter.al2023_arm.value
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = aws_iam_instance_profile.this.name
  user_data              = local.user_data

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 16
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name         = "${var.name}-mongo"
    dlm-snapshot = "${var.name}-mongo"
  }

  lifecycle {
    ignore_changes = [ami, user_data] # không recreate DB server khi AMI mới
  }
}

resource "aws_ebs_volume" "data" {
  availability_zone = data.aws_subnet.target.availability_zone
  size              = var.data_volume_gb
  type              = "gp3"
  encrypted         = true

  tags = {
    Name         = "${var.name}-mongo-data"
    dlm-snapshot = "${var.name}-mongo"
  }
}

resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.this.id
}

# ── DLM: snapshot EBS hằng ngày, giữ N bản ──
data "aws_iam_policy_document" "assume_dlm" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dlm" {
  name               = "${var.name}-mongo-dlm"
  assume_role_policy = data.aws_iam_policy_document.assume_dlm.json
}

resource "aws_iam_role_policy_attachment" "dlm" {
  role       = aws_iam_role.dlm.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

resource "aws_dlm_lifecycle_policy" "this" {
  description        = "${var.name} mongo daily snapshot"
  execution_role_arn = aws_iam_role.dlm.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]
    target_tags    = { dlm-snapshot = "${var.name}-mongo" }

    schedule {
      name = "daily"
      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["19:30"] # ~02:30 VN
      }
      retain_rule {
        count = var.snapshot_retain
      }
      copy_tags = true
    }
  }
}

# ── Alarms ──
resource "aws_cloudwatch_metric_alarm" "disk" {
  alarm_name          = "${var.name}-mongo-disk-high"
  namespace           = "SyncMongo"
  metric_name         = "disk_used_percent"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = aws_instance.this.id
    path       = "/var/lib/mongo"
    device     = "nvme1n1"
    fstype     = "xfs"
  }
  alarm_description  = "Mongo data disk >80% — mở rộng EBS hoặc dọn dữ liệu"
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "status" {
  alarm_name          = "${var.name}-mongo-status-check"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { InstanceId = aws_instance.this.id }
  alarm_description   = "Mongo EC2 status check failed"
}

output "private_ip" { value = aws_instance.this.private_ip }
output "instance_id" { value = aws_instance.this.id }
output "security_group_id" { value = aws_security_group.this.id }
output "password" {
  value     = random_password.mongo.result
  sensitive = true
}
output "username" { value = "syncapp" }
