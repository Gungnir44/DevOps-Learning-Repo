# Cloud Deployment Configurations

Production-ready Infrastructure as Code (IaC) for deploying the monitoring stack to AWS and Azure.

## Overview

This directory contains Terraform configurations to deploy the complete monitoring stack to cloud platforms:

- **AWS**: Deploy to Amazon ECS Fargate with Application Load Balancer
- **Azure**: Deploy to Azure Kubernetes Service (AKS) with managed Kubernetes

Both configurations include:
- ✅ High availability setup with multiple availability zones
- ✅ Auto-scaling based on CPU utilization
- ✅ Persistent storage for metrics and dashboards
- ✅ Load balancing and health checks
- ✅ Cloud-native monitoring integration
- ✅ Security best practices (encryption, IAM/RBAC)

## Directory Structure

```
cloud/
├── aws/                    # AWS ECS deployment
│   ├── main.tf            # VPC, ECS cluster, networking
│   ├── ecs-services.tf    # ECS task definitions and services
│   ├── variables.tf       # Input variables
│   └── outputs.tf         # Output values
└── azure/                 # Azure AKS deployment
    ├── main.tf            # AKS cluster, networking, Helm deployment
    ├── variables.tf       # Input variables
    └── outputs.tf         # Output values
```

## AWS Deployment (ECS Fargate)

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                         VPC                             │
│  ┌──────────────┐              ┌──────────────┐        │
│  │   Public     │              │   Public     │        │
│  │   Subnet     │              │   Subnet     │        │
│  │  (AZ-1)      │              │  (AZ-2)      │        │
│  │              │              │              │        │
│  │   ┌─────────────────────────────────┐      │        │
│  │   │ Application Load Balancer        │      │        │
│  │   └────────────┬────────────────────┘      │        │
│  └────────────────┼─────────────────────────────┘       │
│                   │                                      │
│  ┌────────────────▼────────┐   ┌──────────────┐        │
│  │   Private Subnet        │   │   Private    │        │
│  │   (AZ-1)                │   │   Subnet     │        │
│  │  ┌──────────┐           │   │   (AZ-2)     │        │
│  │  │Prometheus│           │   │              │        │
│  │  │   ECS    │           │   │              │        │
│  │  └──────────┘           │   │              │        │
│  │  ┌──────────┐           │   │              │        │
│  │  │ Grafana  │           │   │              │        │
│  │  │   ECS    │           │   │              │        │
│  │  └──────────┘           │   │              │        │
│  └─────────────────────────┘   └──────────────┘        │
│                                                          │
│  ┌──────────────────────────────────────────┐           │
│  │         EFS (Persistent Storage)         │           │
│  └──────────────────────────────────────────┘           │
└──────────────────────────────────────────────────────────┘
```

### Features

- **ECS Fargate**: Serverless container execution (no EC2 management)
- **Application Load Balancer**: HTTPS termination and path-based routing
- **EFS**: Persistent storage for Prometheus metrics and Grafana dashboards
- **Auto Scaling**: Scale 1-3 replicas based on CPU (target: 70%)
- **Multi-AZ**: High availability across 2 availability zones
- **CloudWatch**: Integrated logging and monitoring
- **Container Insights**: Detailed container metrics

### Prerequisites

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format

# Verify
aws sts get-caller-identity
```

### Deployment Steps

1. **Set up Terraform backend** (S3 + DynamoDB for state locking):
   ```bash
   # Create S3 bucket for state
   aws s3 mb s3://devops-monitoring-terraform-state --region us-east-1

   # Enable versioning
   aws s3api put-bucket-versioning \
     --bucket devops-monitoring-terraform-state \
     --versioning-configuration Status=Enabled

   # Create DynamoDB table for locking
   aws dynamodb create-table \
     --table-name terraform-state-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```

2. **Configure variables**:
   ```bash
   cd cloud/aws

   # Create terraform.tfvars
   cat > terraform.tfvars <<EOF
   aws_region = "us-east-1"
   environment = "production"
   grafana_admin_password = "your-secure-password"
   EOF
   ```

