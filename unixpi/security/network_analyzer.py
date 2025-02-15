#!/usr/bin/env python3
"""
UnixPi Network Analyzer
Professional network traffic analysis tool
"""

import json
import logging
from datetime import datetime
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Set, Union

from scapy.all import ICMP, IP, TCP, UDP, conf, sniff
from scapy.layers.http import HTTP, HTTPRequest

ConnectionStats = Dict[str, Union[str, int, List[str], datetime, Set[str]]]


class NetworkAnalyzer:
    """Professional network analysis implementation."""

    def __init__(
        self, interface: Optional[str] = None, log_file: str = "network_analysis.log"
    ):
        """Initialize the network analyzer.

        Args:
            interface: Network interface to monitor
            log_file: Path to log file
        """
        self.interface = interface or conf.iface
        self.packets: List[Any] = []
        self.connections: Dict[str, ConnectionStats] = {}
        self.protocols: Set[str] = set()

        # Setup logging
        self.logger = logging.getLogger("NetworkAnalyzer")
        self.logger.setLevel(logging.INFO)
        handler = logging.FileHandler(log_file)
        handler.setFormatter(
            logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
        )
        self.logger.addHandler(handler)

    def start_capture(self, duration: int = 60, filter: Optional[str] = None) -> None:
        """Start packet capture.

        Args:
            duration: Capture duration in seconds
            filter: BPF filter string
        """
        self.logger.info(f"Starting capture on {self.interface}")

        try:
            packets = sniff(
                iface=self.interface,
                filter=filter,
                timeout=duration,
                prn=self._process_packet,
            )
            self.packets.extend(packets)

            self.logger.info(
                f"Capture completed: {len(packets)} packets, "
                f"{len(self.protocols)} protocols"
            )

        except Exception as e:
            self.logger.error(f"Capture error: {str(e)}")
            raise

    def _process_packet(self, packet: Any) -> None:
        """Process captured packet.

        Args:
            packet: Scapy packet object
        """
        try:
            # Extract protocol information
            if packet.haslayer(TCP):
                self.protocols.add("TCP")
                self._analyze_tcp(packet)
            elif packet.haslayer(UDP):
                self.protocols.add("UDP")
                self._analyze_udp(packet)
            elif packet.haslayer(ICMP):
                self.protocols.add("ICMP")

            # Track connections
            if IP in packet:
                conn_key = f"{packet[IP].src}:{packet[IP].dst}"
                if conn_key not in self.connections:
                    self.connections[conn_key] = {
                        "packets": 0,
                        "bytes": 0,
                        "start_time": datetime.now(),
                        "protocols": set(),
                    }

                self.connections[conn_key]["packets"] += 1
                self.connections[conn_key]["bytes"] += len(packet)

                if TCP in packet:
                    self.connections[conn_key]["protocols"].add("TCP")
                elif UDP in packet:
                    self.connections[conn_key]["protocols"].add("UDP")

        except Exception as e:
            self.logger.error(f"Packet processing error: {str(e)}")

    def _analyze_tcp(self, packet: Any) -> None:
        """Analyze TCP packet.

        Args:
            packet: TCP packet
        """
        if packet.haslayer(HTTP):
            self.protocols.add("HTTP")
            if packet.haslayer(HTTPRequest):
                self.logger.info(
                    f"HTTP Request: {packet[HTTPRequest].Method.decode()} "
                    f"{packet[HTTPRequest].Path.decode()}"
                )

        # Check for common services
        dport = packet[TCP].dport
        if dport == 80:
            self.protocols.add("HTTP")
        elif dport == 443:
            self.protocols.add("HTTPS")
        elif dport == 22:
            self.protocols.add("SSH")
        elif dport == 21:
            self.protocols.add("FTP")

    def _analyze_udp(self, packet: Any) -> None:
        """Analyze UDP packet.

        Args:
            packet: UDP packet
        """
        dport = packet[UDP].dport
        if dport == 53:
            self.protocols.add("DNS")
        elif dport == 67 or dport == 68:
            self.protocols.add("DHCP")

    def generate_report(
        self,
    ) -> Dict[str, Union[str, List[str], Dict[str, Any], Set[str]]]:
        """Generate network analysis report.

        Returns:
            Dictionary containing analysis results
        """
        report = {
            "timestamp": datetime.now().isoformat(),
            "interface": self.interface,
            "duration": (
                self.packets[-1].time - self.packets[0].time if self.packets else 0
            ),
            "total_packets": len(self.packets),
            "protocols": list(self.protocols),
            "connections": [],
            "findings": [],
        }

        # Analyze connections
        for conn_key, conn_data in self.connections.items():
            src, dst = conn_key.split(":")
            report["connections"].append(
                {
                    "source": src,
                    "destination": dst,
                    "packets": conn_data["packets"],
                    "bytes": conn_data["bytes"],
                    "duration": (
                        datetime.now() - conn_data["start_time"]
                    ).total_seconds(),
                    "protocols": list(conn_data["protocols"]),
                }
            )

        # Add security findings
        self._add_security_findings(report)

        return report

    def _add_security_findings(self, report: Dict[str, Any]) -> None:
        """Add security findings to report.

        Args:
            report: Report dictionary
        """
        # Check for plaintext protocols
        if "HTTP" in self.protocols:
            report["findings"].append(
                {
                    "type": "PLAINTEXT",
                    "severity": "HIGH",
                    "description": "Plaintext HTTP traffic detected",
                    "recommendation": "Use HTTPS for all web traffic",
                }
            )

        if "FTP" in self.protocols:
            report["findings"].append(
                {
                    "type": "PLAINTEXT",
                    "severity": "HIGH",
                    "description": "Plaintext FTP traffic detected",
                    "recommendation": "Use SFTP or FTPS instead",
                }
            )

        # Check for suspicious patterns
        for conn in report["connections"]:
            if conn["packets"] > 1000 and conn["duration"] < 10:
                report["findings"].append(
                    {
                        "type": "TRAFFIC",
                        "severity": "MEDIUM",
                        "description": f'High packet rate from {conn["source"]}',
                        "recommendation": "Investigate potential DoS activity",
                    }
                )

    def save_report(self, filename: str = "network_analysis_report.json") -> None:
        """Save analysis report to file.

        Args:
            filename: Output filename
        """
        report = self.generate_report()

        with open(filename, "w") as f:
            json.dump(report, f, indent=2)

        self.logger.info(f"Analysis report saved to {filename}")

        # Print summary
        print("\nNetwork Analysis Summary:")
        print(f"Total Packets: {report['total_packets']}")
        print(f"Protocols: {', '.join(report['protocols'])}")
        print(f"Connections: {len(report['connections'])}")
        print(f"Security Findings: {len(report['findings'])}")


def main() -> None:
    """Main function for testing."""
    import sys

    interface = sys.argv[1] if len(sys.argv) > 1 else None
    duration = int(sys.argv[2]) if len(sys.argv) > 2 else 60

    analyzer = NetworkAnalyzer(interface)

    print(f"Starting network analysis on {analyzer.interface}")
    print(f"Duration: {duration} seconds")
    print("Press Ctrl+C to stop")

    try:
        analyzer.start_capture(duration)
        analyzer.save_report()
    except KeyboardInterrupt:
        print("\nAnalysis stopped by user")
    except Exception as e:
        print(f"Error during analysis: {str(e)}")


if __name__ == "__main__":
    main()
