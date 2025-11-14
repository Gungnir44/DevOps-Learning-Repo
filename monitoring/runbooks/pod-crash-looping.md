# Runbook: Pod Crash Looping

## Alert Details
- **Alert Name**: PodCrashLooping, ContainerRestarting
- **Severity**: Critical / Warning
- **Category**: Infrastructure

## Symptoms
- Kubernetes pod repeatedly crashing and restarting
- Pod status shows "CrashLoopBackOff" or "Error"
- Application unavailable or intermittently available
- High restart count in pod description

## Impact
- **User Impact**: Service unavailable or degraded
- **Business Impact**: Potential data loss, SLA violations
- **System Impact**: Resource waste, cluster instability

## Investigation Steps

### 1. Check Pod Status
```bash
# Get pod status
kubectl get pods -n monitoring

# Watch pod in real-time
kubectl get pods -n monitoring -w

# Describe the pod (shows events and restart count)
kubectl describe pod <pod-name> -n monitoring
```

### 2. Check Pod Logs
```bash
# Current container logs
kubectl logs <pod-name> -n monitoring

# Previous container logs (after crash)
kubectl logs <pod-name> -n monitoring --previous

# Follow logs in real-time
kubectl logs <pod-name> -n monitoring -f

# Logs from specific container (if multi-container pod)
kubectl logs <pod-name> -c <container-name> -n monitoring
```

### 3. Check Events
```bash
# Recent events in namespace
kubectl get events -n monitoring --sort-by='.lastTimestamp'

# Events for specific pod
kubectl describe pod <pod-name> -n monitoring | grep -A 10 Events
```

### 4. Check Resource Usage
```bash
# Check if pod is being OOMKilled
kubectl describe pod <pod-name> -n monitoring | grep -i "oom"

# Check current resource usage
kubectl top pod <pod-name> -n monitoring

# Check resource limits and requests
kubectl get pod <pod-name> -n monitoring -o yaml | grep -A 10 resources
```

### 5. Check Configuration
```bash
# View full pod spec
kubectl get pod <pod-name> -n monitoring -o yaml

# Check ConfigMaps
kubectl get configmap -n monitoring
kubectl describe configmap <configmap-name> -n monitoring

# Check Secrets
kubectl get secrets -n monitoring
kubectl describe secret <secret-name> -n monitoring
```

## Common Causes and Solutions

### 1. Application Crashing

#### Investigation
```bash
# Check exit code
kubectl describe pod <pod-name> -n monitoring | grep "Exit Code"

# Common exit codes:
# 0 - Success (shouldn't cause restart)
# 1 - Application error
# 137 - OOMKilled (Out of Memory)
# 139 - Segmentation fault
# 143 - Graceful termination (SIGTERM)
```

#### Solution
```bash
# If application error (exit code 1):
# 1. Review application logs for stack traces
# 2. Check environment variables
kubectl exec <pod-name> -n monitoring -- env

# 3. Check file permissions
kubectl exec <pod-name> -n monitoring -- ls -la /path/to/files

# 4. Test the container locally
docker run -it <image> /bin/sh
```

### 2. Out of Memory (OOMKilled)

#### Investigation
```bash
# Check if pod was OOMKilled
kubectl describe pod <pod-name> -n monitoring | grep -i "oomkilled"

# Check current memory limits
kubectl get pod <pod-name> -n monitoring -o jsonpath='{.spec.containers[*].resources.limits.memory}'
```

#### Solution
```bash
# Increase memory limits
kubectl set resources deployment <deployment-name> \
  --limits=memory=2Gi \
  --requests=memory=1Gi \
  -n monitoring

# Or edit deployment directly
kubectl edit deployment <deployment-name> -n monitoring
# Update:
# resources:
#   limits:
#     memory: "2Gi"
#   requests:
#     memory: "1Gi"
```

### 3. Missing Dependencies