3. **Deploy infrastructure**:
   ```bash
   # Initialize Terraform
   terraform init

   # Review plan
   terraform plan

   # Apply configuration
   terraform apply

   # Save outputs
   terraform output > deployment-info.txt
   ```

4. **Access services**:
   ```bash
   # Get ALB DNS name
   ALB_DNS=$(terraform output -raw alb_dns_name)

   # Access Grafana
   echo "Grafana: http://$ALB_DNS/grafana/"

   # Access Prometheus
   echo "Prometheus: http://$ALB_DNS/prometheus/"
   ```

### Cost Estimation

| Resource | Monthly Cost (us-east-1) |
|----------|-------------------------|
| ECS Fargate (0.5 vCPU, 1GB RAM) | ~$15/task |
| Application Load Balancer | ~$20 |
| EFS Storage (10GB) | ~$3 |
| Data Transfer (1TB) | ~$90 |
| **Total Estimated** | **~$143/month** |

*Costs vary by region and usage*

### Scaling

```bash
# Increase Prometheus replicas
terraform apply -var="prometheus_replica_count=2"

# Increase memory
terraform apply -var="prometheus_memory=4096"

# Enable/disable NAT Gateway (cost optimization for dev)
terraform apply -var="enable_nat_gateway=false"
```

## Azure Deployment (AKS)

### Architecture

```
┌──────────────────────────────────────────────────────────┐
│               Azure Resource Group                       │
│  ┌────────────────────────────────────────────────┐     │
│  │            Virtual Network (VNet)               │     │
│  │  ┌──────────────────────────────────────┐      │     │
│  │  │        AKS Subnet                    │      │     │
│  │  │   ┌──────────┐      ┌──────────┐    │      │     │
│  │  │   │  Node 1  │      │  Node 2  │    │      │     │
│  │  │   │          │      │          │    │      │     │
│  │  │   │ ┌────┐   │      │ ┌────┐   │    │      │     │
│  │  │   │ │Pod │   │      │ │Pod │   │    │      │     │
│  │  │   │ └────┘   │      │ └────┘   │    │      │     │
│  │  │   └──────────┘      └──────────┘    │      │     │
│  │  └──────────────────────────────────────┘      │     │
│  └────────────────────────────────────────────────┘     │
│                                                           │
│  ┌────────────────────────────────────────────────┐     │
│  │         Azure Files (Persistent Volumes)        │     │
│  └────────────────────────────────────────────────┘     │
│                                                           │
│  ┌────────────────────────────────────────────────┐     │
│  │    Log Analytics Workspace (Azure Monitor)      │     │
│  └────────────────────────────────────────────────┘     │
│                                                           │
│  ┌────────────────────────────────────────────────┐     │
│  │    Azure Container Registry (Optional)          │     │
│  └────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────┘
```

### Features

- **Managed Kubernetes**: Azure handles control plane
- **Auto-scaling**: Node auto-scaling (1-5 nodes) + HPA for pods
- **Azure Files**: Persistent storage with SMB
- **Azure Monitor**: Integrated logging and metrics
- **Container Insights**: Deep container observability
- **Azure Policy**: Enforce governance and compliance
- **System-assigned Identity**: Secure authentication
- **Network Policy**: Azure CNI with network policies

### Prerequisites

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login
az login

# Set subscription
az account set --subscription "Your-Subscription-Name"

