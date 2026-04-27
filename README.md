# etc VPC Peering & Redis Connector Infrastructure

A Terraform-based infrastructure project that establishes secure **multi-region AWS connectivity** between **Region 1 and Region 2** with a serverless **Lambda-based Redis connector API**. This enables the etc application running in Region 2 to securely access a centralized Redis cluster in Region 1 with low-latency, private network connectivity.

## Project Overview

This project sets up a production-ready infrastructure for the etc application with:
- **Multi-region VPC Peering** between AWS Region 1 (xx-region-1) and Region 2 (xx-region-2) regions
- **Serverless Redis Connector** Lambda function with API Gateway in Region 2
- **Secure networking** with proper routing, subnets, and security groups
- **Cross-region private connectivity** for distributed architecture without exposing to the internet
- **Complete infrastructure isolation** within VPCs with no public IP exposure

## Key Features

- **VPC Peering Connection** — Encrypted, private tunnel between Region 1 and Region 2 VPCs
- **Automated Routing** — Bidirectional routes configured for seamless cross-region traffic
- **Lambda Function** — Node.js 18.x Redis connector deployed in Region 2 VPC
- **REST API** — Both Lambda Function URL and API Gateway endpoints available
- **CORS Enabled** — Ready for frontend and cross-origin requests
- **Environment Variables** — Configurable Redis host, port, and application settings
- **Production Ready** — Security groups, IAM roles, and VPC access controls properly configured

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      AWS Multi-Region Setup                 │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Region 1 Region (xx-region-1)     Region 2 Region (xx-region-2)
│  ┌──────────────────────────┐      ┌──────────────────────────┐
│  │   Existing Region 1 VPC     │      │   Region 2 VPC          │
│  │   (vpc-039181ece...)     │◄────►│   (10.30.0.0/16)         │
│  │   10.50.0.0/16           │ VPC  │                          │
│  │                          │ Peering │ ┌──────────────────┐   │
│  │  ┌──────────────────┐    │      │  │  Lambda Function │   │
│  │  │  Redis Cluster   │    │      │  │  (redis-connector)   │
│  │  │  (ElastiCache)   │    │      │  │  - Node.js 18.x │   │
│  │  │  redis-cluster   │    │      │  │  - Port 6379    │   │
│  │  │  .s3psra...      │    │      │  │  - VPC attached │   │
│  │  │  :6379           │    │      │  │                 │   │
│  │  └──────────────────┘    │      │  │ ┌──────────────┐ │   │
│  │                          │      │  │ │ API Gateway  │ │   │
│  │  Route Table:            │      │  │ │ + Function   │ │   │
│  │  10.30.0.0/16 → pcx-xxx │       │   │  │ URL (CORS)    │ │   │
│  └──────────────────────────┘      │  │ └──────────────┘ │   │
│                                    │  │                 │   │
│                                    │  │ Route Table:    │   │
│                                    │  │ 10.50.0.0/16 →  │   │
│                                    │  │ pcx-xxx         │   │
│                                    │  └──────────────────┘   │
│                                    │                          │
│                                    └──────────────────────────┘
│                                                               │
│         (Encrypted Private Tunnel - VPC Peering)            │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

```
.
├── main.tf                              # VPC peering setup (network foundation)
│   ├── AWS Providers (Region 1, Region 2)
│   ├── Region 1 VPC reference
│   ├── Region 2 VPC creation
│   ├── Subnets & Route Tables
│   └── VPC Peering Connection & Routes
│
├── components/
│   └── main.tf                          # Lambda & API Gateway (application layer)
│       ├── Security Group
│       ├── IAM Role & Policies
│       ├── Lambda Function (redis-connector)
│       ├── Lambda Function URL
│       ├── API Gateway & Integration
│       └── Outputs
│
├── README.md                            # This file
├── PROJECT_UNDERSTANDING.md             # Deep dive into concepts & architecture
└── lambda_function_payload.zip          # Lambda function code (not checked in)
```

## Tech Stack

- **Terraform** >= 1.x
- **AWS Services:**
  - VPC (Virtual Private Cloud)
  - VPC Peering Connection
  - Subnets & Route Tables
  - Lambda (Node.js 18.x runtime)
  - API Gateway (REST)
  - Security Groups
  - IAM Roles & Policies
  - CloudWatch Logs
  - ElastiCache Redis (Region 1, pre-existing)

## Configuration Overview

### `main.tf` - Network Foundation
Establishes multi-region connectivity:
- **Variables:** VPC CIDRs and IDs
- **Providers:** AWS regions (Region 1: xx-region-1, Region 2: xx-region-2)
- **Data Sources:** Reference existing Region 1 VPC
- **Resources Created:**
  - Region 2 VPC (10.30.0.0/16)
  - Region 2 Subnet (10.30.1.0/24)
  - Route Tables (both regions)
  - VPC Peering Connection
  - Routes for cross-region traffic
- **Outputs:** VPC IDs, Subnet IDs, Peering Connection ID

### `components/main.tf` - Application Layer
Deploys serverless Redis connector in Region 2:
- **Local Variables:** Region config, Redis endpoint, VPC details
- **Resources Created:**
  - Security Group (TCP 6379 for Redis)
  - IAM Execution Role (VPC access)
  - Lambda Function (redis-connector)
  - Lambda Function URL (HTTPS with CORS)
  - API Gateway (REST API)
  - Lambda Permissions
- **Outputs:** Function URL, API Gateway URL, ARNs

## Prerequisites

