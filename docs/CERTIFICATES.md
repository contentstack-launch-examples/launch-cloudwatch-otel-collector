# 🔐 SSL Certificate Setup Guide

Complete guide for setting up SSL certificates with your OpenTelemetry gRPC Collector.

## Certificate Options

### Option 1: Use Your Existing Certificate (Recommended)

If you already have an SSL certificate in AWS Certificate Manager:

```bash
# List your certificates
aws acm list-certificates --region us-east-1

# Copy the ARN for your certificate
```

**Configure in `terraform/terraform.tfvars`:**
```hcl
ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/your-cert-id"
```

### Option 2: Get FREE Certificate with AWS ACM

AWS Certificate Manager provides **completely FREE** SSL certificates!

#### For Route53 Domains (Automatic)
```hcl
# In terraform/terraform.tfvars
domain_name = "api.yourdomain.com"
route53_zone_id = "Z123456789ABCDEFGH"  # Your hosted zone ID
ssl_certificate_arn = ""  # Leave empty to create new certificate
```

Find your zone ID:
```bash
aws route53 list-hosted-zones --query 'HostedZones[?Name==`yourdomain.com.`].Id' --output text
```

#### For External Domains (Manual Validation)
```hcl
# In terraform/terraform.tfvars  
domain_name = "api.yourdomain.com"
ssl_certificate_arn = ""  # Leave empty to create new certificate
```

After `terraform apply`, you'll get DNS validation records to add to your domain provider:
```
_abc123.api.yourdomain.com → _xyz789.acm-validations.aws.
```

### Option 3: Self-Signed Certificate (Testing Only)

⚠️ **For development/testing only**

```hcl
# In terraform/terraform.tfvars
domain_name = "otel-collector.local"
ssl_certificate_arn = ""  # Self-signed will be created automatically
```

## Import Existing Certificate

If you have certificate files:

```bash
aws acm import-certificate \
  --certificate fileb://certificate.crt \
  --private-key fileb://private.key \
  --certificate-chain fileb://ca-bundle.crt
```

## Testing Your Setup

### With Valid Certificate:
```bash
# Test secure gRPC connection
grpcurl -proto your-service.proto your-domain.com:443 service.method

# Test HTTPS health check
curl -v https://your-alb-dns-name/
```

### With Self-Signed Certificate:
```bash
# Test with certificate validation disabled
grpcurl -insecure your-alb-dns-name:443 service.method
```

## Cost Breakdown

| Certificate Type | Monthly Cost | Notes |
|-----------------|-------------|-------|
| **AWS ACM Public** | **$0.00** | ✅ **Completely FREE** |
| **AWS ACM Private** | $400.00 | For private PKI |
| **Route53 Hosted Zone** | $0.50 | If using Route53 |
| **DNS Queries** | $0.40/million | Minimal cost |

**💰 Total Certificate Cost: $0.00 - $0.50/month**

## Troubleshooting

### Certificate Validation Issues
```bash
# Check certificate status
aws acm describe-certificate --certificate-arn YOUR_ARN

# Check DNS validation
dig _validation-record.yourdomain.com CNAME
```

### Common Problems

**❌ "Domain validation failed"**
- Ensure DNS records are added correctly
- Wait 5-30 minutes for DNS propagation
- Verify domain ownership

**❌ "Certificate not ready"**  
- ACM validation can take up to 30 minutes
- Check ACM console for status
- Ensure domain resolves correctly

**❌ "Wrong region"**
- Certificate must be in same region as ALB
- Create certificate in `us-east-1` (or your deployment region)

## Production Best Practices

✅ **DO:**
- Use ACM public certificates (free and auto-renewing)
- Set up proper DNS records
- Monitor certificate expiration
- Use Route53 for automated validation

❌ **DON'T:**
- Use self-signed certificates in production  
- Share certificates between environments
- Ignore certificate expiration warnings
- Use overly broad certificate subject names

## Need Help?

- 📖 **Setup Guide**: See [SETUP.md](../SETUP.md)
- 🛡️ **Security**: See [SECURITY.md](../SECURITY.md)  
- 📞 **Issues**: Check AWS ACM console and CloudWatch logs
