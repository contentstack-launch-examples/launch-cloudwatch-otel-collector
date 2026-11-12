#!/bin/bash

# Complete deployment script for Launch OpenTelemetry Log Target
# This script handles the complete deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    echo_step "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        echo_error "Terraform is not installed. Please install it first."
        echo "Installation instructions: https://learn.hashicorp.com/tutorials/terraform/install-cli"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        echo_error "AWS CLI is not installed. Please install it first."
        echo "Installation instructions: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        echo_error "Docker is not installed. Please install it first."
        echo "Installation instructions: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    echo_info "All prerequisites met."
}

# Deploy infrastructure
deploy_infrastructure() {
    echo_step "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    echo_info "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    echo_info "Planning Terraform deployment..."
    terraform plan
    
    # Apply deployment
    echo_info "Applying Terraform deployment..."
    terraform apply -auto-approve
    
    # Get outputs
    echo_info "Getting Terraform outputs..."
    ECR_URL=$(terraform output -raw ecr_repository_url)
    ALB_DNS=$(terraform output -raw alb_dns_name)
    
    cd ..
    
    echo_info "Infrastructure deployed successfully!"
    echo_info "ECR Repository: $ECR_URL"
    echo_info "Load Balancer DNS: $ALB_DNS"
}

# Build and push Docker image
build_and_push_image() {
    echo_step "Building and pushing Docker image..."
    
    chmod +x build-and-push.sh
    ./build-and-push.sh
    
    echo_info "Docker image built and pushed successfully!"
}

# Update ECS service
update_ecs_service() {
    echo_step "Updating ECS service..."
    
    cd terraform
    
    # Force new deployment of ECS service
    echo_info "Forcing new deployment of ECS service..."
    aws ecs update-service \
        --cluster $(terraform output -raw ecs_cluster_name) \
        --service $(terraform output -raw ecs_service_name) \
        --force-new-deployment
    
    cd ..
    
    echo_info "ECS service update initiated!"
}

# Main deployment function
main() {
    echo_info "Starting deployment of Launch OpenTelemetry Log Target..."
    echo_info "This will create AWS infrastructure and deploy the application."
    
    # Check if user wants to proceed
    read -p "Do you want to proceed with the deployment? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo_info "Deployment cancelled."
        exit 0
    fi
    
    check_prerequisites
    deploy_infrastructure
    build_and_push_image
    update_ecs_service
    
    echo_info "🎉 Deployment completed successfully!"
    
    # Show final information
    cd terraform
    echo ""
    echo "=========================================="
    echo "Deployment Summary:"
    echo "=========================================="
    echo "ECR Repository: $(terraform output -raw ecr_repository_url)"
    echo "Load Balancer DNS: $(terraform output -raw alb_dns_name)"
    echo "ECS Cluster: $(terraform output -raw ecs_cluster_name)"
    echo "ECS Service: $(terraform output -raw ecs_service_name)"
    echo "CloudWatch Log Group: $(terraform output -raw cloudwatch_log_group)"
    echo "=========================================="
    echo ""
    echo "Your OpenTelemetry Log Target is now deployed!"
    echo "You can send OTLP gRPC requests to: http://$(terraform output -raw alb_dns_name)"
    echo ""
    echo "To monitor logs: aws logs tail $(terraform output -raw cloudwatch_log_group) --follow"
    echo "To destroy resources: cd terraform && terraform destroy"
}

# Run main function
main "$@"
