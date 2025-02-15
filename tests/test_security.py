#!/usr/bin/env python3
"""
UnixPi Security Framework Test Suite
Comprehensive tests for all security features
"""

import asyncio
import json
import sys
import unittest
from datetime import datetime
from pathlib import Path
from unittest.mock import MagicMock, patch
import logging

import pytest
from scapy.layers.inet import IP, TCP, UDP
from scapy.packet import Packet

from unixpi.security.network_analyzer import NetworkAnalyzer
from unixpi.security.system_monitor import SystemMonitor

# Add project root to path
sys.path.append(str(Path(__file__).parent.parent))


def create_mock_packet(protocol="TCP", src="192.168.1.1", dst="192.168.1.2"):
    """Create a mock packet for testing"""
    packet = Packet()
    ip_layer = IP(src=src, dst=dst)
    if protocol == "TCP":
        proto_layer = TCP(sport=12345, dport=80)
    else:
        proto_layer = UDP(sport=12345, dport=53)

    packet.add_payload(ip_layer)
    ip_layer.add_payload(proto_layer)
    return packet


class TestNetworkAnalyzer(unittest.TestCase):
    """Test network analyzer features"""

    def setUp(self):
        """Set up test environment"""
        self.analyzer = NetworkAnalyzer()

    def test_process_packet(self):
        """Test packet processing without root privileges"""
        # Test TCP packet
        tcp_packet = create_mock_packet("TCP")
        self.analyzer._process_packet(tcp_packet)
        self.assertIn("TCP", self.analyzer.protocols)

        # Test UDP packet
        udp_packet = create_mock_packet("UDP")
        self.analyzer._process_packet(udp_packet)
        self.assertIn("UDP", self.analyzer.protocols)

        # Verify connection tracking
        conn_key = f"{tcp_packet[IP].src}:{tcp_packet[IP].dst}"
        self.assertIn(conn_key, self.analyzer.connections)
        self.assertGreater(self.analyzer.connections[conn_key]["packets"], 0)

    def test_report_generation(self):
        """Test report generation"""
        # Process some packets first
        for _ in range(3):
            self.analyzer._process_packet(create_mock_packet())

        report = self.analyzer.generate_report()
        self.assertIsInstance(report, dict)
        self.assertIn("timestamp", report)
        self.assertIn("interface", report)
        self.assertIn("protocols", report)
        self.assertIn("connections", report)
        self.assertGreater(len(report["protocols"]), 0)

    def test_error_handling(self):
        """Test error handling in packet processing"""
        with self.assertLogs(level="ERROR") as cm:
            # Create an invalid packet that will cause an error
            self.analyzer._process_packet(None)
            self.assertTrue(any("error" in msg.lower() for msg in cm.output))

    def test_invalid_packet_handling(self):
        analyzer = NetworkAnalyzer()
        analyzer._process_packet(None)  # Should handle gracefully without raising an error
        report = analyzer.generate_report()
        assert report['total_connections'] == 0

    def test_empty_report_generation(self):
        analyzer = NetworkAnalyzer()
        report = analyzer.generate_report()
        assert report['total_connections'] == 0

    def test_packet_protocol_detection(self):
        analyzer = NetworkAnalyzer()
        tcp_packet = create_mock_packet("TCP")
        udp_packet = create_mock_packet("UDP")
        analyzer._process_packet(tcp_packet)
        analyzer._process_packet(udp_packet)
        report = analyzer.generate_report()
        assert "TCP" in report["protocols"]
        assert "UDP" in report["protocols"]

    def test_packet_source_destination_detection(self):
        analyzer = NetworkAnalyzer()
        packet = create_mock_packet("TCP", src="192.168.1.100", dst="192.168.1.200")
        analyzer._process_packet(packet)
        report = analyzer.generate_report()
        assert "192.168.1.100:192.168.1.200" in report["connections"]
        # Check if the connection exists and has the correct data
        connection_data = report["connections"]["192.168.1.100:192.168.1.200"]
        assert connection_data["packets"] == 1
        assert connection_data["bytes"] > 0


