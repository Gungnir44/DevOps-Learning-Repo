#!/usr/bin/env python3
"""
System Health Checker V2 - Enhanced DevOps Monitoring Script
Author: Joshua
Description: Advanced system monitoring with email alerts and database checks
"""

import psutil
import platform
import datetime
import json
import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from collections import OrderedDict
import argparse
import sys


class DatabaseChecker:
    """Check connectivity to various databases"""

    def __init__(self):
        self.results = []

    def check_postgresql(self, config):
        """Check PostgreSQL connection"""
        try:
            import psycopg2

            conn = psycopg2.connect(
                host=config["host"],
                port=config["port"],
                database=config["database"],
                user=config["user"],
                password=config["password"],
                connect_timeout=config.get("timeout", 5),
            )
            conn.close()
            return {"status": "CONNECTED", "message": "Connection successful"}
        except ImportError:
            return {"status": "SKIPPED", "message": "psycopg2 not installed"}
        except Exception as e:
            return {"status": "FAILED", "message": str(e)}

    def check_mysql(self, config):
        """Check MySQL connection"""
        try:
            import pymysql

            conn = pymysql.connect(
                host=config["host"],
                port=config["port"],
                database=config["database"],
                user=config["user"],
                password=config["password"],
                connect_timeout=config.get("timeout", 5),
            )
            conn.close()
            return {"status": "CONNECTED", "message": "Connection successful"}
        except ImportError:
            return {"status": "SKIPPED", "message": "pymysql not installed"}
        except Exception as e:
            return {"status": "FAILED", "message": str(e)}

    def check_mongodb(self, config):
        """Check MongoDB connection"""
        try:
            from pymongo import MongoClient

            client = MongoClient(
                host=config["host"],
                port=config["port"],
                serverSelectionTimeoutMS=config.get("timeout", 5) * 1000,
            )
            client.server_info()
            client.close()
            return {"status": "CONNECTED", "message": "Connection successful"}
        except ImportError:
            return {"status": "SKIPPED", "message": "pymongo not installed"}
        except Exception as e:
            return {"status": "FAILED", "message": str(e)}

    def check_redis(self, config):
        """Check Redis connection"""
        try:
            import redis

            r = redis.Redis(
                host=config["host"],
                port=config["port"],
                socket_timeout=config.get("timeout", 5),
            )
            r.ping()
            return {"status": "CONNECTED", "message": "Connection successful"}
        except ImportError:
            return {"status": "SKIPPED", "message": "redis not installed"}
        except Exception as e:
            return {"status": "FAILED", "message": str(e)}

    def check_all(self, db_configs):
        """Check all configured databases"""
        results = []

        for db_config in db_configs:
            db_type = db_config["type"].lower()
            result = {
                "name": db_config["name"],
                "type": db_config["type"],
                "host": db_config["host"],
                "port": db_config["port"],
            }

            if db_type == "postgresql":
                check_result = self.check_postgresql(db_config)
            elif db_type == "mysql":
                check_result = self.check_mysql(db_config)
            elif db_type == "mongodb":
                check_result = self.check_mongodb(db_config)
            elif db_type == "redis":
                check_result = self.check_redis(db_config)
            else:
                check_result = {
                    "status": "UNKNOWN",
                    "message": f"Unknown database type: {db_type}",
                }

            result.update(check_result)
            results.append(result)

        return results