# Verify
az account show
```

### Deployment Steps

1. **Set up Terraform backend**:
   ```bash
   # Create resource group for Terraform state
   az group create --name terraform-state-rg --location "East US"

   # Create storage account
   az storage account create \
     --resource-group terraform-state-rg \
     --name devopsterraformstate \
     --sku Standard_LRS \
     --encryption-services blob

   # Create container
   az storage container create \
     --name tfstate \
     --account-name devopsterraformstate
   ```

2. **Configure variables**:
   ```bash
   cd cloud/azure

   # Create terraform.tfvars
   cat > terraform.tfvars <<EOF
   location = "East US"
   environment = "production"
   kubernetes_version = "1.28"
   node_count = 2
   grafana_admin_password = "your-secure-password"
   EOF
   ```

3. **Deploy infrastructure**:
   ```bash
   # Initialize Terraform
   terraform init

   # Review plan
   terraform plan

   # Apply configuration
   terraform apply

   # Save outputs
   terraform output > deployment-info.txt
   ```

4. **Configure kubectl**:
   ```bash
   # Get AKS credentials
   CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
   RG_NAME=$(terraform output -raw resource_group_name)

   az aks get-credentials \
     --resource-group $RG_NAME \
     --name $CLUSTER_NAME

   # Verify connection
   kubectl get nodes
   kubectl get pods -n monitoring
   ```

5. **Access services**:
   ```bash
   # Port forward Grafana
   kubectl port-forward -n monitoring svc/grafana 3000:3000
   # Open: http://localhost:3000

   # Port forward Prometheus
   kubectl port-forward -n monitoring svc/prometheus 9090:9090
   # Open: http://localhost:9090
   ```

### Cost Estimation

| Resource | Monthly Cost (East US) |
|----------|------------------------|
| AKS Control Plane | Free |
| 2x Standard_D2s_v3 nodes | ~$140 |
| Azure Files (100GB) | ~$20 |
| Log Analytics (10GB) | ~$24 |
| Data Transfer (1TB) | ~$87 |
| **Total Estimated** | **~$271/month** |

*Costs vary by region, instance type, and usage*

### Scaling

```bash
# Scale nodes
terraform apply -var="node_count=3"

# Change VM size
terraform apply -var="vm_size=Standard_D4s_v3"

# Scale Prometheus replicas
terraform apply -var="prometheus_replicas=2"

# Manual kubectl scaling
kubectl scale deployment prometheus --replicas=2 -n monitoring
```

## Comparison: AWS vs Azure

| Feature | AWS ECS | Azure AKS |
|---------|---------|-----------|
| **Deployment Model** | Serverless containers | Managed Kubernetes |
| **Learning Curve** | Lower (simpler) | Higher (K8s knowledge) |
| **Flexibility** | Medium | High (full K8s) |
| **Cost (2 instances)** | ~$143/month | ~$271/month |
| **Auto-scaling** | ECS Service + Target Tracking | HPA + Cluster Autoscaler |
| **Monitoring** | CloudWatch + Container Insights | Azure Monitor + Container Insights |
| **Storage** | EFS | Azure Files |
| **Best For** | Simpler workloads, AWS-native | Complex workloads, K8s standard |

## Common Operations

### Updating Services

#### AWS ECS
```bash
# Update task definition with new image
terraform apply -var="prometheus_image_tag=v2.45.0"

# Force new deployment
aws ecs update-service \
  --cluster <cluster-name> \
  --service prometheus-production \
  --force-new-deployment
```

#### Azure AKS
```bash
# Update Helm release
cd ../../kubernetes/helm
helm upgrade monitoring ./monitoring \
  --set prometheus.image.tag=v2.45.0 \
  -n monitoring

# Or use kubectl
kubectl set image deployment/prometheus \
  prometheus=prom/prometheus:v2.45.0 \
  -n monitoring
```

### Viewing Logs

#### AWS ECS
```bash
# Via AWS CLI
aws logs tail /ecs/monitoring-production \
  --follow \
  --filter-pattern "ERROR"

# Via CloudWatch Insights
# Navigate to: CloudWatch → Log Insights
```

#### Azure AKS
```bash
# Via kubectl
kubectl logs -f deployment/prometheus -n monitoring

# Via Azure Monitor
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query 'ContainerLog | where Name == "prometheus"'
```

### Backup and Disaster Recovery

#### AWS ECS
```bash
# Backup EFS
aws backup start-backup-job \
  --backup-vault-name monitoring-vault \
  --resource-arn <efs-arn> \
  --iam-role-arn <backup-role-arn>

