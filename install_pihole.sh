#!/bin/bash
# Pi-hole Automated Deployment Script (Ethernet, Static IP)
# Public-ready: Users provide their own IPs and credentials

set -e

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

read -p "Enter your Ethernet interface name (e.g., eth0): " ETH_INTERFACE
read -p "Enter the static IP you want to assign (e.g., 192.168.X.X/24): " STATIC_IP
read -p "Enter your router gateway IP (e.g., 192.168.X.1): " GATEWAY
read -p "Enter the admin password for Pi-hole web interface: " ADMIN_PASSWORD
echo "Choose upstream DNS providers (comma-separated, e.g., 1.1.1.1,9.9.9.9): "
read UPSTREAM_DNS

echo "Configuring static IP for $ETH_INTERFACE..."
sudo cp /etc/dhcpcd.conf /etc/dhcpcd.conf.bak
echo -e "\ninterface $ETH_INTERFACE\nstatic ip_address=$STATIC_IP\nstatic routers=$GATEWAY\nstatic domain_name_servers=127.0.0.1" | sudo tee -a /etc/dhcpcd.conf

if ! systemctl is-active --quiet dhcpcd; then
    echo "dhcpcd not found, installing..."
    sudo apt install -y dhcpcd5
    sudo systemctl enable dhcpcd
fi
sudo systemctl restart dhcpcd
hostname -I

echo "Installing Pi-hole..."
curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended \
    --interface "$ETH_INTERFACE" \
    --static-ip "$STATIC_IP" \
    --upstream-dns "$(echo $UPSTREAM_DNS | tr ',' ';')" \
    --admin-password "$ADMIN_PASSWORD"

echo "Verifying Pi-hole installation..."
pihole status
echo "Pi-hole installation complete!"
echo "Web admin interface: http://$STATIC_IP/admin"
echo "Admin password: $ADMIN_PASSWORD"