@pytest.mark.asyncio
class TestSystemMonitor(unittest.IsolatedAsyncioTestCase):
    """Test system monitor features"""

    def setUp(self):
        """Set up test environment"""
        self.monitor = SystemMonitor()

    @pytest.mark.asyncio
    async def test_monitoring(self):
        """Test system monitoring"""
        results = await self.monitor.monitor(duration=1, interval=0.1)
        self.assertIsInstance(results, dict)
        self.assertIn("anomalies", results)
        self.assertIn("security_issues", results)
        self.assertIn("samples", results)
        self.assertGreater(len(results["samples"]), 0)

    @pytest.mark.asyncio
    async def test_system_state(self):
        """Test system state collection"""
        state = await self.monitor._get_system_state()
        self.assertIn("timestamp", state)
        self.assertIn("cpu", state)
        self.assertIn("memory", state)
        self.assertIn("processes", state)

    @pytest.mark.asyncio
    async def test_anomaly_detection(self):
        """Test anomaly detection"""
        sample = await self.monitor._get_system_state()
        results = {"anomalies": [], "samples": [sample]}
        await self.monitor._check_anomalies(sample, results)
        self.assertIsInstance(results["anomalies"], list)

    def test_report_generation(self):
        """Test report generation"""
        mock_results = {
            "start_time": datetime.now().isoformat(),
            "end_time": datetime.now().isoformat(),
            "samples": [
                {"cpu": {"percent": 10}, "memory": {"percent": 50}},
                {"cpu": {"percent": 15}, "memory": {"percent": 55}},
            ],
            "anomalies": [
                {
                    "type": "CPU",
                    "message": "High CPU usage detected",
                    "severity": "HIGH",
                }
            ],
            "security_issues": [
                {
                    "type": "Process",
                    "message": "Suspicious process detected",
                    "severity": "MEDIUM",
                }
            ],
            "duration": 1,
            "interval": 0.1,
            "baseline": {"cpu": {"percent": 5}, "memory": {"percent": 45}},
        }
        report_file = "test_report.json"
        self.monitor.generate_report(mock_results, report_file)

        # Verify report contents
        self.assertTrue(Path(report_file).exists())
        with open(report_file) as f:
            report_data = json.load(f)
            self.assertEqual(len(report_data["anomalies"]), 1)
            self.assertEqual(len(report_data["security_issues"]), 1)
            self.assertEqual(report_data["summary"]["total_anomalies"], 1)
            self.assertEqual(report_data["summary"]["total_security_issues"], 1)
            self.assertEqual(report_data["summary"]["risk_level"], "HIGH")

    async def test_system_monitor_exception_handling(self):
        monitor = SystemMonitor()
        monitor._get_system_state = lambda: (_ for _ in ()).throw(Exception("Simulated failure"))  # Simulate failure
        with self.assertRaises(Exception):
            await monitor.monitor(duration=5, interval=1)

    async def test_anomaly_detection_exceeds_threshold(self):
        monitor = SystemMonitor()
        monitor.thresholds["cpu"] = 0  # Set threshold to 0% for testing
        state = await monitor._get_system_state()
        results = await monitor.monitor(duration=5, interval=1)
        assert any(anomaly["type"] == "CPU" for anomaly in results["anomalies"])

    async def test_anomaly_detection_cpu_usage(self):
        monitor = SystemMonitor()
        monitor.thresholds["cpu"] = 50  # Set threshold to 50% for testing
        state = await monitor._get_system_state()
        state["cpu"]["percent"] = 75  # Simulate high CPU usage
        results = {"anomalies": [], "samples": [state]}
        await monitor._check_anomalies(state, results)
        assert any(anomaly["type"] == "CPU" for anomaly in results["anomalies"])

    async def test_anomaly_detection_memory_usage(self):
        logger = logging.getLogger(__name__)
        logger.setLevel(logging.DEBUG)
        monitor = SystemMonitor()
        monitor.thresholds["memory"] = 50  # Set threshold to 50% for testing
        state = await monitor._get_system_state()
        state["memory"] = {"total": 100, "available": 25, "percent": 75}  # Simulate high memory usage
        results = {"anomalies": [], "samples": [state]}
        await monitor._check_anomalies(state, results)
        logger.debug(f"Anomalies detected: {results['anomalies']}")
        assert any(anomaly["type"] == "Memory" for anomaly in results["anomalies"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
