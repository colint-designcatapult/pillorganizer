# Staging Environment Configuration
app_name    = "cabinet"
environment = "staging"
aws_region  = "ca-central-1"

# Domain Configuration
domain_name = "staging.cabinet-app.ca"

# Container Configuration
container_port = 8080

# ECS Configuration (Smaller for staging)
cpu              = 256
memory           = 512
desired_capacity = 1
min_capacity     = 1
max_capacity     = 2

# Database Configuration (Smaller instance for staging)
db_name              = "cabinet_staging_db"
db_username          = "cabinet"
# Database password managed by AWS Secrets Manager: cabinet/staging/db-password
db_instance_class    = "db.t3.micro"
db_allocated_storage = 10

# Networking Configuration
availability_zones = ["ca-central-1a", "ca-central-1b"]

# Health Check Configuration
health_check_path = "/health"