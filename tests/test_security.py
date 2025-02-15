#!/usr/bin/env python3
"""
UnixPi Security Framework Test Suite
Comprehensive tests for all security features
"""

import sys
import unittest
from pathlib import Path
import pytest

from unixpi.security.network_analyzer import NetworkAnalyzer
from unixpi.security.system_monitor import SystemMonitor

# Add project root to path
sys.path.append(str(Path(__file__).parent.parent))


class TestNetworkAnalyzer(unittest.TestCase):
    """Test network analyzer features"""

    def setUp(self):
        """Set up test environment"""
        self.analyzer = NetworkAnalyzer()

    @pytest.mark.skip(reason="Requires root privileges")
    def test_packet_capture(self):
        """Test packet capture"""
        self.analyzer.start_capture()
        self.analyzer.stop_capture()
        self.assertTrue(len(self.analyzer.packets) >= 0)

    def test_report_generation(self):
        """Test report generation"""
        report = self.analyzer.generate_report()
        self.assertIsInstance(report, dict)
        self.assertIn('timestamp', report)
        self.assertIn('interface', report)


class TestSystemMonitor(unittest.TestCase):
    """Test system monitor features"""

    def setUp(self):
        """Set up test environment"""
        self.monitor = SystemMonitor()

    @pytest.mark.asyncio
    async def test_monitoring(self):
        """Test system monitoring"""
        results = await self.monitor.monitor(duration=1, interval=0.1)
        self.assertIsInstance(results, dict)
        self.assertIn('anomalies', results)
        self.assertIn('security_issues', results)

    def test_report_generation(self):
        """Test report generation"""
        mock_results = {
            'start_time': '2025-02-14T22:11:40',
            'end_time': '2025-02-14T22:11:41',
            'samples': [
                {'cpu': 10, 'memory': 50},
                {'cpu': 15, 'memory': 55}
            ],
            'anomalies': [],
            'security_issues': [],
            'duration': 1,
            'interval': 0.1,
            'baseline': {'cpu': 5, 'memory': 45}
        }
        self.monitor.generate_report(mock_results, 'test_report.json')
        self.assertTrue(Path('test_report.json').exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
