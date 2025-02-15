# UnixPi - Professional IoT Security Framework

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/Anon23261/UnixPi/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Python](https://img.shields.io/badge/python-3.8%2B-blue.svg)](https://www.python.org/downloads/)

UnixPi is a professional IoT security assessment framework designed for security researchers and penetration testers. It provides a comprehensive suite of tools for analyzing and testing IoT device security.

## 🔒 Security Features

### Bluetooth Security Analysis
- Real-time device discovery and monitoring
- Signal strength analysis and tracking
- Device fingerprinting and profiling
- Connection pattern analysis
- Detailed security reporting

### Network Security Assessment
- Advanced port scanning and service detection
- Version-based vulnerability analysis
- Default credential checking
- Protocol compliance testing
- Network service enumeration

### IoT Vulnerability Scanner
- Firmware version analysis
- Known vulnerability detection
- Security misconfiguration checks
- Detailed vulnerability reporting
- Remediation recommendations

## 📋 Requirements

### System Dependencies
```bash
# Install system packages
sudo apt-get update
sudo apt-get install -y \
    python3-dev \
    python3-pip \
    python3-venv \
    build-essential \
    libssl-dev \
    libffi-dev \
    libpcap-dev \
    libbluetooth-dev \
    libhidapi-dev \
    libusb-1.0-0-dev \
    pkg-config \
    git \
    bluetooth \
    bluez \
    bluez-tools
```

### Python Dependencies
```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

## 🚀 Quick Start

1. Clone the repository:
```bash
git clone https://github.com/Anon23261/UnixPi.git
cd UnixPi
```

2. Set up the environment:
```bash
./scripts/setup_environment.sh
```

3. Start security assessment:
```bash
# Bluetooth security monitoring
python3 -m unixpi.security.bluetooth_monitor

# Port scanning
python3 -m unixpi.security.port_scanner <target>

# Vulnerability scanning
python3 -m unixpi.security.vuln_scanner <target>
```

## 📊 Security Reports

UnixPi generates detailed security reports in JSON format:

- `bluetooth_security_report.json`: Bluetooth device analysis
- `port_scan_report.json`: Network service assessment
- `vulnerability_report.json`: Identified security issues

## 🔄 Updates

### Online Update
```bash
./scripts/update.sh
```

### Offline Update
```bash
# Create offline package
./scripts/create_offline_package.sh

# Install from package
tar xzf unixpi-offline-*.tar.gz
cd unixpi-offline
./install_offline.sh
```

## 🛡️ Responsible Usage

This framework is designed for legitimate security testing only. Always:
1. Obtain proper authorization before testing
2. Follow responsible disclosure practices
3. Respect privacy and data protection laws
4. Document all testing activities
5. Report vulnerabilities responsibly

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) first.

## 📬 Support

- Report bugs: [Issue Tracker](https://github.com/Anon23261/UnixPi/issues)
- Ask questions: [Discussions](https://github.com/Anon23261/UnixPi/discussions)
- Documentation: [Wiki](https://github.com/Anon23261/UnixPi/wiki)

## ⚠️ Disclaimer

This software is provided for educational and research purposes only. Users are responsible for ensuring all testing activities comply with applicable laws and regulations. Security Framework

![Build Status](https://github.com/Anon23261/UnixPi/workflows/CI/badge.svg)
![Security Status](https://github.com/Anon23261/UnixPi/workflows/Security/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

A comprehensive IoT and network security framework for Raspberry Pi Zero W, focusing on penetration testing, security analysis, and system hardening.

## Features

### IoT Security
- Multi-protocol device discovery
- Vulnerability scanning
- Protocol analysis
- Firmware analysis
- Security assessment

### Network Security
- Port scanning
- Traffic analysis
- Packet capture
- Network monitoring
- Intrusion detection

### System Security
- Secure boot process
- Kernel hardening
- AppArmor profiles
- Integrity monitoring
- Audit logging

### Anonymity
- Tor integration
- IP masking
- Traffic routing
- Circuit management
- Security kill switch

## Quick Start

### Installation

1. Download the latest release:
```bash
git clone https://github.com/Anon23261/UnixPi.git
cd UnixPi
```

2. Create SD card image:
```bash
sudo ./scripts/create_image.sh
```

3. Write to SD card:
```bash
sudo ./scripts/write_to_sd.sh /dev/sdX  # Replace X with your SD card device
```

The image includes:
- Pre-installed Raspberry Pi firmware
- Auto-configuration on first boot
- Default user setup (username: ghost, password: ghost23!)
- Security hardening and monitoring
- Full IoT security toolkit

### First Boot

1. Insert SD card into Raspberry Pi Zero W and power on
2. Wait for initial setup to complete
3. Login with default credentials:
   - Username: ghost
   - Password: ghost23!

### Basic Usage

```bash
# Run security scan
secure-scan

# Start monitoring
secure-monitor

# Create backup
secure-backup

# Check system status
secure-status
```

## Development

### Setup Development Environment

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Run tests
pytest tests/
```

### Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Security

### Reporting Security Issues

Please report security issues by opening a GitHub Security Advisory on the UnixPi repository.

### Security Features

- Secure boot process
- Encrypted storage
- Network isolation
- Process containment
- Audit logging

## Documentation

Detailed documentation is available in the [docs](docs/) directory:
- [Installation Guide](docs/installation.md)
- [Security Guide](docs/security.md)
- [Development Guide](docs/development.md)
- [API Reference](docs/api.md)

## Testing

Run the test suite:
```bash
# Run all tests
pytest

# Run specific test
pytest tests/test_security.py

# Run with coverage
pytest --cov=UnixPi
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Raspberry Pi Foundation
- The Tor Project
- Python Security Community
- Open Source Security Tools

## Support

For support:
- GitHub Issues: https://github.com/Anon23261/UnixPi/issues
- Documentation Wiki: https://github.com/Anon23261/UnixPi/wiki
- Discussions: https://github.com/Anon23261/UnixPi/discussions

## Roadmap

- [ ] Additional protocol support
- [ ] Enhanced firmware analysis
- [ ] Machine learning integration
- [ ] Automated penetration testing
- [ ] Cloud integration

## Authors

- **GhostSec Team** - *Initial work*

## Disclaimer

This tool is for educational and research purposes only. Users are responsible for complying with applicable laws and regulations.
