#!/bin/bash
# UnixPi System Configuration Script
# Sets up user account and system configuration

set -e

# Configuration
USERNAME="ghost"
PASSWORD="ghost23!"
HOSTNAME="ghostsec"

# Configure system
configure_system() {
    echo "Configuring system..."
    
    # Set hostname
    echo $HOSTNAME > /etc/hostname
    sed -i "s/127.0.1.1.*/127.0.1.1\t$HOSTNAME/g" /etc/hosts
    
    # Set timezone
    timedatectl set-timezone UTC
    
    # Configure locale
    locale-gen en_US.UTF-8
    update-locale LANG=en_US.UTF-8
    
    return 0
}

# Create user account
create_user() {
    echo "Creating user account..."
    
    # Create user with secure shell
    useradd -m -s /bin/bash $USERNAME
    
    # Set password
    echo "$USERNAME:$PASSWORD" | chpasswd
    
    # Add to necessary groups
    usermod -aG sudo,adm,dialout,cdrom,audio,video,plugdev,netdev $USERNAME
    
    # Create SSH directory
    mkdir -p /home/$USERNAME/.ssh
    chmod 700 /home/$USERNAME/.ssh
    chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
    
    # Generate SSH key
    sudo -u $USERNAME ssh-keygen -t ed25519 -f /home/$USERNAME/.ssh/id_ed25519 -N ""
    
    return 0
}

# Configure user environment
configure_user() {
    echo "Configuring user environment..."
    
    # Create user config directory
    mkdir -p /home/$USERNAME/.config
    
    # Set up bash configuration
    cat > /home/$USERNAME/.bashrc << EOF
# UnixPi Security Framework
export PATH="/opt/UnixPi/bin:$PATH"
export PYTHONPATH="/opt/UnixPi:$PYTHONPATH"

# Security aliases
alias secure-update='sudo apt-get update && sudo apt-get upgrade'
alias secure-scan='sudo python3 /opt/UnixPi/security/scan.py'
alias secure-monitor='sudo python3 /opt/UnixPi/security/monitor.py'
alias secure-backup='sudo /opt/UnixPi/boot/recovery.sh backup'

# System aliases
alias ls='ls --color=auto'
alias ll='ls -la'
alias grep='grep --color=auto'

# Security prompt
PS1='\[\033[1;31m\][\[\033[1;33m\]\u@\h\[\033[1;31m\]]\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\]\$ '

# Security environment
export HISTCONTROL=ignoreboth
export HISTSIZE=1000
export HISTFILESIZE=2000
export EDITOR=vim
EOF
    
    # Set up vim configuration
    cat > /home/$USERNAME/.vimrc << EOF
set nocompatible
set secure
set modelines=0
set nomodeline
syntax on
set number
set ruler
set encoding=utf-8
EOF
    
    # Set ownership
    chown -R $USERNAME:$USERNAME /home/$USERNAME
    
    return 0
}

# Configure security settings
configure_security() {
    echo "Configuring security settings..."
    
    # Set up sudo configuration
    cat > /etc/sudoers.d/99-unixpi << EOF
# UnixPi sudo configuration
$USERNAME ALL=(ALL) ALL
Defaults:$USERNAME timestamp_timeout=15
Defaults:$USERNAME !tty_tickets
Defaults:$USERNAME passwd_tries=3
Defaults:$USERNAME passwd_timeout=1
EOF
    chmod 440 /etc/sudoers.d/99-unixpi
    
    # Set secure permissions
    chmod 700 /home/$USERNAME
    chmod 600 /home/$USERNAME/.bash_history
    
    return 0
}

# Main configuration sequence
main() {
    echo "Starting UnixPi system configuration..."
    
    # Configure system
    if ! configure_system; then
        echo "System configuration failed!"
        exit 1
    fi
    
    # Create user
    if ! create_user; then
        echo "User creation failed!"
        exit 1
    fi
    
    # Configure user environment
    if ! configure_user; then
        echo "User environment configuration failed!"
        exit 1
    fi
    
    # Configure security
    if ! configure_security; then
        echo "Security configuration failed!"
        exit 1
    fi
    
    echo "System configuration completed successfully."
    return 0
}

# Execute main function
main "$@"
