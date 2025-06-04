#!/bin/bash

# Ensure /etc/resolv.conf points to systemd-resolved stub
if [ "$(readlink /etc/resolv.conf)" != "/run/systemd/resolve/stub-resolv.conf" ]; then
    echo "[+] Updating /etc/resolv.conf to point to systemd-resolved stub"
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
else
    echo "[=] /etc/resolv.conf already correctly points to systemd-resolved"
fi

# Get all active interfaces with DNS support (ignore loopback and virtual)
IFACES=$(resolvectl status | awk '/^Link [0-9]+/ {print $2}')

if [[ -z "$IFACES" ]]; then
    echo "[!] No interfaces found to configure."
    exit 1
fi

for IFACE in $IFACES; do
    echo "[+] Configuring DNS-over-TLS for interface: $IFACE"
    resolvectl dns "$IFACE" 9.9.9.9
    resolvectl domain "$IFACE" '~.'
    resolvectl dnsovertls "$IFACE" yes
done
