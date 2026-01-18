#!/bin/bash
set -e

APP_NAME="omni"
GITHUB_REPO="edgeleap/omni"
DOWNLOAD_BASE="https://github.com/${GITHUB_REPO}/releases/latest/download"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "Installing ${APP_NAME}..."
echo ""

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case $OS in
  darwin) OS_NAME="macos" ;;
  linux)  OS_NAME="linux" ;;
  *)      echo -e "${RED}✘ Unsupported OS: $OS${NC}"; exit 1 ;;
esac

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
  x86_64|amd64) ARCH_NAME="x64" ;;
  arm64|aarch64) ARCH_NAME="arm64" ;;
  *)            echo -e "${RED}✘ Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

echo "→ Detected: ${OS_NAME} (${ARCH_NAME})"

# Build artifact name
ARTIFACT="${APP_NAME}-${OS_NAME}-${ARCH_NAME}.tar.gz"
URL="${DOWNLOAD_BASE}/${ARTIFACT}"

echo "→ Downloading from: ${URL}"

# Create temp directory
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# Download
curl -fsSL "$URL" -o "$TMP_DIR/archive.tar.gz"

# Extract
echo "→ Extracting..."
tar -xzf "$TMP_DIR/archive.tar.gz" -C "$TMP_DIR"

# Install based on OS
if [ "$OS_NAME" = "macos" ]; then
  INSTALL_PATH="/Applications/${APP_NAME}.app"
  
  echo "→ Installing to ${INSTALL_PATH}..."
  
  # Remove quarantine attribute
  xattr -cr "$TMP_DIR/${APP_NAME}.app" 2>/dev/null || true
  
  # Remove old version if exists
  [ -d "$INSTALL_PATH" ] && rm -rf "$INSTALL_PATH"
  
  mv "$TMP_DIR/${APP_NAME}.app" /Applications/
  
  echo ""
  echo -e "${GREEN}✓ Installed to /Applications/${APP_NAME}.app${NC}"
  echo "  Open with: open /Applications/${APP_NAME}.app"
  echo "  Or search '${APP_NAME}' in Spotlight"

elif [ "$OS_NAME" = "linux" ]; then
  INSTALL_DIR="$HOME/.local/bin"
  INSTALL_PATH="$INSTALL_DIR/${APP_NAME}"
  
  echo "→ Installing to ${INSTALL_PATH}..."
  
  mkdir -p "$INSTALL_DIR"
  chmod +x "$TMP_DIR/${APP_NAME}.AppImage"
  mv "$TMP_DIR/${APP_NAME}.AppImage" "$INSTALL_PATH"
  
  echo ""
  echo -e "${GREEN}✓ Installed to ${INSTALL_PATH}${NC}"
  
  # Check if in PATH
  if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo "⚠ Add to PATH by adding this to ~/.bashrc or ~/.zshrc:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
fi

echo ""
echo -e "${GREEN}✓ Done!${NC}"