class EmailAlerter:
    """Send email alerts for system health issues"""

    def __init__(self, config):
        self.config = config
        self.enabled = config.get("enabled", False)

    def send_alert(self, health_data):
        """Send email alert based on health data"""
        if not self.enabled:
            return {"sent": False, "message": "Email alerts disabled"}

        overall_health = health_data["overall_health"]
        alert_levels = self.config.get("alert_on", ["WARNING", "CRITICAL"])

        if overall_health not in alert_levels:
            return {
                "sent": False,
                "message": f"Health status {overall_health} not in alert levels",
            }

        try:
            subject = f"[{overall_health}] System Health Alert - {health_data['system']['hostname']}"
            body = self._format_email_body(health_data)

            msg = MIMEMultipart()
            msg["From"] = self.config["sender_email"]
            msg["To"] = ", ".join(self.config["recipient_emails"])
            msg["Subject"] = subject

            msg.attach(MIMEText(body, "html"))

            with smtplib.SMTP(
                self.config["smtp_server"], self.config["smtp_port"]
            ) as server:
                server.starttls()
                server.login(
                    self.config["sender_email"], self.config["sender_password"]
                )
                server.send_message(msg)

            return {"sent": True, "message": "Alert sent successfully"}

        except Exception as e:
            return {"sent": False, "message": f"Failed to send alert: {str(e)}"}

    def _format_email_body(self, health_data):
        """Format health data as HTML email"""
        status_colors = {
            "HEALTHY": "#28a745",
            "WARNING": "#ffc107",
            "CRITICAL": "#dc3545",
        }

        overall_color = status_colors.get(health_data["overall_health"], "#6c757d")

        html = f"""
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; }}
                .header {{ background-color: {overall_color}; color: white; padding: 20px; text-align: center; }}
                .content {{ padding: 20px; }}
                .metric {{ margin: 15px 0; padding: 10px; background-color: #f8f9fa; border-radius: 5px; }}
                .status {{ font-weight: bold; padding: 5px 10px; border-radius: 3px; }}
                .healthy {{ background-color: #d4edda; color: #155724; }}
                .warning {{ background-color: #fff3cd; color: #856404; }}
                .critical {{ background-color: #f8d7da; color: #721c24; }}
                table {{ width: 100%; border-collapse: collapse; margin: 10px 0; }}
                th, td {{ padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }}
                th {{ background-color: #e9ecef; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h1>System Health Alert</h1>
                <h2>{health_data['system']['hostname']}</h2>
                <h3>Status: {health_data['overall_health']}</h3>
            </div>
            <div class="content">
                <p><strong>Timestamp:</strong> {health_data['timestamp']}</p>

                <div class="metric">
                    <h3>CPU - <span class="status {health_data['cpu']['status'].lower()}">{health_data['cpu']['status']}</span></h3>
                    <p>Usage: {health_data['cpu']['cpu_percent_total']}%</p>
                    <p>Cores: {health_data['cpu']['cpu_count_logical']} logical ({health_data['cpu']['cpu_count']} physical)</p>
                </div>

                <div class="metric">
                    <h3>Memory - <span class="status {health_data['memory']['status'].lower()}">{health_data['memory']['status']}</span></h3>
                    <p>Used: {health_data['memory']['used_gb']} GB / {health_data['memory']['total_gb']} GB ({health_data['memory']['percent_used']}%)</p>
                    <p>Available: {health_data['memory']['available_gb']} GB</p>
                </div>

                <div class="metric">
                    <h3>Disk Usage</h3>
                    <table>
                        <tr><th>Mount</th><th>Used</th><th>Total</th><th>Status</th></tr>
        """

        for disk in health_data["disk"]:
            html += f"""
                        <tr>
                            <td>{disk['mountpoint']}</td>
                            <td>{disk['used_gb']} GB ({disk['percent_used']}%)</td>
                            <td>{disk['total_gb']} GB</td>
                            <td><span class="status {disk['status'].lower()}">{disk['status']}</span></td>
                        </tr>
            """

        html += """
                    </table>
                </div>
        """

        if "databases" in health_data and health_data["databases"]:
            html += """
                <div class="metric">
                    <h3>Database Connectivity</h3>
                    <table>
                        <tr><th>Name</th><th>Type</th><th>Status</th><th>Message</th></tr>
            """

            for db in health_data["databases"]:
                html += f"""
                        <tr>
                            <td>{db['name']}</td>
                            <td>{db['type']}</td>
                            <td><span class="status {db['status'].lower()}">{db['status']}</span></td>
                            <td>{db['message']}</td>
                        </tr>
                """

            html += """
                    </table>
                </div>
            """

        html += """
                <div class="metric">
                    <h3>Top CPU Processes</h3>
                    <table>
                        <tr><th>PID</th><th>Name</th><th>CPU %</th><th>Memory %</th></tr>
        """

        for proc in health_data["processes"]["top_cpu_processes"][:5]:
            html += f"""
                        <tr>
                            <td>{proc['pid']}</td>
                            <td>{proc['name']}</td>
                            <td>{proc['cpu_percent']}%</td>
                            <td>{proc['memory_percent']}%</td>
                        </tr>
            """

        html += """
                    </table>
                </div>

                <p style="margin-top: 30px; color: #6c757d; font-size: 12px;">
                    This is an automated alert from the DevOps System Health Checker.
                </p>
            </div>
        </body>
        </html>
        """

        return html


