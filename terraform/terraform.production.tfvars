# Production Environment Configuration
app_name    = "cabinet"
environment = "production"
aws_region  = "ca-central-1"

# Domain Configuration
domain_name = "cabinet-app.ca"

# Container Configuration
container_port = 8080

# ECS Configuration (Production sized)
cpu              = 512
memory           = 1024
desired_capacity = 2
min_capacity     = 1
max_capacity     = 4

# Database Configuration (Production instance)
db_name              = "cabinet_production_db"
db_username          = "cabinet"
# Database password managed by AWS Secrets Manager: cabinet/production/db-password
db_instance_class    = "db.t3.small"
db_allocated_storage = 50

# Networking Configuration
availability_zones = ["ca-central-1a", "ca-central-1b"]

# Health Check Configuration
health_check_path = "/health"