# Backup to S3 (manual)
aws efs create-access-point ...
# Mount and copy to S3
```

#### Azure AKS
```bash
# Using Velero
velero install --provider azure \
  --plugins velero/velero-plugin-for-microsoft-azure:v1.7.0 \
  --bucket velero-backups \
  --backup-location-config resourceGroup=<rg>,storageAccount=<sa>

# Create backup
velero backup create monitoring-backup \
  --include-namespaces monitoring
```

### Destroying Infrastructure

```bash
# AWS
cd cloud/aws
terraform destroy

# Azure
cd cloud/azure
terraform destroy

# Confirm by typing: yes
```

## Security Best Practices

### AWS
- ✅ Enable ECS Container Insights
- ✅ Use Secrets Manager for sensitive data
- ✅ Enable VPC Flow Logs
- ✅ Use IAM roles (not access keys)
- ✅ Enable ALB access logs
- ✅ Encrypt EFS at rest and in transit
- ✅ Use security groups to limit access
- ✅ Regular AMI/image updates

### Azure
- ✅ Enable Azure Policy
- ✅ Use Azure Key Vault for secrets
- ✅ Enable NSG flow logs
- ✅ Use managed identities
- ✅ Enable diagnostic settings
- ✅ Encrypt storage with CMK
- ✅ Use Azure Firewall for egress
- ✅ Regular node pool upgrades

## Monitoring Integration

### CloudWatch (AWS)
```hcl
# Already configured in main.tf
# View metrics at:
# CloudWatch → Container Insights → ECS

# Custom metrics
aws cloudwatch put-metric-data \
  --namespace DevOps/Monitoring \
  --metric-name PrometheusUp \
  --value 1
```

### Azure Monitor
```hcl
# Already configured in main.tf
# View at:
# Azure Monitor → Containers → AKS Cluster

# Query logs
az monitor log-analytics query \
  --workspace <id> \
  --analytics-query 'KubePodInventory | summarize count() by Namespace'
```

## Troubleshooting

### AWS ECS Issues

**Task won't start**:
```bash
# Check task events
aws ecs describe-tasks \
  --cluster <cluster> \
  --tasks <task-arn>

# Check service events
aws ecs describe-services \
  --cluster <cluster> \
  --services prometheus-production
```

**Can't pull image**:
```bash
# Verify ECR permissions
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
```

### Azure AKS Issues

**Pod won't start**:
```bash
# Check events
kubectl describe pod <pod-name> -n monitoring

# Check logs
kubectl logs <pod-name> -n monitoring --previous
```

**Node issues**:
```bash
# Check node status
kubectl get nodes
kubectl describe node <node-name>

# Azure-specific
az aks show \
  --resource-group <rg> \
  --name <cluster>
```

## Production Checklist

Before going to production:

### AWS
- [ ] Configure HTTPS with ACM certificate on ALB
- [ ] Set up AWS Backup for EFS
- [ ] Enable CloudTrail for auditing
- [ ] Configure Budget alerts
- [ ] Set up Route53 for custom domain
- [ ] Enable AWS Config for compliance
- [ ] Review IAM policies (principle of least privilege)
- [ ] Set up CloudWatch alarms for cost anomalies

### Azure
- [ ] Configure TLS with cert-manager
- [ ] Set up Velero for backups
- [ ] Enable Azure AD integration
- [ ] Configure Budget alerts
- [ ] Set up Azure DNS for custom domain
- [ ] Enable Microsoft Defender for Containers
- [ ] Review RBAC policies
- [ ] Set up Cost Management alerts

## Support and Resources

### AWS Resources
- [ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Fargate Pricing](https://aws.amazon.com/fargate/pricing/)
- [AWS Support](https://console.aws.amazon.com/support/)

### Azure Resources
- [AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [AKS Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Azure Support](https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade)

### Terraform Resources
- [AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

**Choose AWS ECS** for simpler deployments and lower costs.
**Choose Azure AKS** for Kubernetes standardization and portability.
