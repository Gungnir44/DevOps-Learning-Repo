# Runbook: Database Down

## Alert Details
- **Alert Names**: PostgreSQLDown, MySQLDown, MongoDBDown, RedisDown
- **Severity**: Critical
- **Category**: Database

## Symptoms
- Database connection failures
- Applications reporting "connection refused" errors
- Database health checks failing
- No response from database port

## Impact
- **User Impact**: Complete service outage, data cannot be read/written
- **Business Impact**: Critical - service unavailable, potential data loss
- **System Impact**: Dependent services will fail, cascading failures

## Investigation Steps

### 1. Verify the Alert
```bash
# Check if database process is running
ps aux | grep postgres  # PostgreSQL
ps aux | grep mysqld    # MySQL
ps aux | grep mongod    # MongoDB
ps aux | grep redis     # Redis

# Check database port
netstat -tlnp | grep <port>
# PostgreSQL: 5432, MySQL: 3306, MongoDB: 27017, Redis: 6379

# Test connection
telnet localhost <port>
```

### 2. Check Database Status (Docker/Kubernetes)
```bash
# Docker
docker ps -a | grep <database-name>
docker logs <container-name> --tail 100

# Kubernetes
kubectl get pods -n monitoring | grep <database>
kubectl describe pod <pod-name> -n monitoring
kubectl logs <pod-name> -n monitoring --tail=100
```

### 3. Check System Resources
```bash
# Disk space (common cause)
df -h

# Memory
free -h

# Check for OOM killer
dmesg | grep -i "killed process"
journalctl -k | grep "Out of memory"
```

### 4. Review Database Logs
```bash
# PostgreSQL
tail -100 /var/log/postgresql/postgresql-*.log
journalctl -u postgresql --since "10 minutes ago"

# MySQL
tail -100 /var/log/mysql/error.log

# MongoDB
tail -100 /var/log/mongodb/mongod.log

# Redis
tail -100 /var/log/redis/redis-server.log
```

### 5. Check for Corruption
```bash
# PostgreSQL - check for corruption
pg_checksums -D /var/lib/postgresql/data --check

# MySQL - check tables
mysqlcheck -u root -p --all-databases

# MongoDB - repair database (use with caution)
mongod --repair
```

## Resolution Steps

### Immediate Actions

#### Option 1: Restart Database Container/Pod
```bash
# Docker
docker restart <container-name>

# Kubernetes
kubectl delete pod <pod-name> -n monitoring
# StatefulSet will automatically recreate it
```

#### Option 2: Start Stopped Database
```bash
# Systemd
sudo systemctl start postgresql
sudo systemctl start mysql
sudo systemctl start mongod
sudo systemctl start redis

# Check status
sudo systemctl status <service-name>
```

#### Option 3: Fix Disk Space Issue
```bash
# Find large files
du -h /var/lib/postgresql/data | sort -rh | head -20
du -h /var/lib/mysql | sort -rh | head -20

# Clean up old logs
find /var/log -type f -name "*.log" -mtime +30 -delete

# Clean up old WAL files (PostgreSQL)
# Usually handled automatically, but check:
ls -lh /var/lib/postgresql/data/pg_wal/
```

### Recovery from Backup (If Database Won't Start)

#### PostgreSQL
```bash
# Stop database
sudo systemctl stop postgresql

# Restore from backup
pg_restore -d <database> /backup/db_backup.dump

# Or restore from SQL dump
psql -d <database> -f /backup/db_backup.sql

# Start database
sudo systemctl start postgresql
```

#### MySQL
```bash
# Stop database
sudo systemctl stop mysql

# Restore from backup
mysql -u root -p <database> < /backup/db_backup.sql

# Start database
sudo systemctl start mysql
```

#### MongoDB
```bash
# Stop database
sudo systemctl stop mongod

# Restore from backup
mongorestore --db=<database> /backup/mongodb/

# Start database
sudo systemctl start mongod
```

### Kubernetes Persistent Volume Recovery
```bash
# Check PVC status
kubectl get pvc -n monitoring

# If PVC is lost, restore from snapshot
kubectl apply -f pvc-from-snapshot.yaml

# Recreate StatefulSet
kubectl delete statefulset <name> -n monitoring
kubectl apply -f statefulset.yaml
```

## Verification

### 1. Check Database is Running
```bash
# Process check
ps aux | grep <database>

# Port check
netstat -tlnp | grep <port>

# Docker/Kubernetes
docker ps | grep <database>
kubectl get pods -n monitoring
```

### 2. Test Connectivity
```bash
# PostgreSQL
psql -h localhost -U <user> -d <database> -c "SELECT 1;"

# MySQL
mysql -h localhost -u <user> -p<password> -e "SELECT 1;"

# MongoDB
mongo --eval "db.adminCommand('ping')"

# Redis
redis-cli ping
```

### 3. Verify Data Integrity
```bash
# PostgreSQL
psql -U <user> -d <database> -c "SELECT COUNT(*) FROM <important_table>;"

# MySQL
mysql -u <user> -p -e "USE <database>; SELECT COUNT(*) FROM <important_table>;"

# MongoDB
mongo <database> --eval "db.<collection>.count()"
```

