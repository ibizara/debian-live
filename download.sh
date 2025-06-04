#!/bin/bash
set -e

REQUIRED_PACKAGES=(curl dpkg-dev gnupg wget)

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

# --- Tor Browser ---
TOR_DIR="config/includes.chroot/usr/local/tor-browser"
TOR_GPG_HOMEDIR="/tmp/tor-gpg"
mkdir -p "$TOR_DIR" "$TOR_GPG_HOMEDIR"
chmod 700 "$TOR_GPG_HOMEDIR"

echo "[*] Cleaning old Tor Browser files..."
rm -f "$TOR_DIR"/*.tar.xz*

echo "[*] Fetching latest Tor Browser release..."
LATEST=$(curl -s https://archive.torproject.org/tor-package-archive/torbrowser/ \
  | grep -oP '(?<=href=")[0-9]+\.[0-9]+(\.[0-9]+)?(?=/")' | sort -V | tail -n1)

TARBALL="tor-browser-linux-x86_64-${LATEST}.tar.xz"
SIG="$TARBALL.asc"
BASE_URL="https://archive.torproject.org/tor-package-archive/torbrowser/${LATEST}"

cd "$TOR_DIR"
wget -q -nc "${BASE_URL}/${TARBALL}"
wget -q -nc "${BASE_URL}/${SIG}"
gpg --homedir "$TOR_GPG_HOMEDIR" --keyserver hkps://keys.openpgp.org --recv-keys EF6E286DDA85EA2A4BA7DE684E2C6E8793298290

echo "[*] Verifying Tor Browser signature..."
if ! gpg --homedir "$TOR_GPG_HOMEDIR" --verify "$SIG" "$TARBALL" 2>&1 | grep -q "Good signature"; then
    echo "[!] GPG signature verification FAILED for Tor Browser"
    exit 1
fi
echo "[✓] Signature verified successfully"

cd -

# --- .deb packages directory ---
PKG_DIR="config/packages.chroot"
mkdir -p "$PKG_DIR"

echo "[*] Cleaning old .deb packages..."
rm -f "$PKG_DIR"/*.deb

# --- Pulsar (latest GitHub release) ---
echo "[*] Fetching latest Pulsar release..."
PULSAR_URL=$(curl -sL https://api.github.com/repos/pulsar-edit/pulsar/releases/latest \
  | grep "browser_download_url" | grep "amd64.deb" | cut -d '"' -f 4)

PULSAR_FILE=$(basename "$PULSAR_URL")
wget -q -nc -O "$PKG_DIR/$PULSAR_FILE" "$PULSAR_URL"

# Rename immediately for live-build compatibility
dpkg-name -o "$PKG_DIR/$PULSAR_FILE"

# --- VeraCrypt (latest stable from Launchpad) ---
echo "[*] Fetching latest VeraCrypt release..."
VC_PAGE=$(curl -s https://launchpad.net/veracrypt/+download)

VC_URL=$(echo "$VC_PAGE" | grep -oP 'https://.*veracrypt-[0-9.]+-Debian-12-amd64\.deb(?=")' | sort -V | tail -n 1)

if [[ -z "$VC_URL" ]]; then
    echo "[!] Failed to find VeraCrypt .deb URL on Launchpad"
    exit 1
fi

VC_FILE=$(basename "$VC_URL")
wget -q -nc -O "$PKG_DIR/$VC_FILE" "$VC_URL"

# Rename immediately for live-build compatibility
dpkg-name -o "$PKG_DIR/$VC_FILE"

# --- Set permission for _apt ---
find "$PKG_DIR" -name "*.deb" -exec chmod o+r {} \; 2>/dev/null
