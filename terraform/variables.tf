variable "aws_region" {
  description = "The AWS region to create resources in"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for HTTPS listener (required)"
  type        = string
}

variable "domain_name" {
  description = "Domain name for SSL certificate (must be a domain you own for ACM public certificate)"
  type        = string
  default     = "otel-collector.example.com"
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS validation (leave empty if not using Route53)"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  type        = number
  default     = 256
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  type        = number
  default     = 512
}

variable "app_count" {
  description = "Number of docker containers to run"
  type        = number
  default     = 1
}