- **Terraform** >= 1.0
- **AWS CLI** configured with credentials
- **Access** to both Region 1 and Region 2 AWS regions
- **Existing Region 1 VPC** with:
  - VPC ID: `vpc-039181ece9d979587`
  - Redis cluster running (ElastiCache)
  - Host: `redis-cluster.s3psra.0001.apne1.cache.amazonaws.com`
  - Port: 6379
- **Lambda payload** (`lambda_function_payload.zip`) with Redis connector code
- **Git** (for version control)

## Deployment Instructions

### Step 1: Clone & Setup
```bash
git clone <your-repo-url>
cd 16_project_PEERING
terraform init
```

### Step 2: Verify Plan
```bash
terraform plan -out=tfplan
# Review the changes before applying
```

### Step 3: Apply Infrastructure
```bash
terraform apply tfplan
```

### Step 4: Get Outputs
```bash
terraform output
```

You'll receive:
- `vpc_peering_connection_id` - Peering connection ID
- `lambda_function_url` - Direct Lambda HTTPS endpoint
- `api_gateway_url` - REST API endpoint
- `lambda_function_name` - Function name for CLI access

## Configuration Details

### Environment Variables (Lambda)
Set in `components/main.tf`:
```hcl
REDIS_HOST       = "redis-cluster.xxx.amazonaws.com"
REDIS_PORT       = "6379"
ENVIRONMENT      = "staging"
ORIGIN_HOST      = "xx.xx.xx.xx"
WORDPRESS_DOMAIN = "staging.etc.app"
```

### Network Configuration
- **Region 2 VPC:** 10.30.0.0/16
- **Region 2 Subnet:** 10.30.1.0/24
- **Region 1 VPC:** 10.50.0.0/16 (existing)
- **Connection:** VPC Peering (encrypted, private)

## Testing

### Test Lambda Function URL
```bash
curl -X POST https://<lambda-url>/resource \
  -H "Content-Type: application/json" \
  -d '{"command":"GET","key":"mykey"}'
```

### Test API Gateway Endpoint
```bash
curl -X POST https://xyz.execute-api.xx-region-2.amazonaws.com/prod/resource \
  -H "Content-Type: application/json" \
  -d '{"command":"SET","key":"mykey","value":"myvalue"}'
```

### Verify VPC Peering
```bash
# Check peering status
aws ec2 describe-vpc-peering-connections \
  --region xx-region-1 \
  --filters "Name=status-code,Values=active"

# Test connectivity from Lambda CloudWatch Logs
# Or test via EC2 instance in Region 2 VPC
```

## Security Best Practices

✅ **Implemented:**
- VPC isolation (resources in private VPCs)
- VPC peering (encrypted private tunnel)
- Security groups (port-level access control)
- IAM roles (least privilege for Lambda)
- No public IP addresses

⚠️ **For Production:**
- Restrict CORS origins (currently allows `*`)
- Enable API Gateway authorization
- Use AWS Secrets Manager for Redis credentials
- Add VPC Flow Logs for monitoring
- Enable CloudWatch alarms
- Restrict security group CIDR blocks
- Add Network ACLs

## Cost Estimation

Typical monthly costs (rough estimates):
- **VPC Peering:** ~$0.02/GB data transfer
- **Lambda:** ~$0.0000002 per invocation + compute time
- **API Gateway:** ~$3.50 per million requests
- **Data Transfer:** ~$0.02/GB between regions
- **Total (light usage):** $5-20/month

## Troubleshooting

### VPC Peering Connection Stuck
```bash
# Check status
aws ec2 describe-vpc-peering-connections \
  --region xx-region-1 \
  --query 'VpcPeeringConnections[*].[VpcPeeringConnectionId,Status.Code]'
```

### Lambda Can't Reach Redis
1. Check Security Group ingress rules
2. Verify Route Table entries
3. Test with `nc` or `redis-cli` from Lambda environment
4. Check CloudWatch Logs

### API Gateway 403 Error
```bash
# Verify Lambda permissions
aws lambda get-policy \
  --function-name redis-connector \
  --region xx-region-2
```

## Customization

### Change VPC CIDR
Edit `main.tf`:
```hcl
variable "hongkong_vpc_cidr" {
  default = "10.40.0.0/16"  # New CIDR
}
```

### Change Lambda Runtime
Edit `components/main.tf`:
```hcl
runtime = "nodejs20.x"  # Update version
```

### Update Redis Endpoint
Edit `components/main.tf` locals:
```hcl
redis_host = "your-redis-endpoint"
redis_port = "6379"
```

## Additional Resources

- [AWS VPC Peering](https://docs.aws.amazon.com/vpc/latest/peering/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Lambda VPC](https://docs.aws.amazon.com/lambda/latest/dg/vpc.html)
- [API Gateway REST APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizers.html)
- [ElastiCache Redis](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/)

## Project Details

- **Project Name:** etc
- **Regions:** Region 1 (xx-region-1), Region 2 (xx-region-2)
- **Environment:** Staging
- **Status:** Active & Maintained
- **Last Updated:** 2026-04-27

## Support & Questions

For detailed concept explanations, see **PROJECT_UNDERSTANDING.md** which covers:
- What is a VPC?
- What is VPC Peering?
- What is a Subnet?
- What is a Route Table?
- Complete data flow walkthrough
- Architecture decision rationale

## License

[Specify your license here]

## Author

[Your name/team]

---

**Status:** ✅ Production Ready | **Terraform:** >= 1.0 | **Last Updated:** 2026-04-27
