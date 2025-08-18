#!/bin/bash

# Validate Setup Script
# This script validates the setup before deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

echo_error() {
    echo -e "${RED}[✗]${NC} $1"
}

echo_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

VALIDATION_PASSED=true

validate_prerequisites() {
    echo_check "Validating prerequisites..."
    
    # Check Terraform
    if command -v terraform &> /dev/null; then
        TERRAFORM_VERSION=$(terraform version -json | grep '"terraform_version"' | cut -d '"' -f 4)
        echo_info "Terraform installed: v$TERRAFORM_VERSION"
    else
        echo_error "Terraform is not installed"
        VALIDATION_PASSED=false
    fi
    
    # Check AWS CLI
    if command -v aws &> /dev/null; then
        AWS_VERSION=$(aws --version 2>&1 | cut -d ' ' -f 1)
        echo_info "AWS CLI installed: $AWS_VERSION"
        
        # Check AWS credentials
        if aws sts get-caller-identity &> /dev/null; then
            AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
            AWS_USER=$(aws sts get-caller-identity --query Arn --output text)
            echo_info "AWS credentials configured: $AWS_USER (Account: $AWS_ACCOUNT)"
        else
            echo_error "AWS credentials not configured"
            VALIDATION_PASSED=false
        fi
    else
        echo_error "AWS CLI is not installed"
        VALIDATION_PASSED=false
    fi
    
    # Check Docker
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null; then
            DOCKER_VERSION=$(docker version --format '{{.Server.Version}}')
            echo_info "Docker installed and running: v$DOCKER_VERSION"
        else
            echo_error "Docker is installed but not running"
            VALIDATION_PASSED=false
        fi
    else
        echo_error "Docker is not installed"
        VALIDATION_PASSED=false
    fi
}

validate_files() {
    echo_check "Validating required files..."
    
    # Required files
    REQUIRED_FILES=(
        "Dockerfile"
        "otelcol-config.yaml"
        "terraform/main.tf"
        "terraform/variables.tf"
        "terraform/outputs.tf"
        "build-and-push.sh"
        "deploy.sh"
        "terraform.tfvars.example"
    )
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$file" ]; then
            echo_info "File exists: $file"
        else
            echo_error "Missing required file: $file"
            VALIDATION_PASSED=false
        fi
    done
    
    # Check if scripts are executable
    EXECUTABLE_FILES=(
        "build-and-push.sh"
        "deploy.sh"
        "update-service.sh"
    )
    
    for file in "${EXECUTABLE_FILES[@]}"; do
        if [ -x "$file" ]; then
            echo_info "Script is executable: $file"
        else
            echo_warn "Script is not executable: $file (will be fixed)"
            chmod +x "$file"
        fi
    done
}

validate_terraform() {
    echo_check "Validating Terraform configuration..."
    
    cd terraform
    
    # Check if terraform can be initialized
    if terraform init -backend=false &> /dev/null; then
        echo_info "Terraform configuration is valid"
    else
        echo_error "Terraform configuration has errors"
        VALIDATION_PASSED=false
    fi
    
    # Check if variables file exists
    if [ -f "../terraform.tfvars.example" ]; then
        echo_info "Variables example file exists"
        if [ ! -f "terraform.tfvars" ]; then
            echo_warn "terraform.tfvars not found. Copy from terraform.tfvars.example and customize"
        else
            echo_info "terraform.tfvars exists"
        fi
    fi
    
    cd ..
}

validate_docker() {
    echo_check "Validating Docker configuration..."
    
    # Check if Dockerfile exists and has required components
    if [ -f "Dockerfile" ]; then
        if grep -q "EXPOSE 4317" Dockerfile; then
            echo_info "Dockerfile exposes port 4317"
        else
            echo_warn "Dockerfile doesn't explicitly expose port 4317"
        fi
        
        if grep -q "otelcol-config.yaml" Dockerfile; then
            echo_info "Dockerfile references OpenTelemetry config"
        else
            echo_error "Dockerfile doesn't reference otelcol-config.yaml"
            VALIDATION_PASSED=false
        fi
    fi
    
    # Check OpenTelemetry config
    if [ -f "otelcol-config.yaml" ]; then
        if grep -q "4317" otelcol-config.yaml; then
            echo_info "OpenTelemetry config uses port 4317"
        else
            echo_warn "OpenTelemetry config doesn't specify port 4317"
        fi
        
        if grep -q "awscloudwatchlogs" otelcol-config.yaml; then
            echo_info "OpenTelemetry config has CloudWatch exporter"
        else
            echo_warn "OpenTelemetry config missing CloudWatch exporter"
        fi
    fi
}

validate_aws_permissions() {
    echo_check "Validating AWS permissions (basic check)..."
    
    # Check basic AWS permissions
    REQUIRED_PERMISSIONS=(
        "ec2:DescribeVpcs"
        "ecs:ListClusters"
        "ecr:DescribeRepositories"
        "iam:ListRoles"
        "logs:DescribeLogGroups"
    )
    
    # Simple check - try to list resources
    if aws ec2 describe-vpcs --max-items 1 &> /dev/null; then
        echo_info "EC2 permissions appear to be working"
    else
        echo_warn "EC2 permissions might be limited"
    fi
    
    if aws ecs list-clusters --max-items 1 &> /dev/null; then
        echo_info "ECS permissions appear to be working"
    else
        echo_warn "ECS permissions might be limited"
    fi
    
    if aws ecr describe-repositories --max-items 1 &> /dev/null; then
        echo_info "ECR permissions appear to be working"
    else
        echo_warn "ECR permissions might be limited"
    fi
}

show_deployment_steps() {
    echo ""
    echo "=========================================="
    echo "🚀 DEPLOYMENT STEPS"
    echo "=========================================="
    echo "1. Configure variables (optional):"
    echo "   cp terraform.tfvars.example terraform.tfvars"
    echo "   # Edit terraform.tfvars with your preferences"
    echo ""
    echo "2. Quick deployment (recommended):"
    echo "   ./deploy.sh"
    echo ""
    echo "3. Manual deployment:"
    echo "   cd terraform && terraform init && terraform apply"
    echo "   ./build-and-push.sh"
    echo "   ./update-service.sh"
    echo ""
    echo "4. Test the deployment:"
    echo "   # Get ALB DNS from terraform output"
    echo "   # Send test requests to http://<ALB-DNS>/"
    echo ""
    echo "5. Monitor logs:"
    echo "   aws logs tail /ecs/launch-log-target --follow"
    echo "=========================================="
}

# Main validation
main() {
    echo "🔍 Launch OpenTelemetry Log Target - Setup Validation"
    echo "======================================================"
    echo ""
    
    validate_prerequisites
    echo ""
    validate_files
    echo ""
    validate_terraform
    echo ""
    validate_docker
    echo ""
    validate_aws_permissions
    echo ""
    
    if [ "$VALIDATION_PASSED" = true ]; then
        echo_info "✅ All validations passed! Setup is ready for deployment."
        show_deployment_steps
    else
        echo_error "❌ Some validations failed. Please fix the issues above before deploying."
        exit 1
    fi
}

# Run validation
main "$@"
