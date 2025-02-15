#!/bin/bash
# UnixPi Firmware Setup Script
# Downloads and integrates Raspberry Pi firmware

set -e

FIRMWARE_REPO="https://github.com/Anon23261/firmware-raspi.git"
FIRMWARE_DIR="/opt/firmware"
BOOT_DIR="/boot/firmware"
TEMP_DIR="/tmp/firmware-temp"

# Create necessary directories
create_dirs() {
    echo "Creating directories..."
    sudo mkdir -p "$FIRMWARE_DIR"
    sudo mkdir -p "$BOOT_DIR"
    mkdir -p "$TEMP_DIR"
}

# Download firmware
download_firmware() {
    echo "Downloading firmware..."
    cd "$TEMP_DIR"
    
    # Clone specific files instead of entire repository
    git init
    git remote add origin "$FIRMWARE_REPO"
    
    # Only download essential files
    git config core.sparseCheckout true
    cat > .git/info/sparse-checkout << EOF
boot/*
hardfp/opt/vc/bin/*
hardfp/opt/vc/lib/*
hardfp/opt/vc/sbin/*
EOF
    
    git pull --depth=1 origin master
}

# Install firmware files
install_firmware() {
    echo "Installing firmware..."
    
    # Copy boot files
    sudo cp -r "$TEMP_DIR"/boot/* "$BOOT_DIR/"
    
    # Copy VideoCore files
    sudo cp -r "$TEMP_DIR"/hardfp/opt/vc/* "$FIRMWARE_DIR/"
    
    # Set up symlinks
    sudo ln -sf "$FIRMWARE_DIR/bin/"* /usr/local/bin/
    sudo ln -sf "$FIRMWARE_DIR/lib/"* /usr/local/lib/
    
    # Update library cache
    sudo ldconfig
}

# Configure firmware
configure_firmware() {
    echo "Configuring firmware..."
    
    # Update boot config
    sudo tee -a /boot/config.txt > /dev/null << EOF
# Firmware configuration
gpu_mem=128
enable_uart=1
dtparam=audio=on
dtparam=i2c_arm=on
dtparam=spi=on
EOF
    
    # Update environment
    sudo tee /etc/profile.d/firmware.sh > /dev/null << EOF
export PATH="\$PATH:$FIRMWARE_DIR/bin"
export LD_LIBRARY_PATH="\$LD_LIBRARY_PATH:$FIRMWARE_DIR/lib"
EOF
}

# Clean up temporary files
cleanup() {
    echo "Cleaning up..."
    rm -rf "$TEMP_DIR"
}

# Main installation sequence
main() {
    echo "Starting firmware setup..."
    
    create_dirs
    download_firmware
    install_firmware
    configure_firmware
    cleanup
    
    echo "Firmware setup completed successfully."
    return 0
}

# Execute main function
main "$@"
