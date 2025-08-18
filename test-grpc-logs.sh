#!/bin/bash

# Test script for OpenTelemetry gRPC Logs Export
# This script sends test log data to the deployed OpenTelemetry collector

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

echo_header() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Check if grpcurl is installed
if ! command -v grpcurl &> /dev/null; then
    echo_error "grpcurl is not installed. Please install it first:"
    echo "  macOS: brew install grpcurl"
    echo "  Linux: https://github.com/fullstorydev/grpcurl#installation"
    exit 1
fi

# Get the gRPC endpoint from terraform output
echo_info "Getting gRPC endpoint from terraform..."
if [ -f "terraform/terraform.tfstate" ]; then
    GRPC_ENDPOINT=$(cd terraform && terraform output -raw grpc_endpoint 2>/dev/null || echo "")
    if [ -z "$GRPC_ENDPOINT" ]; then
        echo_warn "Could not get endpoint from terraform output"
        GRPC_ENDPOINT="https://launch-grpc-log-target-alb-1861372888.us-east-1.elb.amazonaws.com:443"
        echo_info "Using hardcoded endpoint: $GRPC_ENDPOINT"
    else
        echo_info "Using terraform endpoint: $GRPC_ENDPOINT"
    fi
else
    GRPC_ENDPOINT="https://launch-grpc-log-target-alb-1861372888.us-east-1.elb.amazonaws.com:443"
    echo_warn "No terraform state found, using hardcoded endpoint: $GRPC_ENDPOINT"
fi

# Extract hostname and port from the endpoint
GRPC_HOST=$(echo $GRPC_ENDPOINT | sed 's|https://||' | sed 's|http://||' | cut -d':' -f1)
GRPC_PORT=$(echo $GRPC_ENDPOINT | sed 's|https://||' | sed 's|http://||' | cut -d':' -f2)

echo_header "Testing OpenTelemetry gRPC Logs Export"
echo "Target: $GRPC_HOST:$GRPC_PORT"
echo ""

# Create test log data in OpenTelemetry format (using working example)
cat > /tmp/otel_test_logs.json << 'EOF'
{
    "resource_logs": [
        {
            "resource": {
                "attributes": [
                ],
                "dropped_attributes_count": 993869557
            },
            "scope_logs": [
                {
                    "scope": {
                        "name": "test-grpc-client",
                        "version": "1.0.0",
                        "attributes": [],
                        "dropped_attributes_count": 0
                    },
                    "log_records": [
                        {
                            "time_unix_nano": "1692633600000000000",
                            "observed_time_unix_nano": "1692633600000000000",
                            "severity_number": "SEVERITY_NUMBER_INFO",
                            "severity_text": "INFO",
                            "body": {
                                "string_value": "Test log message from secure gRPC client - OpenTelemetry collector is working!",
                                "bool_value": false,
                                "int_value": "12345",
                                "double_value": 1.234,
                                "array_value": {
                                    "values": []
                                },
                                "kvlist_value": {
                                    "values": []
                                },
                                "bytes_value": ""
                            },
                            "attributes": [
                                {
                                    "key": "test.component",
                                    "value": {
                                        "string_value": "grpc-test-script"
                                    }
                                },
                                {
                                    "key": "test.environment",
                                    "value": {
                                        "string_value": "aws-ecs"
                                    }
                                }
                            ],
                            "dropped_attributes_count": 0,
                            "flags": 0
                        }
                    ],
                    "schema_url": "https://opentelemetry.io/schemas/1.21.0"
                }
            ],
            "schema_url": "https://opentelemetry.io/schemas/1.21.0"
        }
    ]
}
EOF

echo_info "Created test log data with:"
echo "  • Service: test-application v1.0.0"
echo "  • Environment: test"
echo "  • 2 log records (INFO and WARN levels)"
echo "  • Trace/Span IDs included"
echo ""

# IMPORTANT: Get your Bearer token from Launch Log Target settings
# Launch Console > Log Targets > Your Target > Configuration > Bearer Token
# This token must match the one configured in otelcol-config.yaml
BEARER_TOKEN="${LAUNCH_JWT_TOKEN:-YOUR_JWT_BEARER_TOKEN_FROM_LAUNCH_LOG_TARGET}"

# Check if token is configured
if [[ "$BEARER_TOKEN" == "YOUR_JWT_BEARER_TOKEN_FROM_LAUNCH_LOG_TARGET" ]]; then
    echo_error "❌ JWT Bearer token not configured!"
    echo ""
    echo_info "Please set your JWT token in one of these ways:"
    echo ""
    echo "1. Set environment variable:"
    echo "   export LAUNCH_JWT_TOKEN=\"your-jwt-token-here\""
    echo ""
    echo "2. Or edit this script and replace the placeholder token"
    echo ""
    echo "3. Get your token from: Launch Console > Log Targets > Configuration"
    echo ""
    exit 1
fi

# Test the gRPC endpoint with Bearer token authentication
echo_header "Sending logs to OpenTelemetry collector..."
echo "Command: grpcurl -servername \"otel.csnonprod.com\" -proto opentelemetry/proto/collector/logs/v1/logs_service.proto -H \"Authorization: Bearer \$BEARER_TOKEN\" -d \"\$(cat /tmp/otel_test_logs.json)\" $GRPC_HOST:$GRPC_PORT opentelemetry.proto.collector.logs.v1.LogsService/Export"
echo ""
echo_info "Using official OpenTelemetry proto files and SNI for secure connection"
echo ""

if grpcurl -servername "otel.csnonprod.com" \
    -proto opentelemetry/proto/collector/logs/v1/logs_service.proto \
    -H "Authorization: Bearer $BEARER_TOKEN" \
    -d "$(cat /tmp/otel_test_logs.json)" \
    $GRPC_HOST:$GRPC_PORT \
    opentelemetry.proto.collector.logs.v1.LogsService/Export; then
    echo ""
    echo_info "✅ SUCCESS! Logs sent to OpenTelemetry collector"
    echo ""
    echo_header "Verification Steps:"
    echo "1. Check CloudWatch Logs (logs go to /ecs/otel per config):"
    echo "   aws logs tail /ecs/otel --follow"
    echo ""
    echo "   Or check the specific log stream:"
    echo "   aws logs get-log-events --log-group-name '/ecs/otel' --log-stream-name 'tastecard/logs'"
    echo ""
    echo "2. View in AWS Console:"
    echo "   https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/\$252Fecs\$252Flaunch-log-target"
    echo ""
    echo "3. Check ECS service status:"
    echo "   aws ecs describe-services --cluster launch-log-target-cluster --services launch-log-target-grpc-service"
else
    echo ""
    echo_error "❌ FAILED! Could not send logs to OpenTelemetry collector"
    echo ""
    echo_header "Troubleshooting:"
    echo "1. Check if the ALB is healthy:"
    echo "   curl -v https://$GRPC_HOST/"
    echo ""
    echo "2. Check ECS service status:"
    echo "   aws ecs describe-services --cluster launch-log-target-cluster --services launch-log-target-grpc-service"
    echo ""
    echo "3. Check CloudWatch logs for errors:"
    echo "   aws logs tail /ecs/launch-log-target --follow"
    echo ""
    echo "4. Verify security groups allow HTTPS (443):"
    echo "   aws ec2 describe-security-groups --group-names launch-grpc-log-target-alb-sg"
    
    exit 1
fi

# Cleanup
rm -f /tmp/otel_test_logs.json

echo_header "Test completed successfully! 🎉"
