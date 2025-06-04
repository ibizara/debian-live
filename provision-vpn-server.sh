#!/bin/bash

# Ensure script runs as root
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root or with sudo."
  exit 1
fi

# Install required packages
apt update
DEBIAN_FRONTEND=noninteractive apt install -y \
  strongswan iptables iptables-persistent curl dante-server

# Generate credentials
VPN_PSK=$(openssl rand -base64 32)
PUBLIC_IP=$(curl -s http://ip.ce.uk)
EXT_IFACE=$(ip route get 1 | awk '{print $5; exit}')

# Configure IPsec
cat > /etc/ipsec.conf <<EOF
config setup
    #charondebug="ike 2, knl 2, cfg 2, net 2, esp 2, dmn 2, mgr 2"
	charondebug="ike 1, cfg 1"
	
conn ikev2-psk
    auto=add
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    dpdaction=clear
    dpddelay=300s
    rekey=no
    left=%any
    leftid=$PUBLIC_IP
    leftsubnet=0.0.0.0/0
    right=%any
    rightid=%any
    rightsourceip=10.10.10.0/24
    modeconfig=push
    rightdns=9.9.9.9
    leftauth=psk
    rightauth=psk
    ike=aes256gcm16-sha256-ecp256,aes256gcm16-sha256-modp2048,aes256-sha256-ecp256,aes256-sha256-modp2048,aes128-sha256-ecp256,aes128-sha256-modp2048!
EOF

# Configure secrets
cat > /etc/ipsec.secrets <<EOF
: PSK "$VPN_PSK"
EOF

# Enable IPv4 forwarding
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ipsec-forwarding.conf
sysctl -p /etc/sysctl.d/99-ipsec-forwarding.conf

# NAT rules
iptables -t nat -C POSTROUTING -s 10.10.10.0/24 -o "$EXT_IFACE" -j MASQUERADE 2>/dev/null || \
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o "$EXT_IFACE" -j MASQUERADE

# Persist rules
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt install -y iptables-persistent

iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
systemctl enable netfilter-persistent

# Configure Dante SOCKS proxy
cat > /etc/danted.conf <<EOF
#logoutput: syslog
logoutput: /dev/null

internal: $EXT_IFACE port = 1080
external: $EXT_IFACE

method: none

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
    log: connect disconnect error
}
EOF

# Install but disable Dante SOCKS proxy by default
systemctl disable danted
systemctl stop danted

# Restart IPsec
systemctl restart strongswan-starter
systemctl enable strongswan-starter

# Output details
cat > /root/vpn.txt <<EOF
===============================
    IKEv2/IPsec VPN is ready   
===============================
Server Address : $PUBLIC_IP
Remote ID      : $PUBLIC_IP
Pre-Shared Key : $VPN_PSK
DNS Pushed     : 9.9.9.9
VPN Subnet     : 10.10.10.0/24
===============================
    Optional SOCKS5 Proxies     
===============================
[ SSH Tunnel (Preferred) ]
ssh -D 1080 -q -C -N admin@$PUBLIC_IP -i ~/.ssh/key.pem
SOCKS Server   : 127.0.0.1
Port           : 1080

[ Dante Proxy (Disabled by default) ]
SOCKS Server   : $PUBLIC_IP
Port           : 1080
sudo systemctl enable danted
sudo systemctl start danted
===============================
Open firewall ports VPN server:
IKE            : UDP 500
NAT-T          : UDP 4500
SOCKS Proxy    : TCP 1080 (optional)
===============================
Helpful commands:
curl -s https://{server}/{this-script}.sh | sudo bash
sudo iptables -t nat -L -n -v
sudo journalctl -u strongswan-starter -f
sudo journalctl -u danted -f
sudo nano /etc/ipsec.conf
sudo nano /etc/danted.conf
sudo cat /root/vpn.txt
EOF

cat /root/vpn.txt
