# Project # 20 - VPC Peering Redis Connector

Terraform infrastructure that establishes private multi-region VPC peering between two AWS regions and deploys a VPC-attached Node.js Lambda function as a Redis connector API in the secondary region. The Lambda connects privately to an ElastiCache Redis cluster in the primary region over the peering connection, with no public network exposure.

## Architecture

```
Region 1 (primary)               Region 2 (secondary)
+----------------------+          +---------------------------+
| Existing VPC         |          | New VPC (10.30.0.0/16)    |
| (10.50.0.0/16)       |          |                           |
|                      | VPC      | +---------------------+   |
| ElastiCache Redis    | Peering  | | Lambda              |   |
| port 6379            +<-------->+ | redis-connector     |   |
|                      |          | | Node.js 18.x        |   |
| Route: 10.30.0.0/16  |          | | VPC-attached        |   |
| --> peering conn     |          | +---------------------+   |
+----------------------+          |                           |
                                  | +---------------------+   |
                                  | | API Gateway (REST)  |   |
                                  | | + Lambda Function   |   |
                                  | | URL (CORS enabled)  |   |
                                  | +---------------------+   |
                                  |                           |
                                  | Route: 10.50.0.0/16       |
                                  | --> peering conn          |
                                  +---------------------------+
```

## What It Provisions

**`main.tf` — Network layer**
- Region 2 VPC, subnet, and route table
- VPC peering connection between Region 1 and Region 2
- Bidirectional routes in both regions for cross-region traffic

**`components/main.tf` — Application layer**
- Security group allowing TCP 6379 (Redis) inbound
- IAM execution role with VPC access permissions
- Lambda function (`redis-connector`) deployed inside Region 2 VPC
- Lambda Function URL with CORS enabled
- API Gateway REST API proxied to Lambda

## Stack

Terraform 1.x · AWS Lambda (Node.js 18.x) · VPC Peering · ElastiCache Redis · API Gateway · IAM · CloudWatch Logs

## Repository Layout

```
vpc-peering-redis-connector/
├── main.tf                     # Network foundation: VPC, subnets, peering, routes
├── components/
│   └── main.tf                 # Lambda, API Gateway, security group, IAM
├── .gitignore
└── README.md
```

> `lambda_function_payload.zip` is not checked in. Build and place it in the root before deploying.

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with access to both regions
- Existing Region 1 VPC with an ElastiCache Redis cluster running on port 6379
- `lambda_function_payload.zip` containing the Node.js Redis connector handler

## Deployment

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

Outputs include the VPC peering connection ID, Lambda Function URL, API Gateway endpoint URL, and Lambda function name.

## Testing

Test the Lambda Function URL:

```bash
curl -X POST https://<lambda-url>/resource \
  -H "Content-Type: application/json" \
  -d '{"command":"GET","key":"mykey"}'
```

Test via API Gateway:

```bash
curl -X POST https://<api-id>.execute-api.<region>.amazonaws.com/prod/resource \
  -H "Content-Type: application/json" \
  -d '{"command":"SET","key":"mykey","value":"myvalue"}'
```

Verify peering connection is active:

```bash
aws ec2 describe-vpc-peering-connections \
  --region <region-1> \
  --filters "Name=status-code,Values=active"
```

## Notes

- CORS is currently set to `*`. Restrict to specific origins before moving to production.
- API Gateway has no authorizer configured. Add IAM or Cognito authorization for production use.
- Redis credentials are passed as Lambda environment variables. Move to AWS Secrets Manager for production.
- The secondary region subnet (`10.30.1.0/24`) is a single AZ. Add a second subnet and update the Lambda VPC config for high availability.
- VPC Flow Logs are not enabled. Add them for network-level visibility in production.
