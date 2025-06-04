#!/bin/bash
set -e

SKIP_DOWNLOAD=false

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

# --- Make sure hook scripts are executable ---
echo "[*] Ensuring all hook scripts are executable..."
find config/hooks/ -type f -exec chmod +x {} \;
find config/includes.chroot/etc/profile.d/ -type f -exec chmod +x {} \; 2>/dev/null || true

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
