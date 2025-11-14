# Runbook: High CPU Usage

## Alert Details
- **Alert Name**: HighCPUUsage / CriticalCPUUsage
- **Severity**: Warning (>80%) / Critical (>95%)
- **Category**: Infrastructure

## Symptoms
- CPU usage on a host/container is above threshold
- System may be sluggish or unresponsive
- Application performance degradation
- Increased response times

## Impact
- **User Impact**: Slow application response, potential timeouts
- **Business Impact**: Degraded service quality, potential SLA violations
- **System Impact**: Risk of service crashes, cascading failures

## Investigation Steps

### 1. Verify the Alert
```bash
# SSH to the affected instance
ssh user@<instance-ip>

# Check current CPU usage
top -bn1 | head -20

# Or use htop for interactive view
htop

# Check CPU usage over time
sar -u 5 12  # 12 samples over 1 minute
```

### 2. Identify the Process
```bash
# Find top CPU-consuming processes
ps aux --sort=-%cpu | head -10

# Check process tree
pstree -p

# Get detailed process info
top -c -p <PID>
```

### 3. Check System Load
```bash
# Check load average
uptime

# Check running processes
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -10

# Check for zombie processes
ps aux | grep 'Z'
```

### 4. Review Logs
```bash
# Check system logs
journalctl -u <service-name> --since "10 minutes ago"

# Check application logs
tail -f /var/log/application/app.log

# Check for errors
dmesg | tail -50
```

### 5. Check for Resource Constraints
```bash
# Check disk I/O (high I/O can cause CPU wait)
iostat -x 5 3

# Check memory usage
free -h

# Check swap usage
vmstat 5 5
```

## Resolution Steps

### Immediate Actions (Stop the Bleeding)

#### Option 1: Restart the Service
```bash
# For systemd services
sudo systemctl restart <service-name>

# For Docker containers
docker restart <container-name>

# For Kubernetes pods
kubectl delete pod <pod-name> -n <namespace>
```

#### Option 2: Kill Runaway Process
```bash
# Graceful stop
kill -15 <PID>

# Force kill (if graceful fails)
kill -9 <PID>
```

#### Option 3: Scale Up (Cloud/Kubernetes)
```bash
# Kubernetes: Scale deployment
kubectl scale deployment <deployment-name> --replicas=<new-count> -n monitoring

# AWS ECS: Update service desired count
aws ecs update-service --cluster <cluster> --service <service> --desired-count <count>

# Azure: Scale AKS node pool
az aks nodepool scale --resource-group <rg> --cluster-name <cluster> --name <pool> --node-count <count>
```

### Long-Term Solutions

#### 1. Optimize the Application
- Review and optimize database queries
- Implement caching strategies
- Fix memory leaks
- Optimize algorithms and code paths
- Add connection pooling

#### 2. Horizontal Scaling
```bash
# Add more replicas
kubectl scale deployment <name> --replicas=5 -n monitoring

# Enable auto-scaling
kubectl autoscale deployment <name> --cpu-percent=70 --min=2 --max=10 -n monitoring
```

#### 3. Vertical Scaling
```bash
# Increase resource limits (Kubernetes)
kubectl set resources deployment <name> --limits=cpu=2000m,memory=4Gi -n monitoring

# Update ECS task definition with more CPU
# Modify task definition and redeploy
```

#### 4. Performance Profiling
```bash
# Profile CPU usage (Python example)
python -m cProfile -o output.pstats script.py

# Analyze profile
python -m pstats output.pstats

# For Node.js
node --prof app.js
node --prof-process isolate-*.log > processed.txt
```

## Prevention

### Monitoring Improvements
1. Set up CPU usage trending dashboards in Grafana
2. Configure predictive alerts based on growth trends
3. Monitor application-specific metrics (request latency, queue size)
4. Set up capacity planning reports

### Code Quality
1. Conduct regular performance reviews
2. Implement load testing in CI/CD pipeline
3. Use profiling tools in development
4. Set resource limits in development environments

### Infrastructure
1. Implement auto-scaling policies
2. Use CPU-optimized instance types where appropriate
3. Distribute load across multiple availability zones
4. Implement circuit breakers and rate limiting

## Escalation

### When to Escalate
- CPU usage remains above 90% for more than 15 minutes
- Service is completely unresponsive
- Multiple services affected (potential infrastructure issue)
- Unable to identify root cause within 30 minutes

### Escalation Path
1. **L1**: On-call DevOps engineer (you are here)
2. **L2**: Senior DevOps engineer / Infrastructure lead
3. **L3**: Application team lead + CTO
4. **Emergency**: Page entire engineering team

### Escalation Contacts
- DevOps Lead: [Slack: @devops-lead, Phone: XXX-XXX-XXXX]
- Infrastructure Team: [Slack: #infrastructure-oncall]
- Application Team: [Slack: #app-team-oncall]

## Communication

### Internal Communication
```
Subject: [INCIDENT] High CPU Usage on <instance/service>

Status: Investigating / Resolved
Affected Service: <service-name>
Impact: <description>
Current CPU: XX%
Actions Taken:
- <action 1>
- <action 2>

Next Steps:
- <next action>

ETA for Resolution: <time>
```

### External Communication (if needed)
```
We are currently experiencing elevated response times due to high server load.
Our team is actively working to resolve the issue.
ETA: <time>
```

## Post-Incident

### Immediate Actions
1. Document all actions taken
2. Collect relevant logs and metrics
3. Create timeline of events
4. Verify service is fully recovered

### Follow-Up (Within 24 Hours)
1. Write post-incident review (PIR)
2. Identify root cause
3. Create action items to prevent recurrence
4. Update runbook with lessons learned
5. Schedule team retrospective

### PIR Template
- **What Happened**: Brief description
- **Root Cause**: Technical cause
- **Impact**: User impact and duration
- **Detection**: How was it detected
- **Response**: What actions were taken
- **Timeline**: Chronological events
- **Lessons Learned**: What went well, what didn't
- **Action Items**: Prevent recurrence

## Related Runbooks
- [High Memory Usage](./high-memory-usage.md)
- [Service Down](./service-down.md)
- [Database Performance](./database-performance.md)
- [Container Restart Loop](./container-restart-loop.md)

## Reference Links
- [Prometheus Alerts Dashboard](http://grafana/d/alerts)
- [CloudWatch Metrics](https://console.aws.amazon.com/cloudwatch)
- [Azure Monitor](https://portal.azure.com/#blade/Microsoft_Azure_Monitoring)
- [Incident Management System](https://incident-mgmt.company.com)
