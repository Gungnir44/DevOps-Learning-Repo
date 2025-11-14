# Python Automation Scripts

Collection of Python scripts for DevOps automation tasks.

## Scripts

### 1. System Health Checker (`system_health_checker.py`)

**Purpose**: Monitor system resources and generate comprehensive health reports

**Features**:
- CPU usage monitoring (total and per-core)
- Memory and swap usage tracking
- Disk usage for all mounted partitions
- Network I/O statistics
- Top CPU-consuming processes
- Overall health status (HEALTHY/WARNING/CRITICAL)
- JSON export for integration with monitoring systems

**Usage**:

```bash
# Install dependencies
pip install -r requirements.txt

# Run the health checker
python system_health_checker.py

# Output: Console report + system_health_report.json
```

**Docker Usage**:

```bash
# Build the container
docker build -t devops-health-checker -f ../../docker/Dockerfile .

# Run the container
docker run --rm devops-health-checker
```

**Health Status Thresholds**:
- `HEALTHY`: Resource usage < 60%
- `WARNING`: Resource usage 60-80%
- `CRITICAL`: Resource usage > 80%

**Output Format**:
- Console: Formatted table with all metrics
- JSON: Structured data for automation and monitoring

**Use Cases**:
- Automated system monitoring
- Pre-deployment health checks
- Incident response data collection
- Resource capacity planning
- Integration with alerting systems

---

## Requirements

- Python 3.7+
- psutil library

Install dependencies:
```bash
pip install -r requirements.txt
```

---

## Future Scripts

### Planned Additions:
- [ ] Log analyzer and parser
- [ ] Automated backup script
- [ ] Docker container manager
- [ ] CI/CD deployment helper
- [ ] SSL certificate checker
- [ ] Database backup automation
- [ ] Cloud resource cost calculator
- [ ] Git repository health checker

---

## Contributing

As this is a learning repository, feel free to suggest improvements or additional automation scripts!