class SystemHealthChecker:
    """Monitor and report system health metrics with enhanced features"""

    def __init__(self, config_path="config.json"):
        self.timestamp = datetime.datetime.now()
        self.health_data = OrderedDict()
        self.config = self._load_config(config_path)
        self.db_checker = DatabaseChecker()
        self.email_alerter = EmailAlerter(self.config.get("email", {}))

    def _load_config(self, config_path):
        """Load configuration from JSON file"""
        if os.path.exists(config_path):
            try:
                with open(config_path, "r") as f:
                    return json.load(f)
            except Exception as e:
                print(f"Warning: Could not load config file: {e}")
                return self._get_default_config()
        else:
            print(f"Config file not found: {config_path}. Using defaults.")
            return self._get_default_config()

    def _get_default_config(self):
        """Return default configuration"""
        return {
            "email": {"enabled": False},
            "thresholds": {
                "cpu_warning": 60,
                "cpu_critical": 80,
                "memory_warning": 60,
                "memory_critical": 80,
                "disk_warning": 60,
                "disk_critical": 80,
            },
            "databases": {"check_enabled": False, "connections": []},
            "monitoring": {"report_path": "./", "keep_history": False},
        }

    def get_system_info(self):
        """Gather basic system information"""
        return {
            "hostname": platform.node(),
            "platform": platform.system(),
            "platform_version": platform.version(),
            "architecture": platform.machine(),
            "processor": platform.processor(),
            "python_version": platform.python_version(),
        }

    def get_cpu_info(self):
        """Get CPU usage and information"""
        cpu_percent = psutil.cpu_percent(interval=1, percpu=True)
        total_percent = psutil.cpu_percent(interval=1)

        return {
            "cpu_count": psutil.cpu_count(logical=False),
            "cpu_count_logical": psutil.cpu_count(logical=True),
            "cpu_percent_total": total_percent,
            "cpu_percent_per_core": cpu_percent,
            "cpu_freq": psutil.cpu_freq()._asdict() if psutil.cpu_freq() else None,
            "status": self._get_status(total_percent, "cpu"),
        }

    def get_memory_info(self):
        """Get memory usage information"""
        memory = psutil.virtual_memory()
        swap = psutil.swap_memory()

        return {
            "total_gb": round(memory.total / (1024**3), 2),
            "available_gb": round(memory.available / (1024**3), 2),
            "used_gb": round(memory.used / (1024**3), 2),
            "percent_used": memory.percent,
            "swap_total_gb": round(swap.total / (1024**3), 2),
            "swap_used_gb": round(swap.used / (1024**3), 2),
            "swap_percent": swap.percent,
            "status": self._get_status(memory.percent, "memory"),
        }

    def get_disk_info(self):
        """Get disk usage information"""
        partitions = psutil.disk_partitions()
        disk_data = []

        for partition in partitions:
            try:
                usage = psutil.disk_usage(partition.mountpoint)
                disk_data.append(
                    {
                        "device": partition.device,
                        "mountpoint": partition.mountpoint,
                        "fstype": partition.fstype,
                        "total_gb": round(usage.total / (1024**3), 2),
                        "used_gb": round(usage.used / (1024**3), 2),
                        "free_gb": round(usage.free / (1024**3), 2),
                        "percent_used": usage.percent,
                        "status": self._get_status(usage.percent, "disk"),
                    }
                )
            except PermissionError:
                continue

        return disk_data

    def get_network_info(self):
        """Get network interface information"""
        net_io = psutil.net_io_counters()
        interfaces = psutil.net_if_addrs()

        return {
            "bytes_sent_mb": round(net_io.bytes_sent / (1024**2), 2),
            "bytes_recv_mb": round(net_io.bytes_recv / (1024**2), 2),
            "packets_sent": net_io.packets_sent,
            "packets_recv": net_io.packets_recv,
            "errors_in": net_io.errin,
            "errors_out": net_io.errout,
            "interface_count": len(interfaces),
        }

    def get_process_info(self):
        """Get running process information"""
        process_count = len(psutil.pids())
        processes = []

        # Get top 5 CPU consuming processes
        for proc in sorted(
            psutil.process_iter(["pid", "name", "cpu_percent", "memory_percent"]),
            key=lambda p: p.info["cpu_percent"] or 0,
            reverse=True,
        )[:5]:
            try:
                processes.append(
                    {
                        "pid": proc.info["pid"],
                        "name": proc.info["name"],
                        "cpu_percent": proc.info["cpu_percent"],
                        "memory_percent": round(proc.info["memory_percent"], 2),
                    }
                )
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue

        return {"total_processes": process_count, "top_cpu_processes": processes}

    def check_databases(self):
        """Check database connectivity"""
        if not self.config["databases"].get("check_enabled", False):
            return []

        db_configs = self.config["databases"].get("connections", [])
        if not db_configs:
            return []

        print("Checking database connectivity...")
        return self.db_checker.check_all(db_configs)

    def _get_status(self, percent, resource_type="cpu"):
        """Determine health status based on percentage and thresholds"""
        thresholds = self.config.get("thresholds", {})
        warning = thresholds.get(f"{resource_type}_warning", 60)
        critical = thresholds.get(f"{resource_type}_critical", 80)

        if percent < warning:
            return "HEALTHY"
        elif percent < critical:
            return "WARNING"
        else:
            return "CRITICAL"

    def get_overall_health(self):
        """Calculate overall system health"""
        cpu_status = self.health_data["cpu"]["status"]
        memory_status = self.health_data["memory"]["status"]

        disk_statuses = [disk["status"] for disk in self.health_data["disk"]]
        worst_disk_status = "HEALTHY"

        if "CRITICAL" in disk_statuses:
            worst_disk_status = "CRITICAL"
        elif "WARNING" in disk_statuses:
            worst_disk_status = "WARNING"

        statuses = [cpu_status, memory_status, worst_disk_status]

        # Check databases if enabled
        if self.health_data.get("databases"):
            db_statuses = [db["status"] for db in self.health_data["databases"]]
            if "FAILED" in db_statuses:
                statuses.append("CRITICAL")

        if "CRITICAL" in statuses:
            return "CRITICAL"
        elif "WARNING" in statuses:
            return "WARNING"
        else:
            return "HEALTHY"

    def collect_all_metrics(self):
        """Collect all system health metrics"""
        print("Collecting system health metrics...\n")

        self.health_data["timestamp"] = self.timestamp.isoformat()
        self.health_data["system"] = self.get_system_info()
        self.health_data["cpu"] = self.get_cpu_info()
        self.health_data["memory"] = self.get_memory_info()
        self.health_data["disk"] = self.get_disk_info()
        self.health_data["network"] = self.get_network_info()
        self.health_data["processes"] = self.get_process_info()

        # Check databases if enabled
        db_results = self.check_databases()
        if db_results:
            self.health_data["databases"] = db_results

        self.health_data["overall_health"] = self.get_overall_health()

        return self.health_data

    def print_report(self):
        """Print a formatted health report"""
        data = self.health_data

        print("=" * 80)
        print(f"SYSTEM HEALTH REPORT - {data['timestamp']}")
        print("=" * 80)

        print(f"\nOVERALL HEALTH: {data['overall_health']}")

        print("\n" + "-" * 80)
        print("SYSTEM INFORMATION")
        print("-" * 80)
        for key, value in data["system"].items():
            print(f"  {key.replace('_', ' ').title()}: {value}")

        print("\n" + "-" * 80)
        print(f"CPU - {data['cpu']['status']}")
        print("-" * 80)
        print(f"  Physical Cores: {data['cpu']['cpu_count']}")
        print(f"  Logical Cores: {data['cpu']['cpu_count_logical']}")
        print(f"  Total Usage: {data['cpu']['cpu_percent_total']}%")

        print("\n" + "-" * 80)
        print(f"MEMORY - {data['memory']['status']}")
        print("-" * 80)
        print(f"  Total: {data['memory']['total_gb']} GB")
        print(
            f"  Used: {data['memory']['used_gb']} GB ({data['memory']['percent_used']}%)"
        )
        print(f"  Available: {data['memory']['available_gb']} GB")
        print(
            f"  Swap Used: {data['memory']['swap_used_gb']} GB ({data['memory']['swap_percent']}%)"
        )

        print("\n" + "-" * 80)
        print("DISK USAGE")
        print("-" * 80)
        for disk in data["disk"]:
            print(f"  {disk['mountpoint']} ({disk['device']}) - {disk['status']}")
            print(
                f"    Total: {disk['total_gb']} GB | Used: {disk['used_gb']} GB ({disk['percent_used']}%)"
            )

        print("\n" + "-" * 80)
        print("NETWORK")
        print("-" * 80)
        print(f"  Data Sent: {data['network']['bytes_sent_mb']} MB")
        print(f"  Data Received: {data['network']['bytes_recv_mb']} MB")
        print(f"  Packets Sent: {data['network']['packets_sent']}")
        print(f"  Packets Received: {data['network']['packets_recv']}")
        print(f"  Errors In: {data['network']['errors_in']}")
        print(f"  Errors Out: {data['network']['errors_out']}")

        # Print database status if available
        if "databases" in data and data["databases"]:
            print("\n" + "-" * 80)
            print("DATABASE CONNECTIVITY")
            print("-" * 80)
            for db in data["databases"]:
                status_symbol = "✓" if db["status"] == "CONNECTED" else "✗"
                print(f"  {status_symbol} {db['name']} ({db['type']}) - {db['status']}")
                print(f"    Host: {db['host']}:{db['port']} | {db['message']}")

        print("\n" + "-" * 80)
        print("TOP CPU CONSUMING PROCESSES")
        print("-" * 80)
        for proc in data["processes"]["top_cpu_processes"]:
            print(
                f"  PID: {proc['pid']} | {proc['name']} | CPU: {proc['cpu_percent']}% | MEM: {proc['memory_percent']}%"
            )

        print("\n" + "=" * 80)

    def export_to_json(self, filename=None):
        """Export health data to JSON file"""
        if filename is None:
            report_path = self.config["monitoring"].get("report_path", "./")
            os.makedirs(report_path, exist_ok=True)

            if self.config["monitoring"].get("keep_history", False):
                timestamp_str = self.timestamp.strftime("%Y%m%d_%H%M%S")
                filename = os.path.join(
                    report_path, f"health_report_{timestamp_str}.json"
                )
            else:
                filename = os.path.join(report_path, "system_health_report.json")

        with open(filename, "w") as f:
            json.dump(self.health_data, f, indent=2)
        print(f"\nHealth report exported to: {filename}")
        return filename

    def send_alert(self):
        """Send email alert if conditions are met"""
        result = self.email_alerter.send_alert(self.health_data)

        if result["sent"]:
            print(
                f"\n[EMAIL] Alert sent to {', '.join(self.config['email']['recipient_emails'])}"
            )
        elif self.config["email"].get("enabled", False):
            print(f"\n[EMAIL] Alert not sent: {result['message']}")

        return result


