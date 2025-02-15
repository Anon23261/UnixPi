#!/bin/bash
# UnixPi Firmware Update Script
# Updates Raspberry Pi firmware to latest version

set -e

FIRMWARE_REPO="https://github.com/Anon23261/firmware-raspi.git"
FIRMWARE_DIR="/opt/firmware"
BOOT_DIR="/boot/firmware"
BACKUP_DIR="/var/backups/firmware"
TEMP_DIR="/tmp/firmware-update"

# Create backup
create_backup() {
    echo "Creating backup..."
    sudo mkdir -p "$BACKUP_DIR"
    sudo tar czf "$BACKUP_DIR/firmware-$(date +%Y%m%d_%H%M%S).tar.gz" "$FIRMWARE_DIR" "$BOOT_DIR"
}

# Download latest firmware
download_latest() {
    echo "Downloading latest firmware..."
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
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

# Update firmware files
update_firmware() {
    echo "Updating firmware..."
    
    # Update boot files
    sudo cp -r "$TEMP_DIR"/boot/* "$BOOT_DIR/"
    
    # Update VideoCore files
    sudo cp -r "$TEMP_DIR"/hardfp/opt/vc/* "$FIRMWARE_DIR/"
    
    # Update library cache
    sudo ldconfig
}

# Verify firmware
verify_firmware() {
    echo "Verifying firmware..."
    
    # Check critical files
    for file in start.elf bootcode.bin fixup.dat; do
        if [ ! -f "$BOOT_DIR/$file" ]; then
            echo "Error: Missing critical file $file"
            return 1
        fi
    done
    
    # Check VideoCore binaries
    if [ ! -d "$FIRMWARE_DIR/bin" ] || [ ! -d "$FIRMWARE_DIR/lib" ]; then
        echo "Error: Missing VideoCore directories"
        return 1
    fi
    
    return 0
}

# Clean up
cleanup() {
    echo "Cleaning up..."
    rm -rf "$TEMP_DIR"
}

# Rollback on failure
rollback() {
    echo "Rolling back to previous version..."
    local latest_backup=$(ls -t "$BACKUP_DIR"/*.tar.gz | head -1)
    
    if [ -f "$latest_backup" ]; then
        sudo tar xzf "$latest_backup" -C /
        sudo ldconfig
        echo "Rollback completed successfully."
    else
        echo "Error: No backup found for rollback!"
        return 1
    fi
}

# Main update sequence
main() {
    echo "Starting firmware update..."
    
    create_backup
    
    if ! download_latest; then
        echo "Error: Failed to download firmware!"
        exit 1
    fi
    
    if ! update_firmware; then
        echo "Error: Failed to update firmware!"
        rollback
        exit 1
    fi
    
    if ! verify_firmware; then
        echo "Error: Firmware verification failed!"
        rollback
        exit 1
    fi
    
    cleanup
    echo "Firmware update completed successfully."
    return 0
}

# Execute main function
main "$@"
