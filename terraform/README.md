# Terraform Infrastructure as Code

Automate infrastructure provisioning with Terraform.

## Quick Start

```bash
cd terraform/docker

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply infrastructure
terraform apply

# Destroy infrastructure
terraform destroy
```

## What Gets Created

- Docker network for monitoring
- Prometheus container
- Grafana container
- Redis container
- PostgreSQL container

## Accessing Services

After `terraform apply`:
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **Redis**: localhost:6379
- **PostgreSQL**: localhost:5432

## View Outputs

```bash
terraform output
terraform output -json
terraform output prometheus_url
```

## State Management

State is stored locally in `terraform.tfstate`.
For production, use remote state (S3, Terraform Cloud, etc.)

## Variables

Copy `terraform.tfvars.example` to `terraform.tfvars` and customize.

Variables:
- `environment`: dev/staging/prod
- `prometheus_port`: Prometheus port (default: 9090)
- `grafana_port`: Grafana port (default: 3000)
- `grafana_admin_password`: Grafana password
- And more...

## Best Practices Implemented

✅ Variable validation
✅ Sensitive value handling
✅ Resource dependencies
✅ Output formatting
✅ State management
✅ Provider versioning