### 4. Check Replication (If Applicable)
```bash
# PostgreSQL
psql -U <user> -c "SELECT * FROM pg_stat_replication;"

# MySQL
mysql -u root -p -e "SHOW SLAVE STATUS\G"

# MongoDB
mongo --eval "rs.status()"
```

## Prevention

### 1. Monitoring Enhancements
- Add disk space monitoring alerts (< 20% free)
- Monitor connection pool usage
- Track slow query logs
- Set up replication lag alerts
- Monitor database transaction rates

### 2. High Availability Setup
```bash
# PostgreSQL - streaming replication
# MySQL - master-slave replication
# MongoDB - replica sets
# Redis - Redis Sentinel or Redis Cluster
```

### 3. Automated Backups
```bash
# Cronjob for PostgreSQL backup
0 2 * * * pg_dump -U postgres <database> | gzip > /backup/db_$(date +\%Y\%m\%d).sql.gz

# Cronjob for MySQL backup
0 2 * * * mysqldump -u root -p<password> --all-databases | gzip > /backup/mysql_$(date +\%Y\%m\%d).sql.gz

# Kubernetes - use Velero for backup
velero backup create <backup-name> --include-namespaces monitoring
```

### 4. Resource Management
```yaml
# Kubernetes - set appropriate resource limits
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 2000m
    memory: 4Gi
```

### 5. Health Checks
```yaml
# Kubernetes liveness probe
livenessProbe:
  exec:
    command:
    - pg_isready
    - -U
    - postgres
  initialDelaySeconds: 30
  periodSeconds: 10
```

## Escalation

### When to Escalate
- Database won't start after multiple restart attempts
- Data corruption detected
- Backup restoration failing
- Issue persists for more than 15 minutes
- Data loss suspected

### Escalation Path
1. **L1**: On-call DevOps engineer (you are here)
2. **L2**: Database administrator (DBA)
3. **L3**: Infrastructure architect + Application team
4. **Emergency**: CTO + Database vendor support

### Escalation Contacts
- DBA On-Call: [Slack: @dba-oncall, Phone: XXX-XXX-XXXX]
- Database Team: [Slack: #database-oncall]
- Infrastructure Lead: [Slack: @infra-lead]
- Vendor Support: [Support portal, Phone: XXX-XXX-XXXX]

## Communication

### Internal Status Update
```
Subject: [CRITICAL] Database Outage - <database-name>

Status: Investigating / Restoring / Resolved
Affected Database: <database-name>
Impact: Complete service outage
Services Affected: <list>
Started At: <time>

Actions Taken:
- <action 1>
- <action 2>

Root Cause: <if known>
ETA for Resolution: <time>

Next Update: <time>
```

### External Communication
```
We are currently experiencing a service outage due to database issues.
Our team is actively working to restore service.
We apologize for the inconvenience.

Updates will be posted every 15 minutes at: status.company.com
```

## Post-Incident

### Immediate Actions (Once Resolved)
1. ✅ Verify all dependent services are healthy
2. ✅ Check data integrity across tables
3. ✅ Review and save all logs
4. ✅ Document exact cause and resolution
5. ✅ Update incident timeline

### Follow-Up (Within 24 Hours)
1. Complete post-incident review
2. Analyze root cause
3. Review backup and recovery procedures
4. Update monitoring thresholds
5. Test restore procedures
6. Schedule team post-mortem

### Action Items Checklist
- [ ] Implement additional monitoring
- [ ] Set up automated failover
- [ ] Test backup restoration monthly
- [ ] Review and update runbooks
- [ ] Conduct disaster recovery drill
- [ ] Increase resource limits if needed
- [ ] Set up database replication if not present

## Related Runbooks
- [High Database Connections](./database-high-connections.md)
- [Database Slow Queries](./database-slow-queries.md)
- [Disk Space Full](./disk-space-full.md)
- [Service Down](./service-down.md)

## Database-Specific Commands

### PostgreSQL Useful Commands
```sql
-- Check database size
SELECT pg_database_size('<database>');

-- Check active connections
SELECT count(*) FROM pg_stat_activity;

-- Terminate connections
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '<database>';

-- Check replication status
SELECT * FROM pg_stat_replication;
```

### MySQL Useful Commands
```sql
-- Check database size
SELECT table_schema, SUM(data_length + index_length) / 1024 / 1024 AS size_mb
FROM information_schema.tables GROUP BY table_schema;

-- Check connections
SHOW PROCESSLIST;

-- Kill connection
KILL <process_id>;

-- Check replication
SHOW SLAVE STATUS\G
```

### MongoDB Useful Commands
```javascript
// Check database size
db.stats()

// Check current operations
db.currentOp()

// Kill operation
db.killOp(<opid>)

// Check replica set status
rs.status()
```

### Redis Useful Commands
```bash
# Check info
redis-cli INFO

# Check memory
redis-cli INFO memory

# Check connected clients
redis-cli CLIENT LIST

# Save snapshot
redis-cli SAVE
```

## Reference Links
- [Database Monitoring Dashboard](http://grafana/d/database)
- [Backup Storage](https://backup-portal.company.com)
- [Database Documentation](https://docs.company.com/database)
