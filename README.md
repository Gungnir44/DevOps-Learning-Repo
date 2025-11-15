# DevOps Learning Journey

[![CI - Test and Lint](https://github.com/Gungnir44/DevOps-Learning-Repo/actions/workflows/ci.yml/badge.svg)](https://github.com/Gungnir44/DevOps-Learning-Repo/actions/workflows/ci.yml)
[![Docker Build and Push](https://github.com/Gungnir44/DevOps-Learning-Repo/actions/workflows/docker-build.yml/badge.svg)](https://github.com/Gungnir44/DevOps-Learning-Repo/actions/workflows/docker-build.yml)
[![Deploy](https://github.com/Gungnir44/DevOps-Learning-Repo/actions/workflows/deploy.yml/badge.svg)](https://github.com/Gungnir44/DevOps-Learning-Repo/actions/workflows/deploy.yml)

**Author**: Joshua
**Background**: Software Engineering & Cyber Security
**Goal**: Master DevOps practices and build a comprehensive portfolio

---

## About This Repository

This repository documents my journey learning DevOps from the ground up. It contains hands-on projects, automation scripts, infrastructure code, and real-world implementations of DevOps practices.

### Why DevOps?

Read my detailed analysis: [why-devops-is-important.txt](./why-devops-is-important.txt)

---

## Learning Roadmap

### Phase 1: Foundation ✅ COMPLETED
- [x] Linux & Command Line
- [x] Git & Version Control
- [x] Shell Scripting & Python Automation
- [x] Networking Basics
- [x] System Health Monitoring
- [x] Email Alerting
- [x] Automated Scheduling

**Project**: DevOps Toolbox - Automation scripts with monitoring and alerts

### Phase 2: Containerization ✅ COMPLETED
- [x] Docker fundamentals
- [x] Docker Compose orchestration
- [x] Container networking & storage
- [x] Multi-container applications (16 containers!)
- [x] Volume management & persistence
- [x] Health checks & restart policies
- [x] Multi-stage builds
- [x] Database integration (PostgreSQL, MySQL, MongoDB, Redis)
- [x] Message queue (RabbitMQ)
- [x] **Observability Stack (Prometheus + Grafana + ELK)**
- [x] **Metrics collection & exporters**
- [x] **Production monitoring patterns**

**Project**: Enterprise-grade monitoring and observability platform
**Tech Stack**:
- Monitoring: Prometheus, Grafana, cAdvisor
- Logging: Elasticsearch, Kibana
- Databases: PostgreSQL, MySQL, MongoDB, Redis
- Infrastructure: Docker Compose, 16 containers

**Guides**:
- Quick Start: [docker/DOCKER_QUICK_START.md](./docker/DOCKER_QUICK_START.md)
- Observability: [docker/OBSERVABILITY_GUIDE.md](./docker/OBSERVABILITY_GUIDE.md)

### Phase 3: CI/CD Pipeline ✅ COMPLETED
- [x] GitHub Actions workflows
- [x] Automated testing (pytest with coverage)
- [x] Code quality checks (flake8, black, pylint)
- [x] Security scanning (safety, bandit, trivy)
- [x] Docker image building and pushing
- [x] Multi-stage deployment workflows
- [x] CI/CD badges and status reporting

**Project**: Production-ready CI/CD pipeline with automated testing and deployment
**Tech Stack**:
- CI/CD: GitHub Actions
- Testing: pytest, pytest-cov
- Linting: flake8, black, pylint
- Security: bandit, safety, trivy
- Containerization: Docker multi-stage builds

**Workflows**:
- CI: Automated testing, linting, and security scans on every push
- Docker Build: Automated image builds with vulnerability scanning
- Integration Tests: Full stack testing with Docker services
- Deploy: Manual deployment to multiple environments

**Development Tools**:
- Makefile: Quick commands for common tasks
- Pre-commit hooks: Automated code quality checks before commit
- Pytest configuration: Organized test execution with markers
- Integration tests: Real-world Docker stack testing

### Phase 4: Infrastructure as Code ✅ COMPLETED
- [x] Terraform infrastructure provisioning
- [x] Ansible configuration management
- [x] Docker provider integration
- [x] State management
- [x] Variables and outputs
- [x] Ansible roles and playbooks
- [x] Inventory management

**Project**: Automated infrastructure provisioning and configuration
**Tech Stack**:
- Terraform: Infrastructure provisioning (Docker, networks, containers)
- Ansible: Configuration management and deployment
- Variables: Environment-specific configurations
- Modules: Reusable infrastructure components

**Features**:
- Declarative infrastructure definitions
- Automated provisioning with Terraform
- Configuration management with Ansible
- State tracking and management
- Idempotent operations
- Environment separation (dev/staging/prod)

### Phase 5: Container Orchestration ✅ COMPLETED
- [x] Kubernetes fundamentals
- [x] Helm charts
- [x] Deployments and StatefulSets
- [x] Services (ClusterIP, NodePort)
- [x] ConfigMaps and Secrets
- [x] Resource management
- [x] Probes and health checks
- [x] Persistent storage

**Project**: Deploy monitoring stack on Kubernetes with Helm
**Tech Stack**:
- Kubernetes: Container orchestration
- Helm: Package manager for Kubernetes
- Manifests: Deployments, Services, ConfigMaps, Secrets
- StatefulSets: Stateful applications (PostgreSQL)

**Features**:
- Complete Kubernetes manifests for monitoring stack
- Helm chart with customizable values
- Resource limits and requests
- Liveness and readiness probes
- Persistent volume claims
- Namespace isolation
- Service discovery

### Phase 6: Cloud & Monitoring ✅ COMPLETED
- [x] AWS ECS Fargate deployment
- [x] Azure AKS deployment
- [x] Prometheus AlertManager configuration
- [x] Comprehensive alert rules (infrastructure, containers, databases, applications)
- [x] Incident response runbooks
- [x] CloudWatch and Azure Monitor integration
- [x] Auto-scaling configuration
- [x] High availability setup

**Project**: Production-ready cloud deployments with advanced alerting
**Tech Stack**:
- Cloud: AWS ECS Fargate, Azure AKS
- IaC: Terraform for AWS and Azure
- Alerting: Prometheus AlertManager
- Monitoring: CloudWatch, Azure Monitor, Container Insights
- Notifications: Email, Slack, PagerDuty

**Features**:
- Multi-cloud deployment configurations (AWS + Azure)
- 50+ alert rules covering infrastructure, containers, databases, and applications
- Detailed incident response runbooks with step-by-step procedures
- Auto-scaling based on CPU utilization
- Persistent storage with EFS (AWS) and Azure Files
- High availability across multiple availability zones
- Production-grade security (encryption, IAM, RBAC)

**Guides**:
- Cloud Deployment: [cloud/README.md](./cloud/README.md)
- Monitoring & Alerting: [monitoring/README.md](./monitoring/README.md)
- Incident Runbooks: [monitoring/runbooks/](./monitoring/runbooks/)

### Phase 7: DevSecOps ✅ COMPLETED
- [x] Security scanning (SAST/DAST)
- [x] Secrets management (HashiCorp Vault)
- [x] Policy as Code (Open Policy Agent)
- [x] Compliance scanning (CIS benchmarks)
- [x] Container security scanning
- [x] Infrastructure as Code security
- [x] Secret detection and prevention
- [x] SBOM generation

**Project**: Production-grade security implementation with DevSecOps practices
**Tech Stack**:
- Secrets: HashiCorp Vault (Docker + Kubernetes)
- SAST: Semgrep, Bandit, Gitleaks, TruffleHog
- DAST: OWASP ZAP, Nikto, testssl.sh
- Container Security: Trivy, Grype, Dockle
- IaC Security: Checkov, tfsec, KICS
- Policy Enforcement: Open Policy Agent (OPA)
- Compliance: CIS Kubernetes Benchmark, HIPAA, PCI-DSS

**Features**:
- HashiCorp Vault deployment (Docker and Kubernetes)
- Demo application showing Vault integration
- Static secrets, dynamic secrets, encryption as a service
- Comprehensive security scanning workflows (7 different scanners)
- DAST scanning with OWASP ZAP
- Policy as Code: 50+ security policies for Kubernetes, Terraform, Docker
- CIS Kubernetes Benchmark compliance checks
- Automated security scans in CI/CD
- SBOM (Software Bill of Materials) generation
- License compliance checking

**Guides**:
- Security Overview: [security/README.md](./security/README.md)
- Vault Integration: [security/vault/](./security/vault/)
- OPA Policies: [security/opa/policies/](./security/opa/policies/)
- Compliance: [security/compliance/](./security/compliance/)

---

## Repository Structure

```
.
├── scripts/
│   ├── python/          # Python automation scripts
│   └── bash/            # Bash scripts for system tasks
├── docker/              # Dockerfiles and compose files
├── kubernetes/          # K8s manifests and Helm charts
├── terraform/           # Infrastructure as Code (local)
├── ansible/             # Configuration management playbooks
├── cloud/               # Cloud deployment (AWS ECS, Azure AKS)
│   ├── aws/            # AWS ECS Fargate deployment
│   └── azure/          # Azure AKS deployment
├── monitoring/          # Advanced alerting and incident response
│   ├── alertmanager/   # AlertManager configuration
│   ├── alert-rules/    # Prometheus alert definitions
│   └── runbooks/       # Incident response procedures
├── security/            # DevSecOps and security automation
│   ├── vault/          # HashiCorp Vault deployment
│   ├── opa/            # Open Policy Agent policies
│   ├── scanning/       # Security scanning configs
│   └── compliance/     # Compliance checks (CIS, etc.)
├── .github/workflows/   # GitHub Actions CI/CD + Security
├── ci-cd/               # Pipeline configurations
├── docs/                # Documentation and learning notes
└── projects/            # Complete project implementations
```

---

## Projects Portfolio

### 1. DevOps Toolbox (Phase 1)
**Status**: In Progress
**Description**: Collection of automation scripts for common DevOps tasks
**Tech Stack**: Python, Bash, Git
**Skills Demonstrated**: Scripting, automation, version control

- System health monitoring
- Log analysis and parsing
- Automated backups
- Network diagnostics

### 2. Containerized Microservices (Phase 2)
**Status**: Planned
**Tech Stack**: Docker, Docker Compose, Python/Node.js

### 3. CI/CD Pipeline (Phase 3)
**Status**: Planned
**Tech Stack**: GitHub Actions, Jenkins, Docker

### 4. Infrastructure Automation (Phase 4)
**Status**: Planned
**Tech Stack**: Terraform, Ansible, AWS

### 5. Kubernetes Deployment (Phase 5)
**Status**: Planned
**Tech Stack**: Kubernetes, Helm, Docker

### 6. Full-Stack Observability (Phase 6)
**Status**: Planned
**Tech Stack**: Prometheus, Grafana, ELK Stack

### 7. Secure DevOps Pipeline (Phase 7)
**Status**: Planned
**Tech Stack**: HashiCorp Vault, Trivy, SonarQube

---

## Skills & Tools

### Currently Learning
- Linux system administration
- Python scripting for automation
- Git workflow and best practices
- Docker basics

### Tools to Master
**Version Control**: Git, GitHub
**Containerization**: Docker, Podman
**Orchestration**: Kubernetes, Docker Swarm
**CI/CD**: GitHub Actions, Jenkins, GitLab CI
**IaC**: Terraform, CloudFormation
**Configuration Management**: Ansible, Chef
**Cloud Platforms**: AWS, Azure, GCP
**Monitoring**: Prometheus, Grafana, Datadog
**Logging**: ELK Stack, Fluentd
**Security**: Vault, Trivy, Aqua Security
**Scripting**: Python, Bash, PowerShell

---

## Daily Log

### Week 1
- **Day 1**: Set up DevOps learning repository structure
  - Initialized Git repository
  - Created project organization
  - Documented DevOps importance
  - Built first automation script: System Health Checker

---

## Resources

### Books
- "The Phoenix Project" by Gene Kim
- "The DevOps Handbook" by Gene Kim
- "Site Reliability Engineering" by Google

### Online Courses
- Linux Foundation DevOps courses
- Cloud provider certifications (AWS, Azure)

### Communities
- DevOps subreddit
- CNCF Slack channels
- Local DevOps meetups

---

## Certifications Target

- [ ] AWS Certified DevOps Engineer
- [ ] Certified Kubernetes Administrator (CKA)
- [ ] HashiCorp Certified: Terraform Associate
- [ ] Docker Certified Associate

---

## Connect

Building in public and documenting my DevOps journey. Follow along as I transform from beginner to DevOps engineer!

**Learning Philosophy**: Practice beats theory. Every concept gets a hands-on project.

---

## License

MIT License - Feel free to use these projects and scripts for your own learning journey.

---

**Last Updated**: November 14, 2025
