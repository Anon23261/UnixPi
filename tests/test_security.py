#!/usr/bin/env python3
"""
UnixPi Security Framework Test Suite
Comprehensive tests for all security features
"""

import os
import sys
import unittest
from pathlib import Path

# Add project root to path
sys.path.append(str(Path(__file__).parent.parent))

from UnixPi.security.anonymity import AnonymityFramework
from UnixPi.security.iot import IoTScanner, Protocol, SecurityLevel
from UnixPi.security.network import NetworkScanner


class TestIoTSecurity(unittest.TestCase):
    """Test IoT security features"""

    def setUp(self):
        self.scanner = IoTScanner(SecurityLevel.ADVANCED)

    def test_device_discovery(self):
        """Test device discovery functionality"""
        devices = self.scanner.start_scan([Protocol.BLUETOOTH, Protocol.WIFI])
        self.assertIsNotNone(devices)
        self.assertIsInstance(devices, list)

    def test_vulnerability_scan(self):
        """Test vulnerability scanning"""
        results = self.scanner.analyze_device(mock_device())
        self.assertIn("vulnerabilities", results)
        self.assertIn("security_score", results)


class TestAnonymity(unittest.TestCase):
    """Test anonymity features"""

    def setUp(self):
        self.framework = AnonymityFramework()

    def test_tor_connection(self):
        """Test Tor connection"""
        status = self.framework.check_tor_connection()
        self.assertTrue(status)

    def test_ip_masking(self):
        """Test IP masking"""
        original_ip = self.framework.get_current_ip()
        self.framework.enable_anonymity()
        masked_ip = self.framework.get_current_ip()
        self.assertNotEqual(original_ip, masked_ip)


class TestNetworkSecurity(unittest.TestCase):
    """Test network security features"""

    def setUp(self):
        self.scanner = NetworkScanner()

    def test_port_scan(self):
        """Test port scanning"""
        results = self.scanner.scan_ports("localhost")
        self.assertIsInstance(results, dict)

    def test_firewall(self):
        """Test firewall configuration"""
        status = self.scanner.check_firewall()
        self.assertTrue(status)


class TestSystemSecurity(unittest.TestCase):
    """Test system security features"""

    def test_secure_boot(self):
        """Test secure boot configuration"""
        with open("/boot/config.txt", "r") as f:
            config = f.read()
        self.assertIn("arm_64bit=1", config)
        self.assertIn("disable_commandline_tags=1", config)

    def test_kernel_hardening(self):
        """Test kernel security parameters"""
        with open("/etc/sysctl.d/99-security.conf", "r") as f:
            config = f.read()
        self.assertIn("kernel.kptr_restrict=2", config)
        self.assertIn("kernel.dmesg_restrict=1", config)


def mock_device():
    """Create a mock IoT device for testing"""
    return {
        "name": "Test Device",
        "mac_address": "00:11:22:33:44:55",
        "protocols": [Protocol.BLUETOOTH],
        "open_ports": [80, 443],
    }


if __name__ == "__main__":
    unittest.main(verbosity=2)
