#!/bin/bash

echo "Script for Assignment2"

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root!" >&2
    exit 1
fi

# Function to update network configuration
configure_network() {
    local NETPLAN_FILE="/etc/netplan/50-cloud-init.yaml"
    local NEW_CONFIG="network:
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.16.21/24
  version: 2"

    if ! grep -q "192.168.16.21" "$NETPLAN_FILE"; then
        echo "$NEW_CONFIG" > "$NETPLAN_FILE"
        netplan apply
        echo "Network configuration updated."
    else
        echo "Network already configured."
    fi
}

# Function to update /etc/hosts
update_hosts() {
    if ! grep -q "192.168.16.21 server1" /etc/hosts; then
        sed -i '/server1/d' /etc/hosts
        echo "192.168.16.21 server1" >> /etc/hosts
        echo "/etc/hosts updated."
    else
        echo "/etc/hosts already configured."
    fi
}

# Function to install required packages
install_packages() {
    apt update
    for pkg in apache2 squid; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            apt install -y $pkg
            systemctl enable --now $pkg
            echo "$pkg installed and running."
        else
            echo "$pkg is already installed."
        fi
    done
}

# Function to create user accounts
create_users() {
    local USERS=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

    for user in "${USERS[@]}"; do
        if ! id "$user" &>/dev/null; then
            useradd -m -s /bin/bash "$user"
            mkdir -p /home/$user/.ssh
            chmod 700 /home/$user/.ssh
            ssh-keygen -q -t rsa -b 2048 -f /home/$user/.ssh/id_rsa -N ""
            ssh-keygen -q -t ed25519 -f /home/$user/.ssh/id_ed25519 -N ""
            cat /home/$user/.ssh/id_rsa.pub >> /home/$user/.ssh/authorized_keys
            cat /home/$user/.ssh/id_ed25519.pub >> /home/$user/.ssh/authorized_keys
            chmod 600 /home/$user/.ssh/authorized_keys
            chown -R $user:$user /home/$user/.ssh
            echo "User $user created with SSH keys."
        else
            echo "User $user already exists."
        fi
    done
}

# Function to configure sudo access for a user
configure_sudo_access() {
    if id "dennis" &>/dev/null; then
        usermod -aG sudo dennis
        echo "dennis added to sudo group."
    fi
}

# Start of script execution
configure_network
update_hosts
install_packages
create_users
configure_sudo_access

echo "Assignment2 scripte setup completed"
