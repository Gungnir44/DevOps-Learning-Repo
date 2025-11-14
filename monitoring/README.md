# Production Monitoring & Alerting

Advanced monitoring, alerting, and incident response configuration for production environments.

## Overview

This directory contains production-ready configurations for:
- **AlertManager**: Intelligent alert routing and notifications
- **Alert Rules**: Comprehensive Prometheus alert definitions
- **Incident Runbooks**: Detailed response procedures for common incidents
- **Cloud Integration**: CloudWatch and Azure Monitor integration

## Directory Structure

```
monitoring/
├── alertmanager/           # AlertManager configuration
│   └── alertmanager.yml   # Notification routing and receivers
├── alert-rules/           # Prometheus alert rules
│   ├── infrastructure-alerts.yml   # CPU, memory, disk, network
│   ├── container-alerts.yml        # Docker, Kubernetes alerts
│   ├── database-alerts.yml         # Database-specific alerts
│   └── application-alerts.yml      # Application and SLO alerts
└── runbooks/              # Incident response procedures
    ├── high-cpu-usage.md
    ├── database-down.md
    └── pod-crash-looping.md
```

## AlertManager Setup

### Features
- **Multi-channel notifications**: Email, Slack, PagerDuty
- **Intelligent routing**: Route alerts by severity and category
- **Alert grouping**: Prevent alert storms
- **Inhibition rules**: Suppress redundant alerts

### Quick Start

1. **Configure notification channels** in `alertmanager/alertmanager.yml`:
   ```yaml
   global:
     smtp_smarthost: 'smtp.gmail.com:587'
     smtp_from: 'your-email@gmail.com'
     smtp_auth_username: 'your-email@gmail.com'
     smtp_auth_password: 'your-app-password'
   ```

2. **Add Slack webhook**:
   ```yaml
   slack_configs:
     - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
       channel: '#alerts'
   ```

3. **Add PagerDuty key** (for critical alerts):
   ```yaml
   pagerduty_configs:
     - service_key: 'YOUR_PAGERDUTY_SERVICE_KEY'
   ```

### Deployment

#### Docker Compose
```yaml
alertmanager:
  image: prom/alertmanager:latest
  ports:
    - "9093:9093"
  volumes:
    - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
  command:
    - '--config.file=/etc/alertmanager/alertmanager.yml'
    - '--storage.path=/alertmanager'
```

#### Kubernetes
```bash
# Create ConfigMap
kubectl create configmap alertmanager-config \
  --from-file=alertmanager.yml=alertmanager/alertmanager.yml \
  -n monitoring

# Deploy AlertManager
kubectl apply -f kubernetes/manifests/alertmanager.yaml
```

#### Configure Prometheus
Add AlertManager to Prometheus configuration:
```yaml
# prometheus.yml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

rule_files:
  - /etc/prometheus/alert-rules/*.yml
```

## Alert Rules

### Infrastructure Alerts
**File**: `alert-rules/infrastructure-alerts.yml`

Coverage:
- ✅ CPU usage (warning: >80%, critical: >95%)
- ✅ Memory usage (warning: >80%, critical: >95%)
- ✅ Disk space (warning: >80%, critical: >95%)
- ✅ Disk fill prediction (4-hour forecast)
- ✅ High I/O wait
- ✅ Network errors and high traffic
- ✅ Node down detection

### Container & Kubernetes Alerts
**File**: `alert-rules/container-alerts.yml`

Coverage:
- ✅ Container high CPU/memory
- ✅ Container restarting
- ✅ Container down
- ✅ Pod crash looping
- ✅ Pod not ready
- ✅ Deployment replica mismatch
- ✅ PVC pending
- ✅ Node conditions (NotReady, MemoryPressure, DiskPressure)

### Database Alerts
**File**: `alert-rules/database-alerts.yml`

