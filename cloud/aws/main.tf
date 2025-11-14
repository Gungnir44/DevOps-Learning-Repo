# AWS ECS Deployment for Monitoring Stack
# This Terraform configuration deploys the monitoring stack to AWS ECS Fargate

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for state management
  backend "s3" {
    bucket         = "devops-monitoring-terraform-state"
    key            = "monitoring/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "DevOps-Monitoring"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "DevOps-Team"
    }
  }
}

# VPC for monitoring stack
resource "aws_vpc" "monitoring" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "monitoring-vpc-${var.environment}"
  }
}

# Public subnets
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.monitoring.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "monitoring-public-${var.availability_zones[count.index]}"
  }
}

# Private subnets
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.monitoring.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "monitoring-private-${var.availability_zones[count.index]}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.monitoring.id

  tags = {
    Name = "monitoring-igw-${var.environment}"
  }
}

# NAT Gateway
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "monitoring-nat-eip-${var.environment}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "monitoring-nat-${var.environment}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.monitoring.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "monitoring-public-rt-${var.environment}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.monitoring.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name = "monitoring-private-rt-${var.environment}"
  }
}

# Route table associations
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "alb" {
  name_description = "Security group for Application Load Balancer"
  vpc_id          = aws_vpc.monitoring.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "monitoring-alb-sg-${var.environment}"
  }
}

resource "aws_security_group" "ecs_tasks" {
  name_description = "Security group for ECS tasks"
  vpc_id          = aws_vpc.monitoring.id

  ingress {
    description     = "Allow from ALB"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Allow inter-task communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "monitoring-ecs-tasks-sg-${var.environment}"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "monitoring" {
  name = "monitoring-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "monitoring-cluster-${var.environment}"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/monitoring-${var.environment}"
  retention_in_days = 30

  tags = {
    Name = "monitoring-ecs-logs-${var.environment}"
  }
}

# Application Load Balancer
resource "aws_lb" "monitoring" {
  name               = "monitoring-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.environment == "production" ? true : false

  tags = {
    Name = "monitoring-alb-${var.environment}"
  }
}

# Target Groups
resource "aws_lb_target_group" "prometheus" {
  name        = "prometheus-tg-${var.environment}"
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = aws_vpc.monitoring.id
  target_type = "ip"

  health_check {
    path                = "/-/healthy"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "prometheus-tg-${var.environment}"
  }
}

resource "aws_lb_target_group" "grafana" {
  name        = "grafana-tg-${var.environment}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.monitoring.id
  target_type = "ip"

  health_check {
    path                = "/api/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "grafana-tg-${var.environment}"
  }
}

# ALB Listeners
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.monitoring.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# Listener rules
resource "aws_lb_listener_rule" "grafana" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }

  condition {
    path_pattern {
      values = ["/grafana*"]
    }
  }
}

resource "aws_lb_listener_rule" "prometheus" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus.arn
  }

  condition {
    path_pattern {
      values = ["/prometheus*"]
    }
  }
}

# IAM roles for ECS
resource "aws_iam_role" "ecs_task_execution" {
  name = "monitoring-ecs-task-execution-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "monitoring-ecs-task-execution-${var.environment}"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch permissions for ECS tasks
resource "aws_iam_role_policy" "ecs_cloudwatch" {
  name = "ecs-cloudwatch-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ]
        Resource = "${aws_cloudwatch_log_group.ecs.arn}:*"
      }
    ]
  })
}

# EFS for persistent storage
resource "aws_efs_file_system" "monitoring" {
  creation_token = "monitoring-efs-${var.environment}"
  encrypted      = true

  tags = {
    Name = "monitoring-efs-${var.environment}"
  }
}

resource "aws_efs_mount_target" "monitoring" {
  count           = length(aws_subnet.private)
  file_system_id  = aws_efs_file_system.monitoring.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.ecs_tasks.id]
}
