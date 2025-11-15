# DevSecOps - Security-First Development

Comprehensive security implementation covering secrets management, vulnerability scanning, policy enforcement, and compliance.

## Overview

This directory implements a complete DevSecOps strategy with:
- **Secrets Management**: HashiCorp Vault for centralized secrets
- **Security Scanning**: SAST, DAST, dependency, container, and IaC scanning
- **Policy as Code**: OPA policies for Kubernetes, Terraform, and Docker
- **Compliance**: CIS benchmarks and regulatory compliance checks
- **Continuous Security**: Automated scanning in CI/CD pipelines

## Directory Structure

```
security/
├── vault/                  # HashiCorp Vault deployment
│   ├── docker-compose.yml # Docker deployment
│   ├── config/           # Vault configuration files
│   ├── demo-app/         # Integration examples
│   └── kubernetes/       # Kubernetes deployment
├── opa/                   # Open Policy Agent policies
│   └── policies/         # Policy definitions
│       ├── kubernetes-policies.rego
│       ├── terraform-policies.rego
│       └── dockerfile-policies.rego
├── scanning/              # Security scanning configurations
├── compliance/            # Compliance checks and benchmarks
│   └── cis-kubernetes-benchmark.yaml
└── README.md             # This file
```

## Secrets Management with Vault

### Overview

HashiCorp Vault provides:
- ✅ Centralized secrets storage
- ✅ Dynamic secrets with automatic rotation
- ✅ Encryption as a service
- ✅ Fine-grained access control (policies)
- ✅ Audit logging of all operations
- ✅ Multiple authentication methods

### Quick Start (Docker)

```bash
cd security/vault

# Start Vault and demo app
docker-compose up -d

# Access Vault UI
open http://localhost:8200
# Token: devroot

# View demo app logs
docker logs -f vault-demo-app
```

The demo application demonstrates:
1. **Static secrets** (KV v2 store)
2. **Dynamic database credentials** (PostgreSQL)
3. **Encryption as a service** (Transit engine)
4. **Access control policies**
5. **Audit logging**
6. **Kubernetes authentication**

### Vault Deployment (Kubernetes)

```bash
# Deploy Vault to Kubernetes
kubectl apply -f vault/kubernetes/vault-deployment.yaml

# Check status
kubectl get pods -n vault

# Access Vault
kubectl port-forward -n vault svc/vault 8200:8200

# Initialize Vault (first time only)
kubectl exec -n vault vault-0 -- vault operator init
```

### Using Vault in Applications

#### Python Example
```python
import hvac

# Connect to Vault
client = hvac.Client(url='http://vault:8200', token='your-token')

# Read secret
secret = client.secrets.kv.v2.read_secret_version(path='app/config')
db_password = secret['data']['data']['password']

# Generate dynamic DB credentials
creds = client.secrets.database.generate_credentials(name='readonly')
username = creds['data']['username']
password = creds['data']['password']

# Encrypt sensitive data
encrypted = client.secrets.transit.encrypt_data(
    name='customer-data',
    plaintext=base64.b64encode(b'sensitive data')
)
```

#### Kubernetes Service Account Auth
```bash
# Enable Kubernetes auth
vault auth enable kubernetes

# Configure Kubernetes
vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

# Create role
vault write auth/kubernetes/role/myapp \
    bound_service_account_names=myapp \
    bound_service_account_namespaces=default \
    policies=app-policy \
    ttl=24h
```

### Vault Best Practices

**Production Setup**:
- ✅ Enable TLS/HTTPS
- ✅ Use proper storage backend (Consul, etcd, cloud storage)
- ✅ Implement auto-unseal (AWS KMS, Azure Key Vault, GCP KMS)
- ✅ Set up high availability (3+ nodes)
- ✅ Regular backups of storage backend
- ✅ Enable audit logging
- ✅ Rotate root tokens regularly
- ✅ Use namespaces for multi-tenancy

**Access Control**:
- Principle of least privilege
- Use policies to restrict access
- Regular policy audits
- Time-bound tokens
- MFA for sensitive operations

