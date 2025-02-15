#!/usr/bin/env python3
"""
Network Analyzer Module
Analyzes network traffic and generates security reports
"""

import logging
from datetime import datetime
from typing import Dict, Optional

from scapy.layers.inet import IP, TCP, UDP
from scapy.packet import Packet

logger = logging.getLogger(__name__)


class NetworkAnalyzer:
    """Network traffic analyzer for security monitoring"""

    def __init__(self):
        """Initialize the network analyzer"""
        self.protocols = set()
        self.connections = {}
        self.interface = "any"
        self.start_time = datetime.now()

    def _process_packet(self, packet: Optional[Packet]) -> None:
        """Process a single packet and update statistics"""
        try:
            if not packet or not packet.haslayer(IP):
                raise ValueError("Invalid packet or missing IP layer")

            # Extract IP layer
            ip = packet[IP]

            # Track protocols
            if packet.haslayer(TCP):
                self.protocols.add("TCP")
                proto = "TCP"
            elif packet.haslayer(UDP):
                self.protocols.add("UDP")
                proto = "UDP"
            else:
                proto = "OTHER"
                self.protocols.add(proto)

            # Track connections
            conn_key = f"{ip.src}:{ip.dst}"
            if conn_key not in self.connections:
                self.connections[conn_key] = {
                    "protocol": proto,
                    "packets": 0,
                    "bytes": 0,
                    "first_seen": datetime.now(),
                    "last_seen": datetime.now(),
                }

            self.connections[conn_key]["packets"] += 1
            self.connections[conn_key]["bytes"] += len(packet)
            self.connections[conn_key]["last_seen"] = datetime.now()

        except Exception as e:
            logger.error(f"Error processing packet: {e}")

    def generate_report(self) -> Dict:
        """Generate a report of network activity"""
        return {
            "timestamp": datetime.now().isoformat(),
            "start_time": self.start_time.isoformat(),
            "interface": self.interface,
            "protocols": list(self.protocols),
            "connections": self.connections,
            "total_connections": len(self.connections),
            "unique_protocols": len(self.protocols),
        }
