output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.launch_log_target.repository_url
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.launch_log_target_vpc.id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.launch_grpc_log_target_alb.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.launch_grpc_log_target_alb.zone_id
}

output "grpc_endpoint" {
  description = "Secure gRPC endpoint for the OpenTelemetry collector"
  value       = "https://${aws_lb.launch_grpc_log_target_alb.dns_name}:443"
}

output "ssl_certificate_arn" {
  description = "ARN of the SSL certificate used"
  value       = local.certificate_arn
}

output "certificate_type" {
  description = "Type of certificate being used"
  value       = "provided"
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.launch_log_target_grpc_service.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for ECS logs"
  value       = aws_cloudwatch_log_group.ecs_logs.name
}
