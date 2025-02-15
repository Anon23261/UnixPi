#!/bin/bash
# UnixPi Secure Initialization Script
# Implements advanced security measures and system hardening

set -e

# Security constants
SECURE_UMASK=027
SECURE_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
AIDE_DB="/var/lib/aide/aide.db"
AUDIT_RULES="/etc/audit/rules.d/audit.rules"

# Initialize system security
init_security() {
    echo "Initializing system security..."
    
    # Set secure umask
    umask $SECURE_UMASK
    
    # Set secure PATH
    export PATH=$SECURE_PATH
    
    # Disable core dumps
    echo "* hard core 0" > /etc/security/limits.d/10-security.conf
    
    # Set up secure tmp directories
    mount -o remount,noexec,nosuid,nodev /tmp
    mount -o remount,noexec,nosuid,nodev /var/tmp
    
    return 0
}

# Configure AppArmor
setup_apparmor() {
    echo "Configuring AppArmor..."
    
    # Enable AppArmor
    aa-enforce /etc/apparmor.d/*
    
    # Load security profiles
    for profile in /etc/apparmor.d/unixpi.*; do
        apparmor_parser -r $profile
    done
    
    return 0
}

# Set up audit system
configure_audit() {
    echo "Configuring audit system..."
    
    # Configure audit rules
    cat > $AUDIT_RULES << EOF
# First rule - delete all
-D

# Increase the buffers to survive stress events
-b 8192

# Monitor for stack-based buffer overflows
-a always,exit -F arch=b64 -S execve -F euid=0 -k rootcmd

# Monitor security-sensitive files
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/group -p wa -k group_changes
-w /etc/sudoers -p wa -k sudoers_changes

# Monitor command execution
-a exit,always -F arch=b64 -S execve -k exec

# Monitor security operations
-w /usr/bin/sudo -p x -k sudo_usage
-w /bin/su -p x -k su_usage

# Monitor network configuration
-w /etc/sysctl.conf -p wa -k sysctl_changes
-w /etc/network/ -p wa -k network_changes

# Monitor UnixPi specific files
-w /opt/UnixPi/ -p wa -k unixpi_changes
-w /etc/tor/torrc -p wa -k tor_config

# Monitor for time changes
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -S clock_settime -k time_change

# Monitor mount operations
-a always,exit -F arch=b64 -S mount -S umount2 -k mount

# Monitor scheduled tasks
-w /etc/crontab -p wa -k crontab_changes
-w /etc/cron.d/ -p wa -k crontab_dir_changes

# Monitor user and group management
-w /usr/sbin/useradd -p x -k user_creation
-w /usr/sbin/usermod -p x -k user_modification
-w /usr/sbin/groupadd -p x -k group_creation
-w /usr/sbin/groupmod -p x -k group_modification

# Monitor kernel module operations
-w /sbin/insmod -p x -k module_insertion
-w /sbin/rmmod -p x -k module_removal
-w /sbin/modprobe -p x -k module_insertion

# Monitor SSH operations
-w /etc/ssh/sshd_config -p wa -k sshd_config
-w /root/.ssh -p wa -k root_ssh
EOF
    
    # Reload audit rules
    auditctl -R $AUDIT_RULES
    
    return 0
}

# Set up AIDE
configure_aide() {
    echo "Configuring AIDE..."
    
    # Initialize AIDE database
    aide --init
    
    # Move new database to active location
    mv /var/lib/aide/aide.db.new $AIDE_DB
    
    # Schedule daily integrity checks
    cat > /etc/cron.daily/aide-check << EOF
#!/bin/bash
aide --check | mail -s "AIDE Integrity Check Report" root
EOF
    chmod +x /etc/cron.daily/aide-check
    
    return 0
}

# Configure secure networking
setup_secure_network() {
    echo "Configuring secure networking..."
    
    # Configure iptables with strict rules
    iptables -F
    iptables -X
    iptables -Z
    
    # Set default policies
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT DROP
    
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Allow Tor
    iptables -A OUTPUT -p tcp --dport 9050 -j ACCEPT
    
    # Allow DNS (through Tor only)
    iptables -A OUTPUT -p udp --dport 53 -m owner --uid-owner debian-tor -j ACCEPT
    
    # Save rules
    iptables-save > /etc/iptables/rules.v4
    
    return 0
}

# Configure secure storage
setup_secure_storage() {
    echo "Configuring secure storage..."
    
    # Enable disk encryption if not already enabled
    if ! grep -q "dm-crypt" /proc/crypto; then
        modprobe dm-crypt
    fi
    
    # Set up encrypted swap
    if grep -q "swap" /etc/fstab; then
        swapoff -a
        dd if=/dev/urandom of=/dev/mmcblk0p3 bs=1M
        mkswap /dev/mmcblk0p3
        swapon -e /dev/mmcblk0p3
    fi
    
    return 0
}

# Set up secure logging
configure_logging() {
    echo "Configuring secure logging..."
    
    # Configure rsyslog for secure logging
    cat > /etc/rsyslog.d/99-secure.conf << EOF
# Log auth messages to secure location
auth,authpriv.* /var/log/secure
# Log all critical messages
*.crit /var/log/critical
# Enable TCP syslog reception
\$ModLoad imtcp
\$InputTCPServerRun 514
EOF
    
    # Restart rsyslog
    systemctl restart rsyslog
    
    return 0
}

# Main initialization sequence
main() {
    echo "Starting UnixPi secure initialization..."
    
    # Initialize basic security
    if ! init_security; then
        echo "Basic security initialization failed!"
        exit 1
    fi
    
    # Set up AppArmor
    if ! setup_apparmor; then
        echo "AppArmor setup failed!"
        exit 1
    fi
    
    # Configure audit system
    if ! configure_audit; then
        echo "Audit system configuration failed!"
        exit 1
    fi
    
    # Set up AIDE
    if ! configure_aide; then
        echo "AIDE configuration failed!"
        exit 1
    fi
    
    # Configure secure networking
    if ! setup_secure_network; then
        echo "Secure network configuration failed!"
        exit 1
    fi
    
    # Set up secure storage
    if ! setup_secure_storage; then
        echo "Secure storage configuration failed!"
        exit 1
    fi
    
    # Configure logging
    if ! configure_logging; then
        echo "Secure logging configuration failed!"
        exit 1
    fi
    
    echo "Secure initialization completed successfully."
    return 0
}

# Execute main function
main "$@"
