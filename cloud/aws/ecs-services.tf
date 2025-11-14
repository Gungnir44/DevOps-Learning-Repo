# ECS Task Definitions and Services for Monitoring Stack

# Prometheus ECS Task Definition
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "prometheus-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.prometheus_cpu
  memory                   = var.prometheus_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "prometheus"
      image     = "prom/prometheus:latest"
      essential = true

      portMappings = [
        {
          containerPort = 9090
          protocol      = "tcp"
        }
      ]

      command = [
        "--config.file=/etc/prometheus/prometheus.yml",
        "--storage.tsdb.path=/prometheus",
        "--web.console.libraries=/etc/prometheus/console_libraries",
        "--web.console.templates=/etc/prometheus/consoles",
        "--web.enable-lifecycle",
        "--storage.tsdb.retention.time=30d"
      ]

      mountPoints = [
        {
          sourceVolume  = "prometheus-data"
          containerPath = "/prometheus"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "prometheus"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:9090/-/healthy || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  volume {
    name = "prometheus-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.monitoring.id
      root_directory     = "/prometheus"
      transit_encryption = "ENABLED"
    }
  }

  tags = {
    Name = "prometheus-task-${var.environment}"
  }
}

# Prometheus ECS Service
resource "aws_ecs_service" "prometheus" {
  name            = "prometheus-${var.environment}"
  cluster         = aws_ecs_cluster.monitoring.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = var.prometheus_replica_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.prometheus.arn
    container_name   = "prometheus"
    container_port   = 9090
  }

  depends_on = [
    aws_lb_listener.http,
    aws_efs_mount_target.monitoring
  ]

  tags = {
    Name = "prometheus-service-${var.environment}"
  }
}

# Grafana ECS Task Definition
resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.grafana_cpu
  memory                   = var.grafana_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "grafana"
      image     = "grafana/grafana:latest"
      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "GF_SERVER_ROOT_URL"
          value = "%(protocol)s://%(domain)s:%(http_port)s/grafana/"
        },
        {
          name  = "GF_SERVER_SERVE_FROM_SUB_PATH"
          value = "true"
        },
        {
          name  = "GF_SECURITY_ADMIN_USER"
          value = var.grafana_admin_user
        },
        {
          name  = "GF_SECURITY_ADMIN_PASSWORD"
          value = var.grafana_admin_password
        },
        {
          name  = "GF_INSTALL_PLUGINS"
          value = "grafana-clock-panel,grafana-simple-json-datasource"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "grafana-data"
          containerPath = "/var/lib/grafana"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "grafana"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  volume {
    name = "grafana-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.monitoring.id
      root_directory     = "/grafana"
      transit_encryption = "ENABLED"
    }
  }

  tags = {
    Name = "grafana-task-${var.environment}"
  }
}

# Grafana ECS Service
resource "aws_ecs_service" "grafana" {
  name            = "grafana-${var.environment}"
  cluster         = aws_ecs_cluster.monitoring.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = var.grafana_replica_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_listener.http,
    aws_efs_mount_target.monitoring
  ]

  tags = {
    Name = "grafana-service-${var.environment}"
  }
}

# Auto Scaling for Prometheus
resource "aws_appautoscaling_target" "prometheus" {
  max_capacity       = var.prometheus_max_replicas
  min_capacity       = var.prometheus_min_replicas
  resource_id        = "service/${aws_ecs_cluster.monitoring.name}/${aws_ecs_service.prometheus.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "prometheus_cpu" {
  name               = "prometheus-cpu-autoscaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.prometheus.resource_id
  scalable_dimension = aws_appautoscaling_target.prometheus.scalable_dimension
  service_namespace  = aws_appautoscaling_target.prometheus.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Auto Scaling for Grafana
resource "aws_appautoscaling_target" "grafana" {
  max_capacity       = var.grafana_max_replicas
  min_capacity       = var.grafana_min_replicas
  resource_id        = "service/${aws_ecs_cluster.monitoring.name}/${aws_ecs_service.grafana.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "grafana_cpu" {
  name               = "grafana-cpu-autoscaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.grafana.resource_id
  scalable_dimension = aws_appautoscaling_target.grafana.scalable_dimension
  service_namespace  = aws_appautoscaling_target.grafana.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
