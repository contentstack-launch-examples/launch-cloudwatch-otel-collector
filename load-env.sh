#!/bin/bash

# Load Environment Variables Script
# This script loads AWS credentials from .env file

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
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

# Check if aws-env.sh file exists
if [ -f "aws-env.sh" ]; then
    echo_info "Loading environment variables from aws-env.sh file..."
    
    # Source the aws-env.sh file
    source aws-env.sh
    
    echo_info "Environment variables loaded!"
    
    # Test AWS credentials
    if aws sts get-caller-identity &> /dev/null; then
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
        AWS_USER=$(aws sts get-caller-identity --query Arn --output text)
        echo_info "✅ AWS credentials working: $AWS_USER (Account: $AWS_ACCOUNT)"
    else
        echo_error "❌ AWS credentials not working. Please check your aws-env.sh file."
        exit 1
    fi
else
    echo_error "aws-env.sh file not found!"
    echo_info "Please create aws-env.sh file from aws-env.example:"
    echo "  cp aws-env.example aws-env.sh"
    echo "  # Edit aws-env.sh with your AWS credentials"
    echo "  source aws-env.sh"
    exit 1
fi