def main():
    """Main execution function"""
    parser = argparse.ArgumentParser(
        description="System Health Checker V2 - Enhanced Monitoring"
    )
    parser.add_argument(
        "--config", default="config.json", help="Path to configuration file"
    )
    parser.add_argument(
        "--no-email", action="store_true", help="Disable email alerts for this run"
    )
    parser.add_argument("--quiet", action="store_true", help="Suppress console output")

    args = parser.parse_args()

    checker = SystemHealthChecker(config_path=args.config)

    # Disable email if flag is set
    if args.no_email:
        checker.email_alerter.enabled = False

    # Collect metrics
    checker.collect_all_metrics()

    # Print report unless quiet mode
    if not args.quiet:
        checker.print_report()

    # Export to JSON
    checker.export_to_json()

    # Send email alert if needed
    checker.send_alert()

    # Exit with appropriate status code
    exit_code = 0
    if checker.health_data["overall_health"] == "CRITICAL":
        if not args.quiet:
            print(
                "\n[ALERT] System is in CRITICAL state! Immediate attention required."
            )
        exit_code = 2
    elif checker.health_data["overall_health"] == "WARNING":
        if not args.quiet:
            print("\n[WARNING] System resources are running high. Monitor closely.")
        exit_code = 1
    else:
        if not args.quiet:
            print("\n[OK] System is healthy.")

    sys.exit(exit_code)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nHealth check interrupted by user.")
        sys.exit(130)
    except Exception as e:
        print(f"\nError during health check: {str(e)}")
        sys.exit(1)
