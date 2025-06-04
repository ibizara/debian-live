# Debian Live Build Environment

A custom Debian Live ISO tailored for privacy, UK localisation, and secure browsing. This project builds a live Debian environment with:

- Tor Browser (with Firejail sandboxing)
- DNS over TLS (Quad9)
- IKEv2/IPsec VPN (strongSwan)
- Hardened Firefox ESR
- Ublock Origin extension
- Pulsar editor with config
- Veracrypt encryption utility
- Custom Plymouth and GRUB themes
- Autostart configuration for NetworkManager and DNS privacy

---

## Build Process

1. Run `./rebuild.sh` to build the ISO and use `-s | --skip-download` if needed.
2. Output will be a bootable hybrid ISO `live-image-amd64.hybrid.iso`.

---

## Requirements

- Debian-based host OS
- `live-build` and related dependencies (incl. `dpkg-dev`)
- Sudo/root privileges for certain operations

---

## Installed Packages

These packages are included by default as part of the live environment:

### Base System
- `console-setup`: Configure console font and keyboard layout
- `feh`: Lightweight image viewer for setting wallpapers
- `hunspell-en-gb`: British English spell checking
- `keyboard-configuration`: Manages keyboard layout setup
- `lightdm`: Display manager for graphical login
- `locales`: Localisation support, including `en_GB.UTF-8`
- `mate-desktop-environment`: Lightweight, full-featured desktop
- `plymouth`: Boot splash screen
- `systemd-timesyncd`: Time synchronisation
- `tzdata`: Timezone database
- `xserver-xorg`: Graphical display server

### Networking
- `network-manager`: Main network connection manager
- `network-manager-gnome`: GUI applet for managing connections
- `network-manager-strongswan`: IPsec VPN integration
- `strongswan`: VPN daemon for IKEv2/IPsec
- `strongswan-swanctl`: Advanced config utility for strongSwan
- `systemd-resolved`: DNS resolution service (DoT compatible)

### Tools & Utilities
- `curl`, `wget`, `dnsutils`: Web and DNS utilities
- `filezilla`: FTP client
- `firefox-esr`: Web browser with enterprise support
- `firejail`: Security sandbox for applications
- `gnupg`: Encryption and signing tools
- `htop`, `iftop`, `iotop`, `screen`, `tcpdump`, `traceroute`: System/network monitoring tools
- `iptables`: Firewall rules engine
- `mozo`: MATE menu editor
- `putty-tools`: SSH utilities
- `seahorse`: GNOME key manager
- `torbrowser-launcher`: Secure Tor browser installer
- `torsocks`: Proxy apps through Tor
- `transmission`: Torrent client
- `tree`: Visualise directory structures
- `whois`: Domain/IP whois lookup

### Third Party
- `pulsar`: Hackable text editor based on Atom, pre-configured
- `veracrypt`: Open-source disk encryption software

---

## File & Folder Structure

### Root Directory

- **download.sh**
  - Ensures `dpkg-name` is installed for naming packages.
  - Downloads tor and `.deb` packages (pulsar, veracrypt) then places them in `config/packages.chroot`.

- **rebuild.sh**
  - Controls whether to skip re-downloading packages (`--skip-download`).
  - Removes previous `live-build` output and cache.
  - Runs `lb clean` and `lb config` to prepare build environment.
  - Initiates the build with `lb build`.

### config/hooks/live/

- **99-enable-services.chroot**
  - Enables timesyncd, dns-over-tls, systemd-resolved and iptables-restore.

- **99-firefox-policies.chroot**
  - Applies custom Firefox policies (e.g., disables telemetry).

- **99-install-torbrowser.chroot**
  - Extracts Tor Browser to `~/.local/share/torbrowser/tbb/x86_64`.

- **99-set-ntp.chroot**
  - Configures systemd-timesyncd for NTP.

- **99-set-plymouth-theme.chroot**
  - Applies custom Plymouth boot splash theme.

- **9999-fix-perms.chroot**
  - Ensures correct ownership for `/home/user`.

### config/includes.binary/boot/grub/

- **config.cfg**, **grub.cfg**
  - Custom GRUB menu configurations and splash settings.

### config/includes.binary/isolinux/

- **isolinux.cfg**, **menu.cfg**
  - ISOLINUX configuration files for BIOS systems.

- **splash.png**, **splash800x600.png**
  - Custom boot splash images.

### config/includes.chroot/etc/

- **firefox-esr/policies/policies.json**
  - JSON configuration for Firefox ESR settings.

- **live/config.conf.d/locale-timezone.conf**
  - Sets system locale to `en_GB.UTF-8` and timezone to `Europe/London`.

- **NetworkManager/99-dns-over-tls**
  - Enforces Quad9 DNS over TLS configuration.

- **strongswan/ipsec.conf**, **ipsec.secrets**
  - Example IKEv2/IPsec VPN configuration and ipsec secrets.

- **systemd/system/dns-over-tls.service**
  - Service unit to initiate DNS-over-TLS at boot.

- **systemd/system/iptables-restore.service**
  - Restores firewall rules on system start.

- **iptables.rules**
  - Persistent iptables firewall rules.

- **xdg/autostart/live-session-setup.desktop**, **nm-applet.desktop**
  - Autostart configuration for live session and network applet.

### config/includes.chroot/home/user/.pulsar/

- **config.cson**
  - Pulsar editor configuration file.

### config/includes.chroot/usr/local/bin/

- **dns-over-tls.sh**
  - Shell script to configure DNS-over-TLS.

- **install-vmtools.sh**
  - Installs guest tools for virtual machines.

- **live-session-setup.sh**
  - Configures user session environment on login.

### config/includes.chroot/usr/local/share/

- **ublock-origin.xpi**
  - Firefox add-on for ad and tracker blocking.

### config/includes.chroot/usr/local/tor-browser/
- Tor Browser files placed here during build.

### config/includes.chroot/usr/share/applications/

- **tor-browser.desktop**
  - Adds Tor Browser (firejail) to desktop environment menus.

### config/includes.chroot/usr/share/backgrounds/

- **wallhaven.png**
  - Default desktop background.

### config/includes.chroot/usr/share/plymouth/themes/connect/

- **connect.plymouth**, **connect.script**
  - Theme files for Plymouth boot splash.

### config/package-lists/

- **custom.list.chroot**, **live.list.chroot**
  - Lists of additional packages to install in the live environment.

### config/packages.chroot
- `.deb` packages placed here during build.