## Security Scanning

### SAST (Static Application Security Testing)

Automated code analysis in CI/CD:

**Tools**:
- **Semgrep**: Multi-language security patterns
- **Bandit**: Python security linter
- **Safety**: Python dependency vulnerabilities
- **Gitleaks**: Secret detection in git history
- **TruffleHog**: Deep secret scanning

**Run Locally**:
```bash
# Semgrep
docker run --rm -v "${PWD}:/src" returntocorp/semgrep semgrep --config=auto /src

# Bandit (Python)
pip install bandit
bandit -r scripts/python/ -f json -o bandit-report.json

# Gitleaks
docker run --rm -v "${PWD}:/path" zricethezav/gitleaks:latest detect --source="/path"
```

### DAST (Dynamic Application Security Testing)

Runtime security testing:

**Tools**:
- **OWASP ZAP**: Comprehensive web app scanner
- **Nikto**: Web server scanner
- **testssl.sh**: SSL/TLS configuration tester

**Run OWASP ZAP**:
```bash
# Baseline scan (passive)
docker run -v $(pwd):/zap/wrk/:rw -t owasp/zap2docker-stable \
    zap-baseline.py -t http://localhost:3000 -r zap-report.html

# Full scan (active)
docker run -v $(pwd):/zap/wrk/:rw -t owasp/zap2docker-stable \
    zap-full-scan.py -t http://localhost:3000 -r zap-full-report.html
```

### Container Security

**Tools**:
- **Trivy**: Comprehensive vulnerability scanner
- **Grype**: Vulnerability scanner (Anchore)
- **Dockle**: Docker best practices checker

**Scan Container Image**:
```bash
# Trivy
trivy image myimage:latest

# Trivy with SARIF output (for GitHub)
trivy image --format sarif --output trivy-results.sarif myimage:latest

# Grype
grype myimage:latest

# Dockle (best practices)
dockle myimage:latest
```

### Infrastructure as Code Security

**Tools**:
- **Checkov**: Terraform/Kubernetes/Dockerfile scanner
- **tfsec**: Terraform security scanner
- **KICS**: Infrastructure as Code scanner

**Scan Terraform**:
```bash
# Checkov
checkov -d terraform/

# tfsec
tfsec terraform/

# KICS
docker run -v $(pwd):/path checkmarx/kics scan -p /path/terraform
```

### CI/CD Integration

Security scans run automatically on:
- **Every push** to main/develop
- **Every pull request**
- **Daily schedule** (comprehensive scan)
- **Manual trigger** via workflow_dispatch

View results:
- **Security tab** in GitHub
- **SARIF reports** for detailed findings
- **Artifacts** for full scan reports

## Policy as Code (OPA)

### Overview

Open Policy Agent (OPA) enforces security policies across:
- Kubernetes admission control
- Terraform plan validation
- Dockerfile best practices
- CI/CD pipeline gates

### Kubernetes Policies

**Enforced Rules** (`opa/policies/kubernetes-policies.rego`):
- ✅ No containers running as root
- ✅ Resource limits and requests required
- ✅ No privileged containers
- ✅ No hostNetwork/hostPID/hostIPC
- ✅ No 'latest' image tags
- ✅ Images only from trusted registries
- ✅ Required labels (app, environment, owner)
- ✅ Secrets must be encrypted
- ✅ Readiness and liveness probes required
- ✅ Reasonable resource limits

**Deploy OPA to Kubernetes**:
```bash
# Install OPA Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml

# Create constraint template
kubectl apply -f opa/templates/

# Apply policies
kubectl apply -f opa/policies/
```

**Test Policy**:
```bash
# Test with OPA CLI
opa test opa/policies/

# Test against sample manifests
opa eval --data opa/policies/kubernetes-policies.rego \
    --input kubernetes/manifests/prometheus.yaml \
    'data.kubernetes.admission.deny'
```

### Terraform Policies

