#!/bin/bash

echo "Installing VMware Tools integration..."

# Ensure internet access
if ! ping -c 1 ftp.uk.debian.org > /dev/null 2>&1; then
    echo "Network required to install open-vm-tools packages."
    exit 1
fi

# Update apt and install required packages
sudo apt update
sudo apt install -y open-vm-tools open-vm-tools-desktop

echo "Starting vmtools user session..."
/usr/bin/vmware-user &

echo "VMware integration enabled: clipboard, resolution, drag & drop"