Coverage:
- ✅ Database down (PostgreSQL, MySQL, MongoDB, Redis)
- ✅ Too many connections
- ✅ Slow queries
- ✅ High rollback rate (PostgreSQL)
- ✅ Deadlocks
- ✅ Replication lag
- ✅ Out of memory (Redis)
- ✅ High fragmentation (Redis)

### Application & SLO Alerts
**File**: `alert-rules/application-alerts.yml`

Coverage:
- ✅ Service down
- ✅ High error rate (>5% warning, >10% critical)
- ✅ High response time (p95 > 1s)
- ✅ RabbitMQ queue buildup
- ✅ Batch job failures
- ✅ SSL certificate expiration
- ✅ SLO budget burn rate
- ✅ Availability and latency SLO violations

### Loading Alert Rules

#### Docker Prometheus
```yaml
volumes:
  - ./alert-rules:/etc/prometheus/alert-rules:ro
command:
  - '--config.file=/etc/prometheus/prometheus.yml'
  - '--storage.tsdb.path=/prometheus'
```

#### Kubernetes ConfigMap
```bash
kubectl create configmap prometheus-rules \
  --from-file=alert-rules/ \
  -n monitoring
```

## Incident Runbooks

Detailed step-by-step procedures for responding to common incidents.

### Available Runbooks

| Runbook | Severity | Estimated Resolution Time |
|---------|----------|---------------------------|
| [High CPU Usage](./runbooks/high-cpu-usage.md) | Warning/Critical | 15-30 min |
| [Database Down](./runbooks/database-down.md) | Critical | 10-60 min |
| [Pod Crash Looping](./runbooks/pod-crash-looping.md) | Critical | 10-30 min |

### Runbook Structure

Each runbook includes:
1. **Alert Details**: Name, severity, category
2. **Symptoms**: How to recognize the issue
3. **Impact**: User, business, and system impact
4. **Investigation Steps**: Detailed troubleshooting commands
5. **Resolution Steps**: Immediate actions and long-term fixes
6. **Prevention**: How to avoid future occurrences
7. **Escalation**: When and how to escalate
8. **Communication**: Internal and external communication templates
9. **Post-Incident**: Follow-up actions and PIR template

### Using Runbooks

When an alert fires:

1. **Find the runbook**: Match alert name to runbook
2. **Verify the alert**: Confirm the issue exists
3. **Investigate**: Follow investigation steps
4. **Resolve**: Apply appropriate resolution
5. **Communicate**: Update stakeholders
6. **Document**: Track all actions taken
7. **Follow up**: Complete post-incident review

## Alert Severity Levels

| Severity | Description | Response Time | Examples |
|----------|-------------|---------------|----------|
| **Critical** | Service down, data loss risk | Immediate (page on-call) | Database down, >95% CPU |
| **Warning** | Degraded performance, approaching limits | 15 minutes | >80% CPU, slow queries |
| **Info** | FYI, no action needed | Best effort | Backup completed |

## Notification Channels

### Email
- **Use for**: All alerts, detailed information
- **Audience**: Team distribution lists
- **Format**: HTML with full alert details

### Slack
- **Use for**: Real-time team notifications
- **Channels**:
  - `#alerts`: All alerts
  - `#critical-alerts`: Critical only
  - `#database-alerts`: Database team
  - `#infrastructure-alerts`: Infrastructure team
- **Format**: Rich formatted messages with links

### PagerDuty
- **Use for**: Critical alerts requiring immediate response
- **Escalation**: On-call rotation
- **Integration**: Incident management workflow

## Testing Alerts

### Manual Alert Testing
```bash
# Trigger test alert
curl -H "Content-Type: application/json" -d '[{
  "labels": {
    "alertname": "TestAlert",
    "severity": "warning"
  },
  "annotations": {
    "summary": "Test alert",
    "description": "This is a test"
  }
}]' http://localhost:9093/api/v1/alerts

# Check AlertManager UI
open http://localhost:9093
```

