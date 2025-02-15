#!/bin/bash
# UnixPi Update Script
# Handles both online and offline updates

set -e

# Configuration
REPO_URL="https://github.com/Anon23261/UnixPi.git"
BACKUP_DIR="backup-$(date +%Y%m%d_%H%M%S)"
LOG_FILE="update.log"
OFFLINE_PACKAGE_PATTERN="unixpi-offline-*.tar.gz"

# Initialize logging
setup_logging() {
    exec 1> >(tee -a "$LOG_FILE")
    exec 2>&1
    echo "Starting update at $(date)"
}

# Create backup
create_backup() {
    echo "Creating backup..."
    mkdir -p "$BACKUP_DIR"
    cp -r * "$BACKUP_DIR/" 2>/dev/null || true
}

# Online update
online_update() {
    echo "Performing online update..."
    
    # Update repository
    if [ -d .git ]; then
        git fetch origin
        git checkout main
        git pull origin main
    else
        git clone "$REPO_URL" temp
        cp -r temp/* .
        rm -rf temp
    fi
    
    # Update dependencies
    ./scripts/install_dependencies.sh
}

# Offline update
offline_update() {
    echo "Performing offline update..."
    
    # Find latest offline package
    local latest_package=$(ls -t $OFFLINE_PACKAGE_PATTERN 2>/dev/null | head -1)
    
    if [ -n "$latest_package" ]; then
        echo "Using offline package: $latest_package"
        tar xzf "$latest_package"
        cd unixpi-offline
        ./install_offline.sh
    else
        echo "Error: No offline package found!"
        return 1
    fi
}

# Check for updates
check_updates() {
    echo "Checking for updates..."
    
    local current_version=$(cat VERSION)
    local latest_version
    
    if ping -c 1 github.com &> /dev/null; then
        # Online check
        latest_version=$(curl -s "https://raw.githubusercontent.com/Anon23261/UnixPi/main/VERSION")
    else
        # Offline check
        local latest_package=$(ls -t $OFFLINE_PACKAGE_PATTERN 2>/dev/null | head -1)
        if [ -n "$latest_package" ]; then
            latest_version=$(echo "$latest_package" | grep -oP 'unixpi-offline-\K[0-9]+\.[0-9]+\.[0-9]+(?=\.tar\.gz)')
        fi
    fi
    
    if [ -n "$latest_version" ] && [ "$latest_version" != "$current_version" ]; then
        echo "Update available: $current_version -> $latest_version"
        return 0
    else
        echo "Already at latest version: $current_version"
        return 1
    fi
}

# Verify installation
verify_installation() {
    echo "Verifying installation..."
    ./scripts/check_dependencies.py
}

# Main update sequence
main() {
    setup_logging
    create_backup
    
    if ! check_updates; then
        echo "No updates needed."
        return 0
    fi
    
    if ping -c 1 github.com &> /dev/null; then
        online_update
    else
        offline_update
    fi
    
    if verify_installation; then
        echo "Update completed successfully!"
        echo "A backup of your previous installation is available in: $BACKUP_DIR"
    else
        echo "Update completed with warnings. Check the log file for details."
        echo "You can restore from backup if needed: $BACKUP_DIR"
    fi
    
    return 0
}

# Execute main function
main "$@"