#### Investigation
```bash
# Check if pod can't connect to required services
kubectl logs <pod-name> -n monitoring | grep -i "connection refused\|unable to connect"

# Check if ConfigMap/Secret exists
kubectl get configmap -n monitoring
kubectl get secret -n monitoring

# Check DNS resolution
kubectl exec <pod-name> -n monitoring -- nslookup <service-name>
```

#### Solution
```bash
# Create missing ConfigMap
kubectl create configmap <name> --from-file=<file> -n monitoring

# Create missing Secret
kubectl create secret generic <name> --from-literal=key=value -n monitoring

# Verify service exists
kubectl get svc -n monitoring

# Check service endpoints
kubectl get endpoints -n monitoring
```

### 4. Failing Health Checks

#### Investigation
```bash
# Check liveness probe configuration
kubectl get pod <pod-name> -n monitoring -o yaml | grep -A 10 livenessProbe

# Test probe manually
kubectl exec <pod-name> -n monitoring -- wget -O- http://localhost:8080/health
kubectl exec <pod-name> -n monitoring -- curl http://localhost:8080/health
```

#### Solution
```yaml
# Adjust probe timing in deployment
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 60  # Increase if app needs more startup time
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3      # Increase for more tolerance
```

```bash
# Apply changes
kubectl apply -f deployment.yaml
```

### 5. Image Pull Errors

#### Investigation
```bash
# Check for ImagePullBackOff
kubectl describe pod <pod-name> -n monitoring | grep -i "image"

# Common errors:
# - Image not found
# - Authentication required
# - Invalid image tag
```

#### Solution
```bash
# Verify image exists
docker pull <image-name:tag>

# Create image pull secret (if authentication needed)
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  -n monitoring

# Add imagePullSecrets to deployment
kubectl patch deployment <deployment-name> -n monitoring -p \
  '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"regcred"}]}}}}'
```

### 6. Insufficient Resources

#### Investigation
```bash
# Check if pod is pending due to insufficient resources
kubectl describe pod <pod-name> -n monitoring | grep -i "insufficient"

# Check node resources
kubectl describe nodes
```

#### Solution
```bash
# Option 1: Reduce resource requests
kubectl set resources deployment <deployment-name> \
  --requests=cpu=100m,memory=256Mi \
  -n monitoring

# Option 2: Scale up cluster
# AWS EKS
eksctl scale nodegroup --cluster=<cluster> --name=<nodegroup> --nodes=<count>

# Azure AKS
az aks nodepool scale --resource-group <rg> --cluster-name <cluster> \
  --name <pool> --node-count <count>

# GKE
gcloud container clusters resize <cluster> --num-nodes=<count>
```

## Resolution Steps

### Quick Fix: Rollback to Previous Version
```bash
# Check rollout history
kubectl rollout history deployment/<deployment-name> -n monitoring

# Rollback to previous version
kubectl rollout undo deployment/<deployment-name> -n monitoring

# Rollback to specific revision
kubectl rollout undo deployment/<deployment-name> --to-revision=<number> -n monitoring

# Check rollout status
kubectl rollout status deployment/<deployment-name> -n monitoring
```

### Debug with Temporary Pod
```bash
# Start debug pod with same image
kubectl run debug-pod --image=<image> -it --rm -n monitoring -- /bin/sh

# Or debug running pod
kubectl debug <pod-name> -it --image=busybox -n monitoring

# Copy files from pod for inspection
kubectl cp <pod-name>:/var/log/app.log ./app.log -n monitoring
```

### Force Delete and Recreate
```bash
# Delete the pod (will be recreated by controller)
kubectl delete pod <pod-name> -n monitoring

# If pod is stuck
kubectl delete pod <pod-name> --force --grace-period=0 -n monitoring

# Delete and recreate deployment
kubectl delete deployment <deployment-name> -n monitoring
kubectl apply -f deployment.yaml
```

## Verification

