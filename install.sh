#!/bin/bash
set -e

APP_NAME="omni"
GITHUB_REPO="edgeleap/omni"
DOWNLOAD_BASE="https://github.com/${GITHUB_REPO}/releases/latest/download"

echo "==> Omni Installer"
echo ""

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case $OS in
  darwin) OS="macos" ;;
  linux)  OS="linux" ;;
  *)      echo "Error: Unsupported OS: $OS"; exit 1 ;;
esac

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
  x86_64)  ARCH="x64" ;;
  amd64)   ARCH="x64" ;;
  arm64)   ARCH="arm64" ;;
  aarch64) ARCH="arm64" ;;
  *)       echo "Error: Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Build artifact name
ARTIFACT="${APP_NAME}-${OS}-${ARCH}"

if [ "$OS" = "macos" ]; then
  EXT="tar.gz"
  INSTALL_DIR="/Applications"
  APP_BUNDLE="Omni.app"
elif [ "$OS" = "linux" ]; then
  EXT="tar.gz"
  INSTALL_DIR="$HOME/.local/bin"
  APP_BUNDLE="omni"
fi

URL="${DOWNLOAD_BASE}/${ARTIFACT}.${EXT}"

echo "--> Detected: $OS ($ARCH)"
echo "--> Downloading: $URL"

# Create temp directory
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# Download
curl -fsSL "$URL" -o "$TMP_DIR/archive.${EXT}" || { echo "Error: Download failed"; exit 1; }

# Extract
echo "--> Extracting..."
tar -xzf "$TMP_DIR/archive.${EXT}" -C "$TMP_DIR"

# Install
if [ "$OS" = "macos" ]; then
  echo "--> Installing to ${INSTALL_DIR}/${APP_BUNDLE}..."
  
  # Remove quarantine attribute
  xattr -cr "$TMP_DIR/${APP_BUNDLE}" 2>/dev/null || true
  
  # Remove old version if exists
  [ -d "${INSTALL_DIR}/${APP_BUNDLE}" ] && rm -rf "${INSTALL_DIR}/${APP_BUNDLE}"
  
  mv "$TMP_DIR/${APP_BUNDLE}" "${INSTALL_DIR}/"
  
  echo ""
  echo "[OK] Installed to ${INSTALL_DIR}/${APP_BUNDLE}"
  echo "     Open with: open /Applications/Omni.app"
  echo "     Or search 'Omni' in Spotlight"

elif [ "$OS" = "linux" ]; then
  mkdir -p "$INSTALL_DIR"
  
  chmod +x "$TMP_DIR/${APP_BUNDLE}"
  mv "$TMP_DIR/${APP_BUNDLE}" "${INSTALL_DIR}/"
  
  echo ""
  echo "[OK] Installed to ${INSTALL_DIR}/${APP_BUNDLE}"
  
  # Check if in PATH
  if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo "[!] Add to PATH by adding this to ~/.bashrc or ~/.zshrc:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
fi

echo ""
echo "Done!"