**Enforced Rules** (`opa/policies/terraform-policies.rego`):
- ✅ S3 buckets must be encrypted
- ✅ No public S3 buckets
- ✅ Security groups: no 0.0.0.0/0 (except 80/443)
- ✅ RDS encryption required
- ✅ RDS backup retention >= 7 days
- ✅ No wildcard IAM policies
- ✅ VPC flow logs required
- ✅ EBS encryption required
- ✅ Required tags on resources
- ✅ Azure: HTTPS-only storage
- ✅ Azure: AKS RBAC required

**Validate Terraform Plan**:
```bash
# Generate plan
cd terraform/
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# Validate with OPA
opa eval --data ../security/opa/policies/terraform-policies.rego \
    --input tfplan.json \
    'data.terraform.analysis.deny'
```

### Dockerfile Policies

**Enforced Rules** (`opa/policies/dockerfile-policies.rego`):
- ✅ No 'latest' tags
- ✅ Must specify USER (no root)
- ✅ Images only from trusted registries
- ✅ HEALTHCHECK recommended
- ✅ Use COPY instead of ADD
- ✅ No dangerous ports (22, 23, 3389, 5900)
- ✅ No secrets in ENV
- ✅ Maintainer label required
- ✅ apt-get with --no-install-recommends
- ✅ Clean up package manager cache
- ✅ No curl piped to bash
- ✅ No chmod 777

**Test Dockerfile**:
```bash
# Use dockerfile-json to convert Dockerfile to JSON
npm install -g dockerfile-json
dockerfile-json < Dockerfile > dockerfile.json

# Validate with OPA
opa eval --data security/opa/policies/dockerfile-policies.rego \
    --input dockerfile.json \
    'data.dockerfile.analysis.deny'
```

## Compliance

### CIS Benchmarks

**Kubernetes CIS Benchmark**: `compliance/cis-kubernetes-benchmark.yaml`

Covers:
- Control plane configuration
- etcd security
- Worker node configuration
- Pod Security Standards
- Network policies
- RBAC

**Run CIS Benchmark**:
```bash
# Using kube-bench
kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml

# View results
kubectl logs -l app=kube-bench

# Or run directly
docker run --rm -v /etc/kubernetes:/etc/kubernetes \
    aquasec/kube-bench:latest --json
```

### Regulatory Compliance

**Supported Frameworks**:
- **HIPAA**: Healthcare data protection
- **PCI-DSS**: Payment card industry
- **SOC 2**: Service organization controls
- **GDPR**: Data privacy (EU)
- **NIST 800-53**: Federal security controls

**Compliance Automation**:
```bash
# Check compliance with Checkov
checkov -d . --framework kubernetes --check CKV_K8S_*

# Export compliance report
checkov -d . --output json --output-file compliance-report.json
```

## Security Best Practices

### Development

1. **Never commit secrets**
   - Use Vault for all secrets
   - Add `.env` to `.gitignore`
   - Use pre-commit hooks (gitleaks)

2. **Dependency management**
   - Pin versions in requirements.txt
   - Regular dependency updates
   - Automated vulnerability scanning

3. **Code review**
   - Security-focused code reviews
   - Automated SAST in PR checks
   - Require approvals for security changes

### CI/CD

1. **Security gates**
   - Block builds on critical vulnerabilities
   - Policy validation before deployment
   - Signed container images

2. **Least privilege**
   - Minimal CI/CD permissions
   - Short-lived credentials
   - Audit all pipeline changes

3. **Artifact security**
   - Sign Docker images
   - SBOM generation
   - Vulnerability tracking

### Infrastructure

1. **Network security**
   - Network policies in Kubernetes
   - Security groups/NSGs
   - Private subnets for workloads

2. **Encryption**
   - TLS for all communication
   - Encryption at rest
   - Key rotation policies

3. **Access control**
   - RBAC in Kubernetes
   - IAM roles (least privilege)
   - MFA for production access

### Monitoring

1. **Security monitoring**
   - Audit log analysis
   - Anomaly detection
   - Intrusion detection

