#!/usr/bin/env python3
"""
System Health Checker - DevOps Automation Script
Author: Joshua
Description: Monitors system resources and generates health reports
"""

import psutil
import platform
import datetime
import json
from collections import OrderedDict


class SystemHealthChecker:
    """Monitor and report system health metrics"""

    def __init__(self):
        self.timestamp = datetime.datetime.now()
        self.health_data = OrderedDict()

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
        return {
            "cpu_count": psutil.cpu_count(logical=False),
            "cpu_count_logical": psutil.cpu_count(logical=True),
            "cpu_percent_total": psutil.cpu_percent(interval=1),
            "cpu_percent_per_core": cpu_percent,
            "cpu_freq": psutil.cpu_freq()._asdict() if psutil.cpu_freq() else None,
            "status": self._get_status(psutil.cpu_percent(interval=1)),
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
            "status": self._get_status(memory.percent),
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
                        "status": self._get_status(usage.percent),
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

    def _get_status(self, percent):
        """Determine health status based on percentage"""
        if percent < 60:
            return "HEALTHY"
        elif percent < 80:
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

        print("\n" + "-" * 80)
        print("TOP CPU CONSUMING PROCESSES")
        print("-" * 80)
        for proc in data["processes"]["top_cpu_processes"]:
            print(
                f"  PID: {proc['pid']} | {proc['name']} | CPU: {proc['cpu_percent']}% | MEM: {proc['memory_percent']}%"
            )

        print("\n" + "=" * 80)

    def export_to_json(self, filename="system_health_report.json"):
        """Export health data to JSON file"""
        with open(filename, "w") as f:
            json.dump(self.health_data, f, indent=2)
        print(f"\nHealth report exported to: {filename}")


def main():
    """Main execution function"""
    checker = SystemHealthChecker()

    # Collect metrics
    checker.collect_all_metrics()

    # Print report
    checker.print_report()

    # Export to JSON
    checker.export_to_json()

    # Alert on critical status
    if checker.health_data["overall_health"] == "CRITICAL":
        print("\n[ALERT] System is in CRITICAL state! Immediate attention required.")
    elif checker.health_data["overall_health"] == "WARNING":
        print("\n[WARNING] System resources are running high. Monitor closely.")
    else:
        print("\n[OK] System is healthy.")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nHealth check interrupted by user.")
    except Exception as e:
        print(f"\nError during health check: {str(e)}")
