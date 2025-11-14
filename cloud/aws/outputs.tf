# AWS ECS Deployment Outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.monitoring.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.monitoring.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.monitoring.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.monitoring.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.monitoring.zone_id
}

output "grafana_url" {
  description = "URL to access Grafana"
  value       = "http://${aws_lb.monitoring.dns_name}/grafana/"
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = "http://${aws_lb.monitoring.dns_name}/prometheus/"
}

output "prometheus_service_name" {
  description = "Name of the Prometheus ECS service"
  value       = aws_ecs_service.prometheus.name
}

output "grafana_service_name" {
  description = "Name of the Grafana ECS service"
  value       = aws_ecs_service.grafana.name
}

output "efs_file_system_id" {
  description = "ID of the EFS file system for persistent storage"
  value       = aws_efs_file_system.monitoring.id
}

output "efs_dns_name" {
  description = "DNS name of the EFS file system"
  value       = aws_efs_file_system.monitoring.dns_name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for ECS tasks"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    environment         = var.environment
    region              = var.aws_region
    grafana_url         = "http://${aws_lb.monitoring.dns_name}/grafana/"
    prometheus_url      = "http://${aws_lb.monitoring.dns_name}/prometheus/"
    ecs_cluster         = aws_ecs_cluster.monitoring.name
    prometheus_replicas = var.prometheus_replica_count
    grafana_replicas    = var.grafana_replica_count
  }
}
