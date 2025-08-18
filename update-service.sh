#!/bin/bash

# Update ECS Service Script
# This script updates the ECS service to use the latest Docker image

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if terraform directory exists
if [ ! -d "terraform" ]; then
    echo_error "terraform directory not found. Please run this script from the project root."
    exit 1
fi

cd terraform

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo_error "Terraform not initialized. Please run 'terraform init' first."
    exit 1
fi

echo_info "Updating ECS service..."

# Get cluster and service names from terraform outputs
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null)
SERVICE_NAME=$(terraform output -raw ecs_service_name 2>/dev/null)

if [ -z "$CLUSTER_NAME" ] || [ -z "$SERVICE_NAME" ]; then
    echo_error "Could not get cluster or service name from terraform outputs."
    echo "Make sure terraform has been applied successfully."
    exit 1
fi

echo_info "Cluster: $CLUSTER_NAME"
echo_info "Service: $SERVICE_NAME"

# Force new deployment
echo_info "Forcing new deployment..."
aws ecs update-service \
    --cluster "$CLUSTER_NAME" \
    --service "$SERVICE_NAME" \
    --force-new-deployment \
    --output table

if [ $? -eq 0 ]; then
    echo_info "ECS service update initiated successfully!"
    echo_info "Monitor the deployment:"
    echo "  aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME"
else
    echo_error "Failed to update ECS service."
    exit 1
fi

# Wait for deployment to stabilize (optional)
read -p "Do you want to wait for the deployment to complete? (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo_info "Waiting for deployment to complete..."
    aws ecs wait services-stable \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME"
    
    if [ $? -eq 0 ]; then
        echo_info "✅ Deployment completed successfully!"
    else
        echo_warn "⚠️  Deployment may still be in progress. Check the AWS Console for details."
    fi
fi

echo_info "Done!"
