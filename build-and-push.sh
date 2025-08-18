#!/bin/bash

# Build and Push Docker Image to ECR
# This script builds the Docker image and pushes it to the ECR repository

set -e

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
ECR_REPOSITORY_NAME="launch-log-target"
IMAGE_TAG=${IMAGE_TAG:-latest}

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

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo_error "AWS CLI is not installed. Please install it first."
    echo "Installation instructions: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo_error "Docker is not installed. Please install it first."
    echo "Installation instructions: https://docs.docker.com/get-docker/"
    exit 1
fi

echo_info "Starting Docker build and push process..."

# Get AWS Account ID
echo_info "Getting AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ $? -ne 0 ]; then
    echo_error "Failed to get AWS Account ID. Please check your AWS credentials."
    exit 1
fi
echo_info "AWS Account ID: $AWS_ACCOUNT_ID"

# Construct ECR repository URL
ECR_REPOSITORY_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}"
echo_info "ECR Repository URL: $ECR_REPOSITORY_URL"

# Check if ECR repository exists
echo_info "Checking if ECR repository exists..."
if ! aws ecr describe-repositories --repository-names $ECR_REPOSITORY_NAME --region $AWS_REGION &> /dev/null; then
    echo_error "ECR repository '$ECR_REPOSITORY_NAME' does not exist in region '$AWS_REGION'."
    echo "Please run 'terraform apply' first to create the infrastructure."
    exit 1
fi
echo_info "ECR repository exists."

# Login to ECR
echo_info "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URL
if [ $? -ne 0 ]; then
    echo_error "Failed to login to ECR."
    exit 1
fi
echo_info "Successfully logged into ECR."

# Build Docker image
echo_info "Building Docker image for Linux platform..."
# Use buildx for cross-platform builds
docker buildx build --platform linux/amd64 --load -t $ECR_REPOSITORY_NAME:$IMAGE_TAG .
if [ $? -ne 0 ]; then
    echo_error "Failed to build Docker image."
    exit 1
fi
echo_info "Docker image built successfully."

# Tag image for ECR
echo_info "Tagging image for ECR..."
docker tag $ECR_REPOSITORY_NAME:$IMAGE_TAG $ECR_REPOSITORY_URL:$IMAGE_TAG
if [ $? -ne 0 ]; then
    echo_error "Failed to tag Docker image."
    exit 1
fi
echo_info "Image tagged successfully."

# Push image to ECR
echo_info "Pushing image to ECR..."
docker push $ECR_REPOSITORY_URL:$IMAGE_TAG
if [ $? -ne 0 ]; then
    echo_error "Failed to push Docker image to ECR."
    exit 1
fi
echo_info "Image pushed to ECR successfully!"

# Optional: Tag as latest if not already
if [ "$IMAGE_TAG" != "latest" ]; then
    echo_info "Also tagging as 'latest'..."
    docker tag $ECR_REPOSITORY_NAME:$IMAGE_TAG $ECR_REPOSITORY_URL:latest
    docker push $ECR_REPOSITORY_URL:latest
    echo_info "Latest tag pushed successfully!"
fi

echo_info "Build and push completed successfully!"
echo_info "Image URL: $ECR_REPOSITORY_URL:$IMAGE_TAG"

# Show image information
echo_info "Getting image information..."
aws ecr describe-images --repository-name $ECR_REPOSITORY_NAME --image-ids imageTag=$IMAGE_TAG --region $AWS_REGION --query 'imageDetails[0].[imagePushedAt,imageSizeInBytes]' --output table

echo_info "Done! You can now update your ECS service to use the new image."
