#!/bin/bash
set -e

SKIP_DOWNLOAD=false

REQUIRED_PACKAGES=(curl dpkg-dev gnupg live-build sudo wget)

# --- Check required packages ---
echo "[*] Checking required packages..."
MISSING_PACKAGES=()

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo "[!] The following packages are required but not installed:"
    printf '  - %s\n' "${MISSING_PACKAGES[@]}"
    echo ""
    read -rp "[?] Install missing packages with 'sudo apt install'? [Y/n]: " RESP
    RESP=${RESP:-Y}
    if [[ "$RESP" =~ ^[Yy]$ ]]; then
        sudo apt update
        sudo apt install -y "${MISSING_PACKAGES[@]}"
    else
        echo "[!] Cannot continue without required packages."
        exit 1
    fi
fi

# --- Parse Arguments ---
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -s|--skip-download)
            SKIP_DOWNLOAD=true
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -s, --skip-download   Skip downloading packages (use existing ones)"
            echo "  -h, --help            Show this help message and exit"
            exit 0
            ;;
        *)
            echo "[!] Unknown option: $1"
            echo "Use -h or --help for usage."
            exit 1
            ;;
    esac
    shift
done

# --- Make sure permissions are correct ---
echo "[*] Setting permissions for build scripts, hooks, and sensitive files"
chmod +x download.sh \
  config/hooks/live/*.chroot \
  config/includes.chroot/usr/local/bin/*.sh \
  config/includes.chroot/etc/xdg/autostart/*.desktop \
  config/includes.chroot/usr/share/applications/*.desktop 2>/dev/null
chmod 600 config/includes.chroot/etc/strongswan/ipsec.secrets 2>/dev/null

# --- Run downloads unless skipped ---
if [ "$SKIP_DOWNLOAD" = false ]; then
    ./download.sh
else
    echo "[=] Skipping package downloads (as requested)"
fi

# --- Clean previous build ---
echo "[*] Cleaning previous build..."
sudo lb clean --purge

# --- Configure live-build ---
echo "[*] Running lb config for Debian Bookworm with UK mirrors..."
sudo lb config \
  --distribution bookworm \
  --debian-installer none \
  --archive-areas "main contrib non-free non-free-firmware" \
  --binary-images iso-hybrid \
  --mirror-bootstrap http://ftp.uk.debian.org/debian \
  --mirror-chroot http://ftp.uk.debian.org/debian \
  --mirror-binary http://ftp.uk.debian.org/debian \
  --mirror-binary-security http://security.debian.org/debian-security \
  --bootappend-live "boot=live components locales=en_GB.UTF-8 keyboard-layouts=gb timezone=Europe/London utc=yes"

# --- Start build ---
echo "[*] Starting ISO build..."
if sudo lb build; then
    echo "[✓] Build finished successfully."
else
    echo "[!] Build failed. Attempting to unmount bind..."
    exit 1
fi

# --- Move final ISO ---
ISO_NAME="live-image-amd64.hybrid.iso"

if [[ -f "$ISO_NAME" ]]; then
  echo "[*] Moving final ISO to ~/Desktop..."
  mv "$ISO_NAME" "$HOME/Desktop/"
  sudo chown "$(whoami):$(whoami)" "$HOME/Desktop/$ISO_NAME"
  echo "[✓] ISO moved to: $HOME/Desktop/$ISO_NAME"
else
  echo "[!] Build did not produce expected ISO: $ISO_NAME"
  exit 1
fi

echo "[✓] Build complete!"
