# Docker Quick Start Guide

**Get your monitoring stack running in 5 minutes!**

---

## Prerequisites

1. **Install Docker Desktop**
   - Windows: [Download Docker Desktop](https://www.docker.com/products/docker-desktop)
   - Mac: [Download Docker Desktop](https://www.docker.com/products/docker-desktop)
   - Linux: `curl -fsSL https://get.docker.com | sh`

2. **Start Docker Desktop**
   - Open Docker Desktop application
   - Wait for it to say "Docker is running"

3. **Verify Installation**
   ```bash
   docker --version
   docker-compose --version
   ```

---

## Launch the Stack (Choose Your Method)

### Method 1: Automated Script (Easiest)

**Windows (PowerShell)**:
```powershell
cd docker
.\start-monitoring.ps1
```

**Linux/macOS**:
```bash
cd docker
chmod +x start-monitoring.sh
./start-monitoring.sh
```

### Method 2: Manual Commands

```bash
cd docker

# Start all services
docker-compose -f docker-compose-monitoring.yml up -d

# View logs
docker-compose -f docker-compose-monitoring.yml logs -f
```

---

## Access Your Services

Once running, open your browser:

### Core Services
| Service | URL | Credentials | Description |
|---------|-----|-------------|-------------|
| **Dashboard** | http://localhost:5000 | None | Web UI for health reports |
| **API** | http://localhost:5000/api/latest | None | JSON health data |
| **History** | http://localhost:5000/history | None | Historical reports |
| **Web Demo** | http://localhost:8080 | None | Demo nginx server |

### Observability & Monitoring
| Service | URL | Credentials | Description |
|---------|-----|-------------|-------------|
| **Grafana** | http://localhost:3000 | admin / admin | Dashboards and visualization |
| **Prometheus** | http://localhost:9090 | None | Metrics collection and queries |
| **Kibana** | http://localhost:5601 | None | Log visualization and analysis |
| **Elasticsearch** | http://localhost:9200 | None | Log storage and search |
| **cAdvisor** | http://localhost:8082 | None | Container metrics |

### Database Management
| Service | URL | Credentials | Description |
|---------|-----|-------------|-------------|
| **Adminer** | http://localhost:8081 | varies | Universal database manager |
| **RabbitMQ** | http://localhost:15672 | admin / adminpass | Message queue management |

---

## What's Running?

```bash
# Check container status
docker ps

# You should see 16 containers:

# Core Application Services
# - devops-health-checker     (health monitoring every 5 min)
# - devops-dashboard          (web UI on port 5000)
# - devops-nginx              (web server on port 8080)

# Databases (4)
# - devops-postgres           (PostgreSQL)
# - devops-mysql              (MySQL)
# - devops-mongodb            (MongoDB)
# - devops-redis              (Redis)

# Observability Stack (5)
# - devops-prometheus         (metrics collection on port 9090)
# - devops-grafana            (dashboards on port 3000)
# - devops-elasticsearch      (log storage on port 9200)
# - devops-kibana             (log visualization on port 5601)
# - devops-cadvisor           (container metrics on port 8082)

# Metric Exporters (2)
# - devops-postgres-exporter  (PostgreSQL metrics)
# - devops-redis-exporter     (Redis metrics)

# Management Interfaces (2)
# - devops-adminer            (database manager on port 8081)
# - devops-rabbitmq           (message queue on ports 5672, 15672)
```

---

## Common Operations

### View Logs
```bash
# All services
docker-compose -f docker-compose-monitoring.yml logs -f

# Specific service
docker-compose -f docker-compose-monitoring.yml logs -f health-checker
```

### Stop the Stack
```bash
docker-compose -f docker-compose-monitoring.yml down
```

### Restart a Service
```bash
docker-compose -f docker-compose-monitoring.yml restart dashboard
```

### Run Health Check Manually
```bash
docker-compose -f docker-compose-monitoring.yml exec health-checker \
  python system_health_checker_v2.py
```

### Access Container Shell
```bash
# Health checker
docker exec -it devops-health-checker bash

# Dashboard
docker exec -it devops-dashboard bash
```

### View Resource Usage
```bash
docker stats
```

---

## Troubleshooting

### "Docker is not running"
- Start Docker Desktop
- Wait until system tray icon shows "Docker is running"

### "Port already in use"
```bash
# Check what's using port 5000 (Windows)
netstat -ano | findstr :5000

# Check what's using port 5000 (Linux/macOS)
lsof -i :5000
```

### Dashboard shows "No Data"
```bash
# Manually trigger health check
docker-compose -f docker-compose-monitoring.yml exec health-checker \
  python system_health_checker_v2.py

# Refresh browser
```

### Can't build images
```bash
# Clean Docker cache
docker system prune -a

# Rebuild from scratch
docker-compose -f docker-compose-monitoring.yml build --no-cache
```

---

## Clean Up

### Stop and remove everything:
```bash
# Remove containers but keep volumes (data persists)
docker-compose -f docker-compose-monitoring.yml down

# Remove everything including data
docker-compose -f docker-compose-monitoring.yml down -v
```

### Free up disk space:
```bash
# Remove unused containers, images, networks
docker system prune

# Remove everything (including volumes)
docker system prune -a --volumes
```

---

## Next Steps

1. **Explore the Dashboard**
   - Watch metrics update in real-time
   - Check historical reports
   - Test the API endpoints

2. **Customize Configuration**
   - Edit `scripts/python/config.json`
   - Add email alerts
   - Configure database monitoring

3. **Learn Docker Commands**
   - Read `docker/README.md` for comprehensive guide
   - Experiment with docker-compose commands
   - Try building custom images

4. **Extend the Stack**
   - Add Prometheus for metrics
   - Add Grafana for visualization
   - Add your own services

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Docker Host                             │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         monitoring-network (172.20.0.0/16)          │  │
│  │                                                      │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌──────────┐  │  │
│  │  │health-checker│  │  dashboard   │  │ adminer  │  │  │
│  │  │             │  │              │  │          │  │  │
│  │  │  Reports ───┼──┼──> Reads    │  │   :8081  │  │  │
│  │  └─────────────┘  └──────────────┘  └──────────┘  │  │
│  │         │              :5000                        │  │
│  │         └───> Monitors:                            │  │
│  │               ┌───────────────┐                    │  │
│  │               │ postgres      │                    │  │
│  │               │ mysql         │                    │  │
│  │               │ mongodb       │                    │  │
│  │               │ redis         │                    │  │
│  │               │ rabbitmq      │:15672              │  │
│  │               │ nginx         │:8080               │  │
│  │               └───────────────┘                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Volumes: health-reports, postgres-data, mysql-data,        │
│           mongodb-data, redis-data, rabbitmq-data           │
└─────────────────────────────────────────────────────────────┘
```

---

## Learning Resources

- Full Guide: `docker/README.md`
- Docker Docs: https://docs.docker.com/
- Docker Compose: https://docs.docker.com/compose/
- Interactive Tutorial: https://www.docker.com/play-with-docker/

---

**Happy Containerizing! 🐳**

**Questions?** Check the comprehensive guide in `docker/README.md`