### Alert Rule Validation
```bash
# Validate rules syntax
promtool check rules alert-rules/*.yml

# Test specific rule
promtool test rules alert-rules/tests/
```

## Dashboards

### Grafana Alert Dashboards

Import these dashboards to visualize alerts:

1. **Alert Overview**: Dashboard ID 8010
2. **AlertManager**: Dashboard ID 9578
3. **Prometheus Alerts**: Dashboard ID 11098

```bash
# Access Grafana
http://localhost:3000

# Import dashboard
Dashboards → Import → Enter ID → Load
```

## On-Call Best Practices

### 1. Alert Fatigue Prevention
- ✅ Set appropriate thresholds (avoid too sensitive alerts)
- ✅ Use inhibition rules to suppress redundant alerts
- ✅ Group related alerts together
- ✅ Set proper severity levels
- ✅ Review and tune alerts weekly

### 2. Response Workflow
```
Alert Fires → Check Runbook → Investigate → Resolve → Document → Follow Up
```

### 3. Communication
- Update incident status every 15 minutes for critical issues
- Use dedicated Slack channel for incident coordination
- Post-incident review within 24 hours

### 4. Escalation Guidelines
- **Can't resolve in 30 min**: Escalate to senior engineer
- **Data loss risk**: Immediate escalation to leadership
- **Multiple services affected**: Escalate to infrastructure team
- **Security incident**: Immediate escalation to security team

## Cloud Monitoring Integration

### AWS CloudWatch
```bash
# Push custom metrics
aws cloudwatch put-metric-data \
  --namespace "DevOps/Monitoring" \
  --metric-name "AlertCount" \
  --value 1

# Set up log forwarding
# See: cloud/aws/ for ECS integration
```

### Azure Monitor
```bash
# Query metrics
az monitor metrics list \
  --resource <resource-id> \
  --metric "Percentage CPU"

# See: cloud/azure/ for AKS integration
```

## Maintenance

### Weekly Tasks
- [ ] Review alert accuracy (false positives/negatives)
- [ ] Check alert response times
- [ ] Update runbooks based on recent incidents
- [ ] Test one random runbook procedure

### Monthly Tasks
- [ ] Review alert thresholds and adjust
- [ ] Test notification channels (email, Slack, PagerDuty)
- [ ] Conduct disaster recovery drill
- [ ] Update escalation contacts
- [ ] Review and archive old incidents

### Quarterly Tasks
- [ ] Full alerting system review
- [ ] On-call rotation effectiveness review
- [ ] Update all runbooks
- [ ] Disaster recovery full test
- [ ] Alert rule coverage analysis

## Troubleshooting

### Alerts Not Firing

```bash
# Check Prometheus is loading rules
curl http://localhost:9090/api/v1/rules | jq

# Check if metric exists
curl 'http://localhost:9090/api/v1/query?query=up'

# Check AlertManager is receiving alerts
curl http://localhost:9093/api/v1/alerts
```

### Notifications Not Sent

```bash
# Check AlertManager logs
docker logs alertmanager

# Kubernetes
kubectl logs deployment/alertmanager -n monitoring

# Test SMTP
telnet smtp.gmail.com 587

# Test Slack webhook
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test"}' \
  https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

## Additional Resources

- [Prometheus Alerting Docs](https://prometheus.io/docs/alerting/latest/)
- [AlertManager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Grafana Alerting](https://grafana.com/docs/grafana/latest/alerting/)
- [On-Call Best Practices](https://increment.com/on-call/)
- [SRE Book - Monitoring](https://sre.google/sre-book/monitoring-distributed-systems/)

## Support

- **Documentation Issues**: Create an issue in the repository
- **Alert Configuration Help**: `#devops-help` Slack channel
- **Emergency Contact**: On-call rotation (see PagerDuty)

---

**Remember**: Good alerting is about actionable information, not noise. If an alert doesn't require action, it shouldn't page anyone.
