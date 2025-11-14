# Observability Stack Guide

Your monitoring stack now includes professional-grade observability tools used by companies like Netflix, Uber, and Spotify!

---

## Stack Overview

**Metrics**: Prometheus + Grafana
**Logs**: Elasticsearch + Kibana
**Container Monitoring**: cAdvisor
**Database Metrics**: Postgres & Redis Exporters

---

## Prometheus - Metrics Collection

**Access**: http://localhost:9090

### What is Prometheus?
Prometheus is a time-series database that collects and stores metrics from your services.

### Getting Started

1. **View Targets** - See what's being monitored:
   ```
   http://localhost:9090/targets
   ```

   You should see:
   - ✓ prometheus (itself)
   - ✓ cadvisor (container metrics)
   - ✓ postgres (PostgreSQL metrics)
   - ✓ redis (Redis metrics)
   - ✓ rabbitmq (message queue metrics)

2. **Run Queries** - Try these in the Expression Browser:

   **Container CPU Usage:**
   ```promql
   rate(container_cpu_usage_seconds_total[5m])
   ```

   **Container Memory:**
   ```promql
   container_memory_usage_bytes / 1024 / 1024
   ```

   **PostgreSQL Connections:**
   ```promql
   pg_stat_database_numbackends
   ```

   **Redis Memory:**
   ```promql
   redis_memory_used_bytes / 1024 / 1024
   ```

   **RabbitMQ Queue Depth:**
   ```promql
   rabbitmq_queue_messages
   ```

3. **Graph View**:
   - Click "Graph" tab
   - Add queries
   - See live metrics in real-time

---

## Grafana - Visualization Platform

**Access**: http://localhost:3000
**Username**: admin
**Password**: admin

### What is Grafana?
Grafana turns Prometheus metrics into beautiful, actionable dashboards.

### Getting Started

1. **First Login**:
   - Go to http://localhost:3000
   - Login with admin/admin
   - (Optional) Change password when prompted

2. **Verify Datasource**:
   - Go to Configuration → Data Sources
   - You should see "Prometheus" already configured
   - Status should be green

3. **Create Your First Dashboard**:

   **Step 1**: Click "+" → Dashboard → Add new panel

   **Step 2**: Enter a query (try this):
   ```promql
   rate(container_cpu_usage_seconds_total{name="devops-dashboard"}[5m])
   ```

   **Step 3**: Customize:
   - Panel title: "Dashboard Container CPU Usage"
   - Visualization type: Time series
   - Unit: Percent (0.0-1.0)

   **Step 4**: Click "Apply" and "Save dashboard"

4. **Import Community Dashboards**:

   Go to Dashboards → Import and use these IDs:

   - **179**: Docker Host & Container Overview (cAdvisor)
   - **9628**: PostgreSQL Database
   - **11835**: Redis
   - **10991**: RabbitMQ

   Just enter the ID and click "Load"!

### Useful Panel Queries

**All Container Memory Usage:**
```promql
sum(container_memory_usage_bytes) by (name) / 1024 / 1024
```

**Database Query Rate:**
```promql
rate(pg_stat_database_xact_commit[5m])
```

**Redis Hit Rate:**
```promql
rate(redis_keyspace_hits_total[5m]) / (rate(redis_keyspace_hits_total[5m]) + rate(redis_keyspace_misses_total[5m]))
```

**Disk Usage by Container:**
```promql
sum(container_fs_usage_bytes) by (name) / 1024 / 1024 / 1024
```

---

## Elasticsearch & Kibana - Log Management

**Elasticsearch**: http://localhost:9200
**Kibana**: http://localhost:5601

### What is ELK Stack?
- **Elasticsearch**: Stores and searches logs
- **Kibana**: Visualizes and analyzes logs

### Getting Started with Kibana

1. **First Access**:
   - Go to http://localhost:5601
   - Wait for it to initialize (first time takes ~30 seconds)
   - Click "Explore on my own"

2. **View Logs** (Future Setup):
   To send logs to Elasticsearch, you'll need to configure log shippers:
   - **Filebeat**: For file logs
   - **Logstash**: For complex log processing
   - **Fluentd**: Alternative log collector

3. **Discover Tab**:
   - This is where you'll search logs
   - Use KQL (Kibana Query Language)
   - Filter by time, service, level, etc.

4. **Example Queries** (when logs are configured):
   ```
   level: ERROR
   service: health-checker AND status: CRITICAL
   container.name: devops-dashboard
   ```

### Check Elasticsearch Status

```bash
curl http://localhost:9200/_cluster/health
```

Should show: `"status":"green"`

---

## cAdvisor - Container Monitoring

**Access**: http://localhost:8082

### What is cAdvisor?
Google's Container Advisor provides real-time resource usage and performance metrics for running containers.

### Using cAdvisor

1. **Overview Page**:
   - Shows all containers
   - CPU, Memory, Network, Disk usage
   - Realtime graphs

2. **Per-Container Details**:
   - Click any container name
   - See detailed metrics:
     - CPU usage (cores, throttling)
     - Memory (usage, limit, working set)
     - Network (RX/TX bytes, errors)
     - Filesystem (usage, I/O)

3. **Metrics Endpoint**:
   ```
   http://localhost:8082/metrics
   ```
   Prometheus scrapes this every 15 seconds!

---

## Monitoring Your Databases

### PostgreSQL Metrics

**View in Prometheus**:
```promql
# Active connections
pg_stat_database_numbackends{datname="demodb"}

# Transaction rate
rate(pg_stat_database_xact_commit{datname="demodb"}[5m])

# Database size
pg_database_size_bytes{datname="demodb"} / 1024 / 1024
```

