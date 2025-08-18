# 🚀 Complete Setup Guide

Detailed step-by-step guide for deploying the OpenTelemetry gRPC Collector with secure HTTPS.

## 📋 Prerequisites

**Required Tools:**
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- [Terraform](https://terraform.io/) >= 1.0
- [Docker](https://docker.com/) for building images
- SSL Certificate in AWS Certificate Manager

**AWS Permissions Required:**
- EC2 (VPC, Security Groups, Load Balancer)
- ECS (Clusters, Services, Task Definitions)
- ECR (Repository management)
- IAM (Role and Policy management)
- CloudWatch (Log Groups)
- Certificate Manager (if creating certificates)

## 🔐 Step 1: SSL Certificate Setup

Choose one of these options:

### Option A: Use Existing Certificate (Quickest)
```bash
# List your certificates
aws acm list-certificates --region us-east-1

# Note the ARN of your certificate
```

### Option B: Get FREE Certificate with ACM
**For Route53 domains (automatic validation):**
```bash
# Get your hosted zone ID
aws route53 list-hosted-zones --query 'HostedZones[?Name==`yourdomain.com.`].Id' --output text
```

**For external domains:** Manual DNS validation required after deployment.

📖 **Detailed certificate guide:** [docs/CERTIFICATES.md](docs/CERTIFICATES.md)

## 🔧 Step 2: AWS Credentials

Choose your preferred method:

### Option A: Environment File (Recommended)
```bash
# Copy the template
cp aws-credentials.example aws-env.sh

# Edit with your credentials (never commit this file!)
nano aws-env.sh

# Load credentials
source aws-env.sh

# Verify access
aws sts get-caller-identity
```

### Option B: AWS CLI Profile
```bash
aws configure --profile otel-project
export AWS_PROFILE=otel-project
```

### Option C: IAM Roles (Production)
```bash
# For EC2/ECS with IAM roles attached
# No manual configuration needed
```

## ⚙️ Step 3: Configure Terraform

### Create Your Configuration
```bash
# Copy the example file
cp terraform.tfvars.example terraform/terraform.tfvars

# Edit with your values
nano terraform/terraform.tfvars
```

### Required Configuration
```hcl
# REQUIRED: Your SSL certificate ARN
ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/your-cert-id"

# Your AWS region
aws_region = "us-east-1"
```

### Optional Customizations
```hcl
# Environment tag
environment = "prod"

# Resource sizing
fargate_cpu    = 512   # 0.5 vCPU (256, 512, 1024, 2048, 4096)
fargate_memory = 1024  # 1GB RAM (must match CPU ratios)

# High availability
app_count = 2  # Number of tasks to run

# Network configuration
vpc_cidr = "10.0.0.0/16"  # VPC IP range
```

**💡 Resource Sizing Guide:**
- **Development:** 256 CPU, 512 Memory, 1 task
- **Production:** 512 CPU, 1024 Memory, 2+ tasks  
- **High Traffic:** 1024+ CPU, 2048+ Memory, 3+ tasks

## 🏗️ Step 4: Deploy Infrastructure

### Initialize Terraform
```bash
cd terraform

# Download providers and modules
terraform init

# Optional: create workspace for environment isolation
terraform workspace new production
```

### Plan and Review
```bash
# See what will be created
terraform plan

# Save the plan for approval workflows
terraform plan -out=terraform.tfplan
```

### Deploy Resources
```bash
# Apply the configuration
terraform apply

# Or apply saved plan
terraform apply terraform.tfplan
```

**⏱️ Deployment time:** 5-10 minutes

### What Gets Created
- **VPC** with public/private subnets across 2 AZs
- **Security Groups** with least-privilege access
- **Application Load Balancer** with HTTPS listener
- **ECS Cluster** and Task Definition
- **ECR Repository** for container images
- **CloudWatch Log Group** for application logs
- **IAM Roles** for service permissions

## 🐳 Step 5: Build and Deploy Container

### Build Docker Image
```bash
# Return to project root
cd ..

# Build and push to ECR (includes platform specification for Linux)
./build-and-push.sh
```

**What this script does:**
1. Authenticates with ECR
2. Builds Docker image for `linux/amd64` platform
3. Tags image with `latest` and timestamp
4. Pushes to your ECR repository

### Verify Container Deployment
```bash
# Check ECS service status
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services $(terraform output -raw ecs_service_name)

# View running tasks
aws ecs list-tasks --cluster $(terraform output -raw ecs_cluster_name)
```

## ✅ Step 6: Verify Deployment

### Get Your Endpoints
```bash
cd terraform

# Your secure gRPC endpoint
terraform output grpc_endpoint

# Load balancer DNS name
terraform output alb_dns_name
```

### Test Connectivity
```bash
# Test HTTPS health check
ALB_DNS=$(terraform output -raw alb_dns_name)
curl -v https://$ALB_DNS/

# Test gRPC connection (replace with your proto file)
grpcurl $ALB_DNS:443 list
```

### Monitor Logs
```bash
# Real-time log monitoring
aws logs tail /ecs/launch-log-target --follow

# Check recent logs
aws logs tail /ecs/launch-log-target --start 1h
```

### Verify Load Balancer Health
```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn)
```

## 🧪 Testing Your OpenTelemetry Collector

### Test with Sample Data
```bash
# Test with included sample log request
grpcurl -d @example/log_request.json \
  $ALB_DNS:443 \
  opentelemetry.proto.collector.logs.v1.LogsService/Export
```

### Integration Testing
```bash
# Test from your application
# Replace with your actual service proto and methods
grpcurl -proto your-service.proto \
  -H "authorization: Bearer your-token" \
  $ALB_DNS:443 \
  your.service/YourMethod
```

## 📊 Monitoring and Maintenance

### CloudWatch Monitoring
```bash
# View ECS service metrics in CloudWatch
# Navigate to: CloudWatch > ECS > Clusters > launch-log-target-cluster

# Set up alarms for:
# - ECS service CPU utilization > 80%  
# - ECS service memory utilization > 80%
# - ALB target response time > 5s
# - ALB 4xx/5xx error rates
```

### Updating the Service
```bash
# After code changes, rebuild and deploy
./build-and-push.sh

# Force new deployment
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw ecs_service_name) \
  --force-new-deployment

# Or use the update script
./update-service.sh
```

### Scaling Operations
```bash
# Scale up for high traffic
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw ecs_service_name) \
  --desired-count 5

# Scale down for cost optimization  
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw ecs_service_name) \
  --desired-count 1
```

## 🔍 Troubleshooting

### Common Issues

#### 🚨 ECS Tasks Not Starting
**Symptoms:** Service shows 0 running tasks

**Debug steps:**
```bash
# Check service events
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services $(terraform output -raw ecs_service_name) \
  --query 'services[0].events[0:5]'

# Check task definition
aws ecs describe-task-definition \
  --task-definition launch-log-target \
  --query 'taskDefinition.containerDefinitions[0]'

# Check container logs
aws logs tail /ecs/launch-log-target --follow
```

**Common causes:**
- ECR image doesn't exist or is inaccessible
- Task execution role lacks permissions
- Container port mismatch
- Resource constraints (CPU/memory too low)

#### ⚠️ Load Balancer Health Checks Failing
**Symptoms:** Targets show "unhealthy" status

**Debug steps:**
```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn)

# Check ALB access logs (if enabled)
# Navigate to: ALB > Monitoring > Access logs

# Test health check endpoint directly
curl -v https://$ALB_DNS/
```

**Common causes:**
- Application not listening on port 4317
- Security group blocking ALB → ECS communication
- Health check path/port misconfigured
- Container taking too long to start

#### 🔧 Docker Build Issues
**Symptoms:** `./build-and-push.sh` fails

**Debug steps:**
```bash
# Check Docker is running
docker info

# Check AWS credentials
aws sts get-caller-identity

# Check ECR permissions
aws ecr describe-repositories --repository-names launch-log-target

# Manual ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

**Common causes:**
- Docker daemon not running
- AWS credentials expired/invalid
- ECR repository doesn't exist
- Platform mismatch (arm64 vs amd64)

#### 🌐 Certificate/DNS Issues
**Symptoms:** HTTPS connections fail

**Debug steps:**
```bash
# Check certificate status
aws acm describe-certificate \
  --certificate-arn $(terraform output -raw ssl_certificate_arn)

# Test DNS resolution
nslookup $ALB_DNS
dig $ALB_DNS

# Test SSL certificate
openssl s_client -connect $ALB_DNS:443 -servername $ALB_DNS
```

**Common causes:**
- Certificate in wrong AWS region
- Certificate expired or not validated
- DNS not pointing to ALB
- Certificate domain mismatch

### Advanced Debugging

#### View All Resource States
```bash
# List all ECS services
aws ecs list-services --cluster $(terraform output -raw ecs_cluster_name)

# Check security groups
aws ec2 describe-security-groups \
  --group-names launch-log-target-* \
  --query 'SecurityGroups[*].{GroupName:GroupName,GroupId:GroupId,VpcId:VpcId}'

# Check ALB listeners
aws elbv2 describe-listeners \
  --load-balancer-arn $(terraform output -raw alb_arn)

# View CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=$(terraform output -raw ecs_service_name) \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

## 💰 Cost Optimization

### Development Environment
```hcl
# In terraform.tfvars for cost savings
fargate_cpu    = 256   # Minimum CPU
fargate_memory = 512   # Minimum memory
app_count      = 1     # Single task

# Consider single AZ deployment to save NAT Gateway costs
# (Modify terraform/main.tf to use only one availability zone)
```

**💰 Monthly savings:** ~$35 (single AZ) + ~$7 (smaller instance) = **~$42/month savings**

### Production Environment
```hcl
# In terraform.tfvars for production workloads
fargate_cpu    = 1024  # 1 vCPU
fargate_memory = 2048  # 2GB RAM
app_count      = 3     # High availability

# Enable auto-scaling (modify terraform/main.tf)
# Add CloudWatch alarms for scaling policies
```

## 🗑️ Cleanup and Teardown

### Complete Cleanup
```bash
# Destroy all resources (WARNING: This is irreversible!)
cd terraform
terraform destroy

# Manually clean up ECR images if needed
aws ecr list-images --repository-name launch-log-target
aws ecr batch-delete-image --repository-name launch-log-target --image-ids imageTag=latest
```

### Selective Cleanup
```bash
# Scale service to 0 (keep infrastructure)
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw ecs_service_name) \
  --desired-count 0

# Remove specific resources
terraform destroy -target="aws_ecs_service.launch_log_target_grpc_service"
```

### Before Cleanup Checklist
- [ ] Export any important logs from CloudWatch
- [ ] Backup any configuration changes  
- [ ] Document any customizations made
- [ ] Verify no critical data dependencies

## 📞 Getting Help

### Documentation
- 🔐 **[Certificate Setup](docs/CERTIFICATES.md)** - SSL certificate options
- 🛡️ **[Security Guide](SECURITY.md)** - Best practices and compliance
- 📖 **[AWS Documentation](https://docs.aws.amazon.com/)**

### Debugging Resources
- **ECS Console:** `https://console.aws.amazon.com/ecs/`
- **CloudWatch Logs:** `https://console.aws.amazon.com/cloudwatch/`
- **ALB Console:** `https://console.aws.amazon.com/ec2/v2/home#LoadBalancers:`

### Community Support
- 🐛 **Issues:** Use GitHub issues for bugs and questions
- 💬 **Discussions:** GitHub discussions for general questions
- 📧 **Security:** Email security issues privately

---

**🎉 Congratulations!** You now have a production-ready OpenTelemetry Collector with enterprise security, auto-scaling, and comprehensive monitoring.