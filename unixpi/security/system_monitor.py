#!/usr/bin/env python3
"""
UnixPi System Monitor
Professional system security monitoring tool
"""

import asyncio
import json
import logging
import os
from datetime import datetime
from typing import Dict, List

import psutil


class SystemMonitor:
    """Professional system monitoring implementation."""

    def __init__(self, log_file: str = "system_monitor.log"):
        """Initialize the system monitor.

        Args:
            log_file: Path to log file
        """
        # Setup logging
        self.logger = logging.getLogger("SystemMonitor")
        self.logger.setLevel(logging.INFO)
        handler = logging.FileHandler(log_file)
        handler.setFormatter(
            logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
        )
        self.logger.addHandler(handler)

        # Initialize baseline
        self.baseline = None

    async def monitor(self, duration: int = 60, interval: float = 1.0) -> Dict:
        """Monitor system security.

        Args:
            duration: Monitoring duration in seconds
            interval: Sampling interval in seconds

        Returns:
            Dictionary containing monitoring results
        """
        results = {
            "start_time": datetime.now().isoformat(),
            "duration": duration,
            "interval": interval,
            "samples": [],
            "anomalies": [],
            "security_issues": [],
        }

        try:
            # Take initial baseline
            if not self.baseline:
                self.baseline = await self._get_system_state()
                results["baseline"] = self.baseline

            # Monitor system
            samples_count = int(duration / interval)
            for _ in range(samples_count):
                sample = await self._get_system_state()
                results["samples"].append(sample)

                # Check for anomalies
                await self._check_anomalies(sample, results)

                await asyncio.sleep(interval)

            # Final security assessment
            await self._security_assessment(results)

            self.logger.info("System monitoring completed")

        except Exception as e:
            self.logger.error(f"Monitoring error: {str(e)}")
            raise

        return results

    async def _get_system_state(self) -> Dict:
        """Get current system state.

        Returns:
            Dictionary containing system state
        """
        state = {
            "timestamp": datetime.now().isoformat(),
            "cpu": {
                "percent": psutil.cpu_percent(interval=0.1),
                "count": psutil.cpu_count(),
                "freq": psutil.cpu_freq()._asdict() if psutil.cpu_freq() else None,
            },
            "memory": {
                "virtual": psutil.virtual_memory()._asdict(),
                "swap": psutil.swap_memory()._asdict(),
            },
            "disk": {
                "usage": {
                    path: psutil.disk_usage(path)._asdict()
                    for path in psutil.disk_partitions()
                    if os.path.exists(path.mountpoint)
                },
                "io": (
                    psutil.disk_io_counters()._asdict()
                    if psutil.disk_io_counters()
                    else None
                ),
            },
            "network": {
                "connections": len(psutil.net_connections()),
                "io": (
                    psutil.net_io_counters()._asdict()
                    if psutil.net_io_counters()
                    else None
                ),
            },
            "processes": {
                "total": len(psutil.pids()),
                "running": len(
                    [
                        p
                        for p in psutil.process_iter(["status"])
                        if p.info["status"] == "running"
                    ]
                ),
            },
            "users": len(psutil.users()),
        }

        return state

    async def _check_anomalies(self, sample: Dict, results: Dict):
        """Check for system anomalies.

        Args:
            sample: Current system state
            results: Monitoring results
        """
        # CPU usage spike
        if sample["cpu"]["percent"] > 90:
            results["anomalies"].append(
                {
                    "timestamp": sample["timestamp"],
                    "type": "CPU_USAGE",
                    "severity": "HIGH",
                    "description": f"High CPU usage: {sample['cpu']['percent']}%",
                }
            )

        # Memory pressure
        if sample["memory"]["virtual"]["percent"] > 90:
            results["anomalies"].append(
                {
                    "timestamp": sample["timestamp"],
                    "type": "MEMORY_USAGE",
                    "severity": "HIGH",
                    "description": (
                        f"High memory usage: {sample['memory']['virtual']['percent']}%"
                    ),
                }
            )

        # Disk space
        for path, usage in sample["disk"]["usage"].items():
            if usage["percent"] > 90:
                results["anomalies"].append(
                    {
                        "timestamp": sample["timestamp"],
                        "type": "DISK_SPACE",
                        "severity": "MEDIUM",
                        "description": (
                            f"Low disk space on {path}: {usage['percent']}%"
                        ),
                    }
                )

        # Process count
        if sample["processes"]["total"] > self.baseline["processes"]["total"] * 1.5:
            results["anomalies"].append(
                {
                    "timestamp": sample["timestamp"],
                    "type": "PROCESS_COUNT",
                    "severity": "MEDIUM",
                    "description": "Unusual increase in process count",
                }
            )

        # Network connections
        if (
            sample["network"]["connections"]
            > self.baseline["network"]["connections"] * 2
        ):
            results["anomalies"].append(
                {
                    "timestamp": sample["timestamp"],
                    "type": "NETWORK_CONNECTIONS",
                    "severity": "HIGH",
                    "description": "Unusual increase in network connections",
                }
            )

    async def _security_assessment(self, results: Dict):
        """Perform security assessment.

        Args:
            results: Monitoring results
        """
        # Check running processes
        for proc in psutil.process_iter(["name", "username", "cmdline"]):
            try:
                # Check for processes running as root
                if proc.info["username"] == "root":
                    results["security_issues"].append(
                        {
                            "type": "PROCESS_PRIVILEGE",
                            "severity": "MEDIUM",
                            "description": (
                                f"Process {proc.info['name']} running as root"
                            ),
                            "recommendation": "Review process privileges",
                        }
                    )

                # Check for known malicious process names
                if any(
                    mal in proc.info["name"].lower()
                    for mal in ["crypto", "miner", "botnet"]
                ):
                    results["security_issues"].append(
                        {
                            "type": "SUSPICIOUS_PROCESS",
                            "severity": "HIGH",
                            "description": (
                                f"Suspicious process detected: {proc.info['name']}"
                            ),
                            "recommendation": "Investigate process",
                        }
                    )
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue

        # Check network security
        if results["samples"][-1]["network"]["connections"] > 1000:
            results["security_issues"].append(
                {
                    "type": "NETWORK_CONNECTIONS",
                    "severity": "MEDIUM",
                    "description": "High number of network connections",
                    "recommendation": "Review network activity",
                }
            )

    def generate_report(
        self, results: Dict, filename: str = "system_monitor_report.json"
    ):
        """Generate and save monitoring report.

        Args:
            results: Monitoring results
            filename: Output filename
        """
        report = {
            "monitoring_info": {
                "start_time": results["start_time"],
                "duration": results["duration"],
                "interval": results["interval"],
            },
            "system_state": {
                "initial": results["baseline"],
                "final": results["samples"][-1],
            },
            "anomalies": results["anomalies"],
            "security_issues": results["security_issues"],
            "summary": {
                "total_anomalies": len(results["anomalies"]),
                "total_security_issues": len(results["security_issues"]),
                "risk_level": self._calculate_risk_level(
                    results["anomalies"], results["security_issues"]
                ),
            },
        }

        with open(filename, "w") as f:
            json.dump(report, f, indent=2)

        self.logger.info(f"System monitoring report saved to {filename}")

    def _calculate_risk_level(
        self, anomalies: List[Dict], security_issues: List[Dict]
    ) -> str:
        """Calculate overall risk level.

        Args:
            anomalies: List of anomalies
            security_issues: List of security issues

        Returns:
            Risk level string
        """
        severity_scores = {"CRITICAL": 4, "HIGH": 3, "MEDIUM": 2, "LOW": 1}

        # Calculate maximum severity
        max_score = 0
        for item in anomalies + security_issues:
            score = severity_scores.get(item["severity"], 0)
            max_score = max(max_score, score)

        if max_score >= 4:
            return "CRITICAL"
        elif max_score >= 3:
            return "HIGH"
        elif max_score >= 2:
            return "MEDIUM"
        else:
            return "LOW"


async def main():
    """Main function for testing."""
    import sys

    duration = int(sys.argv[1]) if len(sys.argv) > 1 else 60
    interval = float(sys.argv[2]) if len(sys.argv) > 2 else 1.0

    monitor = SystemMonitor()

    print(f"Starting system monitoring")
    print(f"Duration: {duration} seconds")
    print(f"Interval: {interval} seconds")
    print("Press Ctrl+C to stop")

    try:
        results = await monitor.monitor(duration, interval)
        monitor.generate_report(results)

        print("\nMonitoring completed")
        print(f"Anomalies: {len(results['anomalies'])}")
        print(f"Security Issues: {len(results['security_issues'])}")
        print("See system_monitor_report.json for details")

    except KeyboardInterrupt:
        print("\nMonitoring stopped by user")
    except Exception as e:
        print(f"Error during monitoring: {str(e)}")


if __name__ == "__main__":
    asyncio.run(main())
