# CabiNET Infrastructure

This Terraform configuration sets up a complete AWS infrastructure for the CabiNET application in Canada (ca-central-1 region) for data residency compliance including:

- ECS Fargate cluster and service
- Application Load Balancer (ALB)
- PostgreSQL RDS database
- Route 53 hosted zone and DNS records
- VPC with public, private, and database subnets
- Security groups and IAM roles
- Auto-scaling configuration
- CloudWatch logging

## Architecture

```
Internet -> Route 53 -> ALB -> ECS Fargate Tasks -> RDS PostgreSQL
                        |
                        VPC (10.0.0.0/16)
                        ├── Public Subnets (10.0.1.0/24, 10.0.2.0/24)
                        ├── Private Subnets (10.0.10.0/24, 10.0.11.0/24)
                        └── Database Subnets (10.0.20.0/24, 10.0.21.0/24)
```

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **Docker image** pushed to ECR or other container registry
4. **Domain name** registered (can be managed elsewhere)

## Multi-Environment Setup

This configuration supports both **staging** and **production** environments using Terraform workspaces. Each environment has its own:

- Isolated infrastructure and state
- Separate configuration files
- Different resource sizing
- Independent domains

### Environment Configurations:

- **Staging**: `terraform.staging.tfvars` - Smaller resources, single instance
- **Production**: `terraform.production.tfvars` - Larger resources, multiple instances

## Quick Start

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Configure Environments

Edit the environment-specific configuration files:

**For Staging (`terraform.staging.tfvars`):**

```hcl
domain_name = "staging.your-domain.com"
container_image = "your-account.dkr.ecr.ca-central-1.amazonaws.com/cabinet:staging"
db_password = "your-staging-password"
```

**For Production (`terraform.production.tfvars`):**

```hcl
domain_name = "your-domain.com"
container_image = "your-account.dkr.ecr.ca-central-1.amazonaws.com/cabinet:latest"
db_password = "your-production-password"
```

### 3. Deploy Staging Environment

```bash
make staging-apply
```

### 4. Deploy Production Environment

```bash
make production-apply
```

## Environment Management

### Using Make Commands (Recommended)

**Staging Environment:**

```bash
make staging-plan      # Plan staging changes
make staging-apply     # Deploy staging
make staging-destroy   # Destroy staging
make staging-output    # Show staging outputs
```

**Production Environment:**

```bash
make production-plan      # Plan production changes
make production-apply     # Deploy production
make production-destroy   # Destroy production
make production-output    # Show production outputs
```

### Using Terraform Workspaces Directly

**List workspaces:**

```bash
terraform workspace list
```

**Switch to staging:**

```bash
terraform workspace select staging
terraform plan -var-file="terraform.staging.tfvars"
terraform apply -var-file="terraform.staging.tfvars"
```

**Switch to production:**

```bash
terraform workspace select production
terraform plan -var-file="terraform.production.tfvars"
terraform apply -var-file="terraform.production.tfvars"
```

## Environment Differences

### Staging Environment

- **Purpose**: Testing and development
- **Domain**: `staging.yourdomain.com`
- **Resources**:
  - ECS: 1 task, 256 CPU, 512 MB memory
  - RDS: `db.t3.micro`, 10 GB storage
  - Auto-scaling: 1-2 tasks max
- **Cost**: Optimized for low cost
- **Uptime**: Can tolerate downtime for maintenance

### Production Environment

- **Purpose**: Live production workload
- **Domain**: `yourdomain.com`
- **Resources**:
  - ECS: 2 tasks, 512 CPU, 1024 MB memory
  - RDS: `db.t3.small`, 50 GB storage
  - Auto-scaling: 2-6 tasks max
- **Cost**: Optimized for performance and availability
- **Uptime**: High availability requirements

## Configuration

### Required Variables

- `domain_name`: Your domain name (e.g., "cabinet.com")
- `container_image`: Docker image URI for your application
- `db_password`: Secure password for the PostgreSQL database

### Optional Variables

All other variables have sensible defaults but can be customized:

- `app_name`: Application name (default: "cabinet")
- `environment`: Environment name (default: "prod")
- `aws_region`: AWS region (default: "ca-central-1")
- `container_port`: Container port (default: 8080)
- `cpu`, `memory`: ECS task resources
- `desired_capacity`, `min_capacity`, `max_capacity`: Auto-scaling settings
- `db_instance_class`: RDS instance type (default: "db.t3.micro")

## Outputs

After deployment, Terraform will output important values:

- `application_url`: Your application URL
- `load_balancer_dns_name`: ALB DNS name
- `database_endpoint`: RDS endpoint (sensitive)
- `route53_name_servers`: Name servers for DNS delegation

## Post-Deployment Steps

1. **Update your domain's DNS settings** to use the Route 53 name servers output by Terraform
2. **Wait for DNS propagation** (can take up to 48 hours)
3. **Verify your application** is accessible at your domain
4. **Check CloudWatch logs** at `/ecs/cabinet-prod` log group

## SSL/TLS Certificate

This configuration uses HTTP only. To add HTTPS:

1. Request an SSL certificate through AWS Certificate Manager
2. Add the certificate ARN to the ALB listener
3. Redirect HTTP traffic to HTTPS

Example addition to `main.tf`:

```hcl
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "arn:aws:acm:ca-central-1:account:certificate/certificate-id"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
```

## Cost Optimization

For development environments, consider:

- Using `db.t3.micro` or `db.t4g.micro` for RDS
- Reducing ECS task resources (CPU/memory)
- Setting lower min/max capacity for auto-scaling
- Using spot instances (requires additional configuration)

## Security Considerations

1. **Database password**: Use AWS Secrets Manager for production
2. **VPC security**: Database is isolated in private subnets
3. **Security groups**: Restrictive rules limiting access
4. **IAM roles**: Principle of least privilege

## Monitoring

The infrastructure includes:

- CloudWatch logs for ECS tasks
- Container insights for ECS cluster
- ALB access logs (can be enabled)
- RDS monitoring

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all data including the database.

## Troubleshooting

### Common Issues

1. **ECS tasks not starting**: Check CloudWatch logs and security groups
2. **Database connection issues**: Verify security group rules and endpoint
3. **Domain not resolving**: Check DNS delegation and Route 53 configuration
4. **Load balancer health checks failing**: Verify health check path and port

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster cabinet-prod-cluster --services cabinet-prod-service

# View ECS task logs
aws logs get-log-events --log-group-name /ecs/cabinet-prod --log-stream-name <stream-name>

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

## Common Workflows

### Initial Setup

1. Initialize Terraform: `terraform init`
2. Deploy staging first: `make staging-apply`
3. Test staging environment
4. Deploy production: `make production-apply`

### Development Workflow

1. Make infrastructure changes
2. Test in staging: `make staging-plan` → `make staging-apply`
3. Verify changes work correctly
4. Apply to production: `make production-plan` → `make production-apply`

### Application Updates

1. Build and push new container images:
   - Staging: `cabinet:staging`
   - Production: `cabinet:latest`
2. Update tfvars files with new image URIs
3. Apply changes to respective environments

### Emergency Procedures

**Scale up production quickly:**

```bash
terraform workspace select production
terraform apply -var-file="terraform.production.tfvars" -var="desired_capacity=4"
```

**View current resources:**

```bash
make workspace-list                    # See all environments
make production-output                 # Get production details
make staging-output                   # Get staging details
```

### Cost Management

- **Staging**: Can be destroyed overnight to save costs
- **Production**: Keep running for high availability
- Use `make staging-destroy` and `make staging-apply` as needed
