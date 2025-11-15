# Terraform Security Policies with OPA
# Enforce security and compliance for infrastructure as code

package terraform.analysis

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# Deny unencrypted S3 buckets (AWS)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not resource.change.after.server_side_encryption_configuration
    msg := sprintf("S3 bucket %v must have encryption enabled", [resource.address])
}

# Deny S3 buckets with public access (AWS)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.change.after.block_public_acls == false
    msg := sprintf("S3 bucket %v must block public ACLs", [resource.address])
}

# Deny security groups with 0.0.0.0/0 ingress (AWS)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    some rule in resource.change.after.ingress
    rule.cidr_blocks[_] == "0.0.0.0/0"
    not rule.from_port == 443
    not rule.from_port == 80
    msg := sprintf("Security group %v has overly permissive ingress from 0.0.0.0/0", [resource.address])
}

# Deny RDS instances without encryption (AWS)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.storage_encrypted == false
    msg := sprintf("RDS instance %v must have storage encryption enabled", [resource.address])
}

# Deny RDS instances without backup retention (AWS)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.backup_retention_period < 7
    msg := sprintf("RDS instance %v must have backup retention >= 7 days", [resource.address])
}

# Deny IAM policies with wildcard resources (AWS)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy"
    doc := json.unmarshal(resource.change.after.policy)
    some statement in doc.Statement
    statement.Effect == "Allow"
    statement.Resource == "*"
    statement.Action[_] != "s3:GetObject"  # Allow specific exceptions
    msg := sprintf("IAM policy %v should not use wildcard (*) resources", [resource.address])
}

# Require VPC flow logs (AWS)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_vpc"
    not has_flow_logs(resource.address)
    msg := sprintf("VPC %v must have flow logs enabled", [resource.address])
}

has_flow_logs(vpc_address) {
    some resource in input.resource_changes
    resource.type == "aws_flow_log"
    contains(resource.change.after.vpc_id, vpc_address)
}

# Deny unencrypted EBS volumes (AWS)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    resource.change.after.encrypted == false
    msg := sprintf("EBS volume %v must be encrypted", [resource.address])
}

# Require tags on all resources (AWS)
deny[msg] {
    resource := input.resource_changes[_]
    startswith(resource.type, "aws_")
    not resource.type in ["aws_route_table_association", "aws_subnet"]
    required_tags := ["Environment", "Owner", "Project"]
    some tag in required_tags
    not resource.change.after.tags[tag]
    msg := sprintf("Resource %v missing required tag: %v", [resource.address, tag])
}

# Deny storage accounts without HTTPS only (Azure)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_storage_account"
    resource.change.after.enable_https_traffic_only == false
    msg := sprintf("Storage account %v must enforce HTTPS only", [resource.address])
}

# Deny AKS without RBAC (Azure)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_kubernetes_cluster"
    resource.change.after.role_based_access_control_enabled == false
    msg := sprintf("AKS cluster %v must have RBAC enabled", [resource.address])
}

# Deny Azure SQL without TDE (Transparent Data Encryption)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_mssql_database"
    not has_tde_enabled(resource.address)
    msg := sprintf("SQL database %v should have TDE enabled", [resource.address])
}

has_tde_enabled(db_address) {
    some resource in input.resource_changes
    resource.type == "azurerm_mssql_database_extended_auditing_policy"
    contains(resource.address, db_address)
}

# Deny public IP on VMs (Azure)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_network_interface"
    some ip_config in resource.change.after.ip_configuration
    ip_config.public_ip_address_id != null
    msg := sprintf("Network interface %v should not have public IP in production", [resource.address])
}

# Require network security groups (Azure)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_subnet"
    not resource.change.after.network_security_group_id
    msg := sprintf("Subnet %v must have network security group attached", [resource.address])
}

# Deny containers without resource limits (Docker provider)
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "docker_container"
    not resource.change.after.memory
    msg := sprintf("Container %v must have memory limits", [resource.address])
}

# Deny Docker containers running as root
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "docker_container"
    resource.change.after.user == "root"
    msg := sprintf("Container %v should not run as root", [resource.address])
}

# Cost control: Warn on expensive instance types
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    expensive_types := ["m5.24xlarge", "c5.24xlarge", "r5.24xlarge"]
    resource.change.after.instance_type in expensive_types
    msg := sprintf("Instance %v uses expensive instance type: %v", [resource.address, resource.change.after.instance_type])
}

# Compliance: HIPAA - require encryption at rest
deny[msg] {
    resource := input.resource_changes[_]
    resource.change.after.tags.Compliance == "HIPAA"
    storage_types := ["aws_ebs_volume", "aws_rds_cluster", "aws_s3_bucket"]
    resource.type in storage_types
    not is_encrypted(resource)
    msg := sprintf("HIPAA resource %v must be encrypted", [resource.address])
}

is_encrypted(resource) {
    resource.change.after.encrypted == true
}

is_encrypted(resource) {
    resource.change.after.storage_encrypted == true
}

is_encrypted(resource) {
    resource.change.after.server_side_encryption_configuration
}

# Compliance: PCI-DSS - require CloudTrail
deny[msg] {
    has_pci_resources
    not has_cloudtrail
    msg := "PCI-DSS compliance requires CloudTrail to be enabled"
}

has_pci_resources {
    some resource in input.resource_changes
    resource.change.after.tags.Compliance == "PCI-DSS"
}

has_cloudtrail {
    some resource in input.resource_changes
    resource.type == "aws_cloudtrail"
    resource.change.after.is_multi_region_trail == true
}

# Best practice: Enable versioning on S3 buckets
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not has_versioning(resource.address)
    msg := sprintf("S3 bucket %v should enable versioning", [resource.address])
}

has_versioning(bucket_address) {
    some resource in input.resource_changes
    resource.type == "aws_s3_bucket_versioning"
    contains(resource.change.after.bucket, bucket_address)
}
