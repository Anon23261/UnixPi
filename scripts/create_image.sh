#!/bin/bash
# UnixPi Image Creation Script
# Creates a bootable SD card image with security tools and firmware pre-installed

set -e

# Configuration
IMAGE_NAME="unixpi-security.img"
IMAGE_SIZE="8G"
MOUNT_POINT="/mnt/unixpi"
BOOT_SIZE="512M"
FIRMWARE_REPO="https://github.com/Anon23261/firmware-raspi.git"
TEMP_DIR="/tmp/firmware-temp"

echo "UnixPi Image Creation Script"
echo "==========================="

# Check for root privileges
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Create empty image
echo "Creating empty image..."
dd if=/dev/zero of=$IMAGE_NAME bs=1 count=0 seek=$IMAGE_SIZE

# Set up loop device
LOOP_DEV=$(losetup -f)
losetup $LOOP_DEV $IMAGE_NAME

# Create partitions
echo "Creating partitions..."
parted -s $LOOP_DEV mklabel msdos
parted -s $LOOP_DEV mkpart primary fat32 1MiB $BOOT_SIZE
parted -s $LOOP_DEV mkpart primary ext4 $BOOT_SIZE 100%

# Set up partition loop devices
BOOT_DEV=$(losetup -f)
ROOT_DEV=$(losetup -f)
losetup $BOOT_DEV $IMAGE_NAME -o 1MiB --sizelimit $BOOT_SIZE
losetup $ROOT_DEV $IMAGE_NAME -o $BOOT_SIZE

# Format partitions
echo "Formatting partitions..."
mkfs.vfat -F 32 $BOOT_DEV
mkfs.ext4 $ROOT_DEV

# Mount root partition
mkdir -p $MOUNT_POINT
mount $ROOT_DEV $MOUNT_POINT

# Mount boot partition
mkdir -p $MOUNT_POINT/boot
mount $BOOT_DEV $MOUNT_POINT/boot

# Install base system
echo "Installing base system..."
debootstrap --arch=armhf bullseye $MOUNT_POINT

# Install required packages
echo "Installing required packages..."
chroot $MOUNT_POINT apt-get update
chroot $MOUNT_POINT apt-get install -y \
    python3 \
    python3-pip \
    git \
    vim \
    network-manager \
    bluez \
    tor \
    nmap \
    tcpdump \
    wireshark \
    aircrack-ng \
    hashcat \
    john \
    metasploit-framework \
    postgresql \
    usbutils \
    build-essential \
    rkhunter \
    apparmor \
    apparmor-utils \
    cryptsetup \
    aide \
    auditd \
    fail2ban \
    iptables-persistent

# Install Python packages
echo "Installing Python packages..."
chroot $MOUNT_POINT pip3 install -r /UnixPi/requirements.txt

# Copy UnixPi files
echo "Copying UnixPi files..."
cp -r /media/ghost/1CEB-1733/MyOwnUnix/UnixPi $MOUNT_POINT/opt/
chroot $MOUNT_POINT pip3 install -e /opt/UnixPi

# Configure system
echo "Configuring system..."

# Set up network
cat > $MOUNT_POINT/etc/network/interfaces << EOF
auto lo
iface lo inet loopback

auto eth0
allow-hotplug eth0
iface eth0 inet dhcp

auto wlan0
allow-hotplug wlan0
iface wlan0 inet dhcp
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
EOF

# Configure Tor
cat > $MOUNT_POINT/etc/tor/torrc << EOF
SocksPort 9050
ControlPort 9051
HashedControlPassword 16:872860B76453A77D60CA2BB8C1A7042072093276A3D701AD684053EC4C
CookieAuthentication 1
EOF

# Set up boot configuration
cat > $MOUNT_POINT/boot/config.txt << EOF
# UnixPi Boot Configuration
gpu_mem=16
enable_uart=1
dtoverlay=dwc2
dtoverlay=uart1
dtoverlay=pi3-disable-bt
EOF