2. **Compliance monitoring**
   - Continuous compliance checks
   - Drift detection
   - Regular audits

3. **Incident response**
   - Security runbooks
   - Automated remediation
   - Post-incident reviews

## Security Workflows

### GitHub Actions Workflows

**`security-scan.yml`** - Comprehensive security scanning:
- SAST with Semgrep
- Secret scanning (Gitleaks, TruffleHog)
- Dependency scanning (Safety, Snyk)
- Container scanning (Trivy, Grype, Dockle)
- IaC scanning (Checkov, tfsec, KICS)
- License compliance
- SBOM generation

**`dast-scan.yml`** - Dynamic security testing:
- OWASP ZAP scans
- Nikto web server scan
- API security testing
- SSL/TLS configuration check
- Security headers validation

**Run workflows**:
```bash
# Trigger security scan
gh workflow run security-scan.yml

# Trigger DAST scan
gh workflow run dast-scan.yml

# View results
gh run list --workflow=security-scan.yml
```

## Tools Reference

### Essential Security Tools

| Tool | Purpose | Language | License |
|------|---------|----------|---------|
| HashiCorp Vault | Secrets management | Go | MPL 2.0 |
| Open Policy Agent | Policy enforcement | Go | Apache 2.0 |
| Semgrep | SAST | Python | LGPL 2.1 |
| OWASP ZAP | DAST | Java | Apache 2.0 |
| Trivy | Container scanning | Go | Apache 2.0 |
| Grype | Vulnerability scanning | Go | Apache 2.0 |
| Checkov | IaC scanning | Python | Apache 2.0 |
| kube-bench | CIS benchmarks | Go | Apache 2.0 |
| Gitleaks | Secret detection | Go | MIT |

### Installation

**macOS**:
```bash
brew install vault opa trivy grype gitleaks
```

**Linux**:
```bash
# Vault
wget https://releases.hashicorp.com/vault/1.15.0/vault_1.15.0_linux_amd64.zip
unzip vault_1.15.0_linux_amd64.zip
sudo mv vault /usr/local/bin/

# OPA
curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
chmod 755 opa
sudo mv opa /usr/local/bin/

# Trivy
sudo apt-get install trivy
```

## Metrics and Reporting

### Security Metrics

Track these KPIs:
- Time to detect vulnerabilities
- Time to remediate vulnerabilities
- Number of critical/high vulnerabilities
- Policy violation rate
- Secrets rotation frequency
- Security scan coverage

### Reports

Generate security reports:
```bash
# Vulnerability report
trivy image --format json myimage:latest > vuln-report.json

# Compliance report
checkov -d . --output json > compliance-report.json

# License report
pip-licenses --format=json > licenses.json

# SBOM
syft packages dir:. -o spdx-json > sbom.json
```

## Incident Response

### Security Incident Process

1. **Detection**: Automated alerts + monitoring
2. **Triage**: Assess severity and impact
3. **Containment**: Isolate affected systems
4. **Remediation**: Fix vulnerability
5. **Recovery**: Restore services
6. **Post-mortem**: Document and improve

### Emergency Contacts

- **Security Team**: `#security-incidents` (Slack)
- **On-call Security Engineer**: PagerDuty
- **CISO**: escalation@company.com

## Additional Resources

### Documentation
- [Vault Documentation](https://www.vaultproject.io/docs)
- [OPA Documentation](https://www.openpolicyagent.org/docs)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

### Training
- [Kubernetes Security Specialist (CKS)](https://training.linuxfoundation.org/certification/certified-kubernetes-security-specialist/)
- [OWASP Web Security Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [HashiCorp Vault Associate Certification](https://www.hashicorp.com/certification/vault-associate)

### Community
- [OWASP Community](https://owasp.org/)
- [Cloud Native Security](https://www.cncf.io/projects/)
- [DevSecOps Community](https://www.devsecops.org/)

---

**Security is not a feature, it's a continuous practice.** 🔒
