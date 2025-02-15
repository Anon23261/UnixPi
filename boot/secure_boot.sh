#!/bin/bash
# UnixPi Secure Boot Configuration
# Implements secure boot process and system hardening

set -e

# Security verification
verify_system_integrity() {
    echo "Verifying system integrity..."
    
    # Check kernel integrity
    if ! sha256sum -c /boot/kernel.sha256; then
        echo "ERROR: Kernel integrity check failed!"
        return 1
    fi
    
    # Verify boot partition
    if ! verity_check /dev/mmcblk0p1 /boot/verity.sig; then
        echo "ERROR: Boot partition integrity check failed!"
        return 1
    }
    
    # Check for rootkit presence
    if ! rkhunter --check --skip-keypress; then
        echo "WARNING: Potential rootkit detected!"
        return 1
    }
    
    return 0
}

# Secure boot sequence
secure_boot() {
    echo "Initializing secure boot sequence..."
    
    # Mount filesystems with security options
    mount -o remount,ro /boot
    mount -o remount,nosuid,nodev,noexec /tmp
    mount -o remount,nosuid,nodev /var/tmp
    
    # Enable kernel security features
    echo 1 > /proc/sys/kernel/kptr_restrict
    echo 2 > /proc/sys/kernel/dmesg_restrict
    echo 1 > /proc/sys/net/ipv4/tcp_syncookies
    
    # Load security modules
    modprobe -r bluetooth # Disable by default
    modprobe -r usb-storage # Disable USB storage by default
    
    return 0
}

# Network security setup
secure_network() {
    echo "Configuring network security..."
    
    # Enable firewall with strict rules
    ufw reset
    ufw default deny incoming
    ufw default deny outgoing
    
    # Allow only essential services
    ufw allow out 53/udp # DNS
    ufw allow out 80/tcp # HTTP
    ufw allow out 443/tcp # HTTPS
    ufw allow out 9050/tcp # Tor
    
    # Enable firewall
    ufw enable
    
    # Configure fail2ban
    systemctl start fail2ban
    
    return 0
}

# System hardening
harden_system() {
    echo "Applying system hardening..."
    
    # Secure shared memory
    mount -o remount,nosuid,nodev,noexec /dev/shm
    
    # Disable core dumps
    echo "* hard core 0" >> /etc/security/limits.conf
    
    # Secure sysctl parameters
    cat > /etc/sysctl.d/99-security.conf << EOF
# Kernel hardening
kernel.randomize_va_space = 2
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.printk = 3 4 1 3
kernel.unprivileged_bpf_disabled = 1
kernel.core_uses_pid = 1
kernel.sysrq = 0
kernel.core_pattern = |/bin/false

# Network security
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rfc1337 = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_echo_ignore_all = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# File system security
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.suid_dumpable = 0
EOF
    
    # Apply sysctl settings
    sysctl -p /etc/sysctl.d/99-security.conf
    
    # Secure SSH configuration
    cat > /etc/ssh/sshd_config << EOF
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 0
UsePAM yes
AllowUsers unixpi
EOF
    
    # Set secure permissions
    chmod 700 /root
    chmod 600 /etc/ssh/*_key
    chmod 644 /etc/ssh/*.pub
    
    return 0
}

# Initialize security services
init_security_services() {
    echo "Initializing security services..."
    
    # Start security monitoring
    systemctl start auditd
    systemctl start aide
    systemctl start fail2ban
    
    # Start Tor with secure configuration
    systemctl start tor
    
    # Enable process accounting
    systemctl start psacct
    
    return 0
}

# Main boot sequence
main() {
    echo "Starting UnixPi secure boot sequence..."
    
    # Verify system integrity
    if ! verify_system_integrity; then
        echo "System integrity check failed! Entering recovery mode..."
        /sbin/sulogin
        exit 1
    fi
    
    # Perform secure boot
    if ! secure_boot; then
        echo "Secure boot failed! Entering recovery mode..."
        /sbin/sulogin
        exit 1
    fi
    
    # Configure network security
    if ! secure_network; then
        echo "Network security configuration failed!"
        exit 1
    fi
    
    # Apply system hardening
    if ! harden_system; then
        echo "System hardening failed!"
        exit 1
    fi
    
    # Initialize security services
    if ! init_security_services; then
        echo "Security services initialization failed!"
        exit 1
    fi
    
    echo "Secure boot sequence completed successfully."
    return 0
}

# Execute main function
main "$@"