# Download and install firmware
echo "Setting up firmware..."
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
git init
git remote add origin "$FIRMWARE_REPO"
git config core.sparseCheckout true
echo "boot/*" > .git/info/sparse-checkout
echo "hardfp/opt/vc/bin/*" >> .git/info/sparse-checkout
echo "hardfp/opt/vc/lib/*" >> .git/info/sparse-checkout
echo "hardfp/opt/vc/sbin/*" >> .git/info/sparse-checkout
git pull --depth=1 origin master

# Copy firmware files
mkdir -p $MOUNT_POINT/boot/firmware
mkdir -p $MOUNT_POINT/opt/firmware
cp -r $TEMP_DIR/boot/* $MOUNT_POINT/boot/firmware/
cp -r $TEMP_DIR/hardfp/opt/vc/* $MOUNT_POINT/opt/firmware/

# Set up cmdline.txt
echo "console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait modules-load=dwc2,g_ether quiet splash" > $MOUNT_POINT/boot/cmdline.txt

# Create startup script
cat > $MOUNT_POINT/opt/UnixPi/start.sh << EOF
#!/bin/bash
# UnixPi Startup Script

# Initialize system
if [ ! -f /etc/unixpi/initialized ]; then
    # First boot setup
    echo "Performing first boot setup..."
    
    # Initialize firmware
    /opt/UnixPi/scripts/setup_firmware.sh
    
    # Initialize AIDE database
    aideinit
    
    # Enable AppArmor
    aa-enforce /etc/apparmor.d/*
    
    # Start services
    systemctl enable --now tor
    systemctl enable --now bluetooth
    systemctl enable --now postgresql
    systemctl enable --now auditd
    systemctl enable --now fail2ban
    
    # Mark as initialized
    mkdir -p /etc/unixpi
    touch /etc/unixpi/initialized
fi

# Start UnixPi services
systemctl start unixpi-monitor
systemctl start unixpi-security

# Initialize UnixPi
python3 /opt/UnixPi/init.py

# Start monitoring
python3 /opt/UnixPi/monitor.py &
EOF
chmod +x $MOUNT_POINT/opt/UnixPi/start.sh

# Set up auto-start
cat > $MOUNT_POINT/etc/rc.local << EOF
#!/bin/bash
/opt/UnixPi/start.sh &
exit 0
EOF
chmod +x $MOUNT_POINT/etc/rc.local

# Set up security
echo "Configuring security..."

# Create default user
useradd -m -s /bin/bash ghost
echo "ghost:ghost23!" | chpasswd
usermod -aG sudo,adm,dialout,cdrom,audio,video,plugdev,netdev ghost

# Secure SSH
cat > $MOUNT_POINT/etc/ssh/sshd_config << EOF
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
X11Forwarding no
AllowUsers ghost
Protocol 2
LoginGraceTime 30
MaxAuthTries 3
EOF

# Set hostname
echo "ghostsec" > $MOUNT_POINT/etc/hostname
sed -i "s/127.0.1.1.*/127.0.1.1\tghostsec/g" $MOUNT_POINT/etc/hosts

# Set up firewall
chroot $MOUNT_POINT apt-get install -y ufw
chroot $MOUNT_POINT ufw allow ssh
chroot $MOUNT_POINT ufw allow http
chroot $MOUNT_POINT ufw allow https
chroot $MOUNT_POINT ufw enable

# Clean up
echo "Cleaning up..."
rm -rf "$TEMP_DIR"
umount $MOUNT_POINT/boot
umount $MOUNT_POINT
losetup -d $BOOT_DEV
losetup -d $ROOT_DEV
losetup -d $LOOP_DEV

echo "Image creation complete!"
echo "Write the image to an SD card using:"
echo "dd if=$IMAGE_NAME of=/dev/sdX bs=4M status=progress"
