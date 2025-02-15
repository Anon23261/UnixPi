#!/usr/bin/env python3
"""
System Monitor Module
Monitors system state and detects security anomalies
"""

import asyncio
import json
import logging
import os
import platform
import psutil
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

logger = logging.getLogger(__name__)


class SystemMonitor:
    """System state and security monitor"""

    def __init__(self):
        """Initialize the system monitor"""
        self.baseline = None
        self.thresholds = {
            "cpu": 80.0,  # CPU usage threshold (%)
            "memory": 85.0,  # Memory usage threshold (%)
            "disk": 90.0,  # Disk usage threshold (%)
            "network": 1000000,  # Network traffic threshold (bytes/s)
        }

    async def _get_system_state(self) -> Dict:
        """Get current system state"""
        try:
            cpu_percent = psutil.cpu_percent(interval=0.1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage("/")
            net_io = psutil.net_io_counters()

            return {
                "timestamp": datetime.now().isoformat(),
                "cpu": {"percent": cpu_percent, "count": psutil.cpu_count()},
                "memory": {
                    "total": memory.total,
                    "available": memory.available,
                    "percent": memory.percent,
                },
                "disk": {
                    "total": disk.total,
                    "used": disk.used,
                    "free": disk.free,
                    "percent": disk.percent,
                },
                "network": {
                    "bytes_sent": net_io.bytes_sent,
                    "bytes_recv": net_io.bytes_recv,
                    "packets_sent": net_io.packets_sent,
                    "packets_recv": net_io.packets_recv,
                },
                "processes": len(psutil.pids()),
                "boot_time": datetime.fromtimestamp(psutil.boot_time()).isoformat(),
            }
        except Exception as e:
            logger.error(f"Error getting system state: {e}")
            return {}

    async def _check_anomalies(self, state: Dict, results: Dict) -> None:
        """Check for system anomalies"""
        if not state:
            return

        logger.debug(f"Checking for anomalies in state: {state}")
        logger.debug(f"Current thresholds: {self.thresholds}")
        logger.debug(
            f"CPU usage: {state['cpu']['percent']}% | Threshold: {self.thresholds['cpu']}%"
        )
        logger.debug(
            f"Memory usage: {state['memory']['percent']}% | Threshold: {self.thresholds['memory']}%"
        )
        logger.debug(f"Memory total: {state['memory']['total']} bytes")
        logger.debug(f"Memory available: {state['memory']['available']} bytes")
        logger.debug(
            f"Disk usage: {state['disk']['percent']}% | Threshold: {self.thresholds['disk']}%"
        )
        logger.debug(
            f"Network traffic: {state['network']['bytes_sent']} bytes/s | Threshold: {self.thresholds['network']} bytes/s"
        )

        # CPU anomalies
        if state["cpu"]["percent"] > self.thresholds["cpu"]:
            results["anomalies"].append(
                {
                    "type": "CPU",
                    "message": f"High CPU usage: {state['cpu']['percent']}%",
                    "severity": "HIGH",
                    "timestamp": state["timestamp"],
                }
            )

        # Memory anomalies
        if state["memory"]["percent"] > self.thresholds["memory"]:
            results["anomalies"].append(
                {
                    "type": "Memory",
                    "message": f"High memory usage: {state['memory']['percent']}%",
                    "severity": "HIGH",
                    "timestamp": state["timestamp"],
                }
            )

        # Disk anomalies
        if state["disk"]["percent"] > self.thresholds["disk"]:
            results["anomalies"].append(
                {
                    "type": "Disk",
                    "message": f"High disk usage: {state['disk']['percent']}%",
                    "severity": "HIGH",
                    "timestamp": state["timestamp"],
                }
            )

    async def monitor(self, duration: int = 60, interval: float = 1.0) -> Dict:
        """Monitor system for the specified duration"""
        start_time = datetime.now()
        results = {
            "start_time": start_time.isoformat(),
            "duration": duration,
            "interval": interval,
            "samples": [],
            "anomalies": [],
            "security_issues": [],
        }

        # Collect samples
        iterations = int(duration / interval)
        for _ in range(iterations):
            state = await self._get_system_state()
            if state:
                results["samples"].append(state)
                await self._check_anomalies(state, results)
            await asyncio.sleep(interval)

        results["end_time"] = datetime.now().isoformat()
        return results

    def generate_report(self, results: Dict, output_file: str) -> None:
        """Generate a monitoring report"""
        try:
            # Calculate summary statistics
            total_anomalies = len(results["anomalies"])
            total_security_issues = len(results["security_issues"])

            # Determine overall risk level
            risk_level = "LOW"
            if total_anomalies > 0 or total_security_issues > 0:
                risk_level = "HIGH"

            # Add summary to results
            results["summary"] = {
                "total_anomalies": total_anomalies,
                "total_security_issues": total_security_issues,
                "risk_level": risk_level,
                "system_info": {
                    "platform": platform.platform(),
                    "python_version": platform.python_version(),
                    "hostname": platform.node(),
                },
            }

            # Write report to file
            with open(output_file, "w") as f:
                json.dump(results, f, indent=2)

        except Exception as e:
            logger.error(f"Error generating report: {e}")
            raise