### 1. Check Pod is Running
```bash
# Verify pod status
kubectl get pods -n monitoring | grep <pod-name>

# Should show: Running with 0-1 restarts

# Check readiness
kubectl get pods -n monitoring -o wide
```

### 2. Verify Application Health
```bash
# Check application logs
kubectl logs <pod-name> -n monitoring --tail=50

# Test application endpoint
kubectl port-forward <pod-name> 8080:8080 -n monitoring
curl http://localhost:8080/health
```

### 3. Monitor for Stability
```bash
# Watch pod for 5 minutes
kubectl get pods -n monitoring -w

# Check restart count stays at 0
kubectl get pod <pod-name> -n monitoring -o jsonpath='{.status.containerStatuses[0].restartCount}'
```

## Prevention

### 1. Proper Resource Limits
```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 1Gi
```

### 2. Health Check Best Practices
```yaml
# Separate liveness and readiness probes
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
```

### 3. Pod Disruption Budgets
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: myapp
```

### 4. Monitoring and Alerts
```yaml
# Prometheus alert rule
- alert: PodCrashLooping
  expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Pod {{ $labels.pod }} is crash looping"
```

### 5. Testing Before Deployment
```bash
# Test image locally
docker run -it <image>

# Validate Kubernetes manifests
kubectl apply --dry-run=client -f deployment.yaml

# Use staging environment first
kubectl apply -f deployment.yaml -n staging
```

## Escalation

### When to Escalate
- Pod continues crashing after troubleshooting attempts
- Data corruption suspected
- Cluster-wide pod failures
- Unable to identify root cause within 20 minutes
- Security-related crashes

### Escalation Path
1. **L1**: On-call DevOps engineer (you are here)
2. **L2**: Senior Kubernetes engineer
3. **L3**: Application development team + Infrastructure architect
4. **Emergency**: CTO + Cloud provider support

## Communication Template

```
Subject: [INCIDENT] Pod Crash Loop - <pod-name>

Status: Investigating / Mitigated / Resolved
Pod: <pod-name>
Namespace: monitoring
Restart Count: <count>
Last Exit Code: <code>

Impact: <service> is unavailable/degraded

Root Cause: <if known>
- OOMKilled / Application error / Config issue / etc.

Actions Taken:
- Reviewed logs
- Adjusted resources
- <other actions>

Current Status: <description>
ETA: <time>

Next Update: <time>
```

## Post-Incident

### Checklist
- [ ] Root cause identified and documented
- [ ] Resource limits adjusted appropriately
- [ ] Health check configurations reviewed
- [ ] Logs and metrics saved for analysis
- [ ] Similar deployments checked for same issue
- [ ] Runbook updated with lessons learned
- [ ] Post-mortem scheduled
- [ ] Monitoring alerts tuned

## Related Runbooks
- [High Memory Usage](./high-memory-usage.md)
- [Service Down](./service-down.md)
- [Image Pull Failures](./image-pull-failures.md)
- [Node Not Ready](./node-not-ready.md)

## Useful Kubectl Commands

```bash
# Get pod YAML
kubectl get pod <pod-name> -n monitoring -o yaml > pod.yaml

# Get events sorted by time
kubectl get events --sort-by='.lastTimestamp' -n monitoring

# Exec into running container
kubectl exec -it <pod-name> -n monitoring -- /bin/bash

# Port forward for testing
kubectl port-forward <pod-name> 8080:8080 -n monitoring

# Copy files from pod
kubectl cp <pod-name>:/path/to/file ./file -n monitoring

# Check resource usage across all pods
kubectl top pods -n monitoring

# Get pod IP and node
kubectl get pod <pod-name> -n monitoring -o wide
```

## Reference Links
- [Kubernetes Troubleshooting Guide](https://kubernetes.io/docs/tasks/debug/)
- [Pod Lifecycle Documentation](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [Monitoring Dashboard](http://grafana/d/kubernetes)
