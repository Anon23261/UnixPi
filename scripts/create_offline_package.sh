#!/bin/bash
# UnixPi Offline Package Creator
# Creates a self-contained offline installation package

set -e

# Configuration
PACKAGE_NAME="unixpi-offline"
VERSION=$(cat ../VERSION)
PACKAGE_FILE="${PACKAGE_NAME}-${VERSION}.tar.gz"
TEMP_DIR="/tmp/unixpi-offline"
WHEELS_DIR="wheels"
DEB_DIR="debs"
LOG_FILE="offline_package.log"

# Initialize logging
setup_logging() {
    exec 1> >(tee -a "$LOG_FILE")
    exec 2>&1
    echo "Starting offline package creation at $(date)"
}

# Create directory structure
create_dirs() {
    echo "Creating directory structure..."
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"/{$WHEELS_DIR,$DEB_DIR}
}

# Download Python wheels
download_wheels() {
    echo "Downloading Python wheels..."
    cd "$TEMP_DIR"
    
    # Create requirements file without git dependencies
    grep -v "git+" ../requirements.txt > requirements_offline.txt
    
    # Download wheels
    pip3 download -r requirements_offline.txt -d "$WHEELS_DIR"
    if [ -f ../requirements-dev.txt ]; then
        pip3 download -r ../requirements-dev.txt -d "$WHEELS_DIR"
    fi
}

# Download system packages
download_debs() {
    echo "Downloading system packages..."
    cd "$TEMP_DIR"
    
    # List of required packages
    PACKAGES=(
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
    
    # Download packages and dependencies
    apt-get download ${PACKAGES[@]}
    for pkg in ${PACKAGES[@]}; do
        apt-cache depends --recurse --no-recommends --no-suggests \
            --no-conflicts --no-breaks --no-replaces --no-enhances \
            --no-pre-depends "$pkg" | grep "^\w" | sort -u | \
            xargs apt-get download
    done
    
    mv *.deb "$DEB_DIR/"
}

# Create installation script
create_install_script() {
    echo "Creating installation script..."
    cat > "$TEMP_DIR/install_offline.sh" << 'EOF'
#!/bin/bash
set -e

# Configuration
WHEELS_DIR="wheels"
DEB_DIR="debs"
LOG_FILE="offline_install.log"

# Initialize logging
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1
echo "Starting offline installation at $(date)"

# Install system packages
echo "Installing system packages..."
cd "$DEB_DIR"
sudo dpkg -i *.deb || true
sudo apt-get install -f -y

# Install Python packages
echo "Installing Python packages..."
cd "../$WHEELS_DIR"
pip3 install --no-index --find-links=. -r ../../requirements.txt
if [ -f ../../requirements-dev.txt ]; then
    pip3 install --no-index --find-links=. -r ../../requirements-dev.txt
fi

echo "Offline installation completed!"
EOF
    
    chmod +x "$TEMP_DIR/install_offline.sh"
}

# Create update script
create_update_script() {
    echo "Creating update script..."
    cat > "$TEMP_DIR/update_offline.sh" << 'EOF'
#!/bin/bash
set -e

# Configuration
REPO_URL="https://github.com/Anon23261/UnixPi.git"
BACKUP_DIR="backup-$(date +%Y%m%d_%H%M%S)"
LOG_FILE="update.log"

# Initialize logging
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1
echo "Starting update at $(date)"

# Create backup
echo "Creating backup..."
mkdir -p "$BACKUP_DIR"
cp -r * "$BACKUP_DIR/" 2>/dev/null || true

# Try online update first
if ping -c 1 github.com &> /dev/null; then
    echo "Internet connection available, attempting online update..."
    
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
else
    echo "No internet connection, using offline package..."
    
    # Install from offline package
    if [ -f "unixpi-offline-"*".tar.gz" ]; then
        latest_package=$(ls -t unixpi-offline-*.tar.gz | head -1)
        tar xzf "$latest_package"
        cd unixpi-offline
        ./install_offline.sh
    else
        echo "Error: No offline package found!"
        exit 1
    fi
fi

echo "Update completed successfully!"
EOF
    
    chmod +x "$TEMP_DIR/update_offline.sh"
}

# Create package
create_package() {
    echo "Creating offline package..."
    cd "$TEMP_DIR"
    
    # Copy project files
    cp -r ../../* ./ 2>/dev/null || true
    
    # Create archive
    cd ..
    tar czf "$PACKAGE_FILE" "$(basename "$TEMP_DIR")"
    mv "$PACKAGE_FILE" ../
    
    echo "Package created: $PACKAGE_FILE"
}

# Clean up
cleanup() {
    echo "Cleaning up..."
    rm -rf "$TEMP_DIR"
}

# Main sequence
main() {
    echo "Starting offline package creation..."
    
    setup_logging
    create_dirs
    download_wheels
    download_debs
    create_install_script
    create_update_script
    create_package
    cleanup
    
    echo "Offline package creation completed successfully!"
    return 0
}

# Execute main function
main "$@"
