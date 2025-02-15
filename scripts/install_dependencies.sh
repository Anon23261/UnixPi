#!/bin/bash
# UnixPi Dependency Installation Script
# Installs all required system and Python dependencies

set -e

# Configuration
PYTHON_VERSION="3.9"
LOG_FILE="install.log"

# System dependencies
SYSTEM_DEPS=(
    python3-dev
    python3-pip
    python3-venv
    build-essential
    libssl-dev
    libffi-dev
    libpcap-dev
    libbluetooth-dev
    libhidapi-dev
    libusb-1.0-0-dev
    pkg-config
    git
    bluetooth
    bluez
    bluez-tools
)

# Initialize logging
setup_logging() {
    exec 1> >(tee -a "$LOG_FILE")
    exec 2>&1
    echo "Starting installation at $(date)"
}

# Install system dependencies
install_system_deps() {
    echo "Installing system dependencies..."
    
    sudo apt-get update
    sudo apt-get install -y "${SYSTEM_DEPS[@]}"
    
    # Enable and start bluetooth service
    sudo systemctl enable bluetooth
    sudo systemctl start bluetooth
}

# Install Python dependencies
install_python_deps() {
    echo "Installing Python dependencies..."
    
    # Upgrade pip
    python3 -m pip install --upgrade pip setuptools wheel
    
    # Install build dependencies first
    pip3 install --upgrade build wheel setuptools
    
    # Install from requirements files
    pip3 install -r requirements.txt
    
    if [ -f requirements-dev.txt ]; then
        pip3 install -r requirements-dev.txt
    fi
}

# Verify installation
verify_installation() {
    echo "Verifying installation..."
    
    # Check Python packages
    python3 scripts/check_dependencies.py
    
    # Check bluetooth
    if ! systemctl is-active --quiet bluetooth; then
        echo "Warning: Bluetooth service is not running"
        return 1
    fi
    
    # Test bluetooth functionality
    if ! hciconfig | grep -q "UP RUNNING"; then
        echo "Warning: No Bluetooth adapter is up and running"
        return 1
    fi
    
    return 0
}

# Main installation sequence
main() {
    echo "Starting UnixPi dependency installation..."
    
    setup_logging
    install_system_deps
    install_python_deps
    
    if verify_installation; then
        echo "Installation completed successfully!"
    else
        echo "Installation completed with warnings. Check the log file for details."
    fi
    
    return 0
}

# Execute main function
main "$@"