### Redis Metrics

**View in Prometheus**:
```promql
# Connected clients
redis_connected_clients

# Memory usage
redis_memory_used_bytes / 1024 / 1024

# Commands per second
rate(redis_commands_processed_total[1m])

# Hit rate
rate(redis_keyspace_hits_total[5m]) / rate(redis_keyspace_hits_total[5m] + redis_keyspace_misses_total[5m])
```

### MongoDB & MySQL

Currently monitored by the health-checker. To add exporters:
- **MongoDB**: prometheuscommunity/mongodb-exporter
- **MySQL**: prometheuscommunity/mysqld-exporter

---

## Alert Rules (Advanced)

Create alerts in Prometheus or Grafana:

### Example: High CPU Alert

**In Prometheus** (`prometheus/alerts.yml`):
```yaml
groups:
  - name: container_alerts
    rules:
      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total[5m]) > 0.8
        for: 5m
        annotations:
          summary: "High CPU usage on {{ $labels.name }}"
```

### Example: Memory Alert

```yaml
  - alert: HighMemoryUsage
    expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.9
    for: 5m
    annotations:
      summary: "High memory usage on {{ $labels.name }}"
```

---

## Resource Usage

Your entire observability stack uses approximately:

```
Prometheus:      ~200MB RAM
Grafana:         ~150MB RAM
Elasticsearch:   ~600MB RAM
Kibana:          ~500MB RAM
cAdvisor:        ~30MB RAM
Exporters:       ~20MB RAM each
---
Total:           ~1.5GB RAM
```

Still very efficient for 6 monitoring services!

---

## Common Tasks

### 1. Find Slow Queries (PostgreSQL)
```promql
pg_stat_statements_max_exec_time_ms > 1000
```

### 2. Monitor Redis Keys
```promql
redis_db_keys{db="db0"}
```

### 3. Container Restart Count
```promql
container_last_seen - container_start_time_seconds < 300
```

### 4. Network Traffic by Container
```promql
rate(container_network_receive_bytes_total[5m]) / 1024 / 1024
```

### 5. Disk I/O
```promql
rate(container_fs_writes_bytes_total[5m]) / 1024 / 1024
```

---

## Troubleshooting

### Prometheus Not Scraping Targets

1. Check target status: http://localhost:9090/targets
2. Look for error messages
3. Verify containers are running:
   ```bash
   docker ps | grep exporter
   ```

### Grafana Can't Connect to Prometheus

1. Check datasource health in Grafana
2. Verify Prometheus is running:
   ```bash
   docker logs devops-prometheus
   ```
3. Check network connectivity:
   ```bash
   docker exec devops-grafana ping prometheus
   ```

### Kibana Won't Load

1. Check Elasticsearch status:
   ```bash
   curl http://localhost:9200/_cluster/health
   ```
2. Wait 1-2 minutes for initialization
3. Check logs:
   ```bash
   docker logs devops-kibana
   ```

### High Resource Usage

If your system is slow:

1. **Reduce Elasticsearch memory**:
   Edit docker-compose-monitoring.yml:
   ```yaml
   ES_JAVA_OPTS: "-Xms256m -Xmx256m"
   ```

2. **Increase scrape interval**:
   Edit `prometheus/prometheus.yml`:
   ```yaml
   scrape_interval: 30s  # was 15s
   ```

3. **Stop non-essential containers**:
   ```bash
   docker stop devops-kibana devops-elasticsearch
   ```

---

## Next Steps

### 1. Create Custom Dashboards
- Build dashboards for your specific needs
- Monitor your application metrics
- Set up alerts for critical issues

### 2. Add More Exporters
- MySQL Exporter
- MongoDB Exporter
- Nginx Exporter
- Node Exporter (Linux only)

### 3. Configure Log Shipping
- Install Filebeat to send logs to Elasticsearch
- Configure log parsing in Logstash
- Create log dashboards in Kibana

### 4. Set Up Alerting
- Configure Alertmanager for Prometheus
- Add Grafana alerts
- Integrate with Slack, PagerDuty, or email

### 5. Production Readiness
- Enable authentication on Elasticsearch/Kibana
- Set up SSL/TLS
- Configure retention policies
- Add backup strategies

---

## Learning Resources

### Prometheus
- Official Docs: https://prometheus.io/docs/
- Query Language: https://prometheus.io/docs/prometheus/latest/querying/basics/
- Best Practices: https://prometheus.io/docs/practices/naming/

### Grafana
- Official Docs: https://grafana.com/docs/
- Dashboard Gallery: https://grafana.com/grafana/dashboards/
- Tutorial: https://grafana.com/tutorials/

### ELK Stack
- Elasticsearch Guide: https://www.elastic.co/guide/en/elasticsearch/reference/current/
- Kibana Guide: https://www.elastic.co/guide/en/kibana/current/
- KQL Syntax: https://www.elastic.co/guide/en/kibana/current/kuery-query.html

---

## Quick Reference Commands

```bash
# Check all metrics targets
curl http://localhost:9090/api/v1/targets | python -m json.tool

# Query Prometheus
curl 'http://localhost:9090/api/v1/query?query=up'

# Check Elasticsearch health
curl http://localhost:9200/_cluster/health

# View Grafana datasources
curl -u admin:admin http://localhost:3000/api/datasources

# cAdvisor metrics
curl http://localhost:8082/metrics

# Container stats
docker stats --no-stream
```

---

**Congratulations!** You now have a production-grade observability stack running locally. This is the same technology stack used by major tech companies for monitoring their services at scale.
