#!/bin/bash
set -e

APP_NAME="omni"
GITHUB_REPO="edgeleap/omni"
DOWNLOAD_BASE="https://github.com/${GITHUB_REPO}/releases/latest/download"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Mode
# - default: installs GUI (same behavior as original)
# - --cli: installs CLI-only (no GUI)
MODE="gui"
if [ "${1:-}" = "--cli" ]; then
  MODE="cli"
fi

if [ "$MODE" = "cli" ]; then
  echo "Installing ${APP_NAME} (CLI-only)..."
else
  echo "Installing ${APP_NAME}..."
fi
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
if [ "$MODE" = "cli" ]; then
  ARTIFACT="${APP_NAME}-cli-${OS_NAME}-${ARCH_NAME}.tar.gz"
else
  ARTIFACT="${APP_NAME}-${OS_NAME}-${ARCH_NAME}.tar.gz"
fi
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
  if [ "$MODE" = "cli" ]; then
    INSTALL_DIR="$HOME/.local/bin"
    INSTALL_PATH="$INSTALL_DIR/${APP_NAME}"

    echo "→ Installing to ${INSTALL_PATH}..."

    # CLI-only: archive contains a single binary named `omni`
    if [ ! -f "$TMP_DIR/omni" ]; then
      echo -e "${RED}✘ CLI binary not found in CLI-only archive (expected file named 'omni')${NC}"
      exit 1
    fi

    mkdir -p "$INSTALL_DIR"
    mv "$TMP_DIR/omni" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"

    echo ""
    echo -e "${GREEN}✓ Installed to ${INSTALL_PATH}${NC}"
    echo "  Try: omni --help"

    # Check if in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
      echo ""
      echo "⚠ Add to PATH by adding this to ~/.bashrc or ~/.zshrc:"
      echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi

  else
    INSTALL_PATH="/Applications/${APP_NAME}.app"
    echo "→ Installing to ${INSTALL_PATH}..."

    # Remove quarantine attribute
    xattr -cr "$TMP_DIR/${APP_NAME}.app" 2>/dev/null || true

    # Remove old version if exists
    [ -d "$INSTALL_PATH" ] && rm -rf "$INSTALL_PATH"

    mv "$TMP_DIR/${APP_NAME}.app" /Applications/

    # Install `omni` router shim (no args => open GUI, args => run embedded cli)
    # This installs only the shim in ~/.local/bin; the real CLI lives inside the .app.
    CLI_DIR="$HOME/.local/bin"
    mkdir -p "$CLI_DIR"
    cat > "$CLI_DIR/omni" <<'INNER'
#!/bin/sh
if [ "$#" -eq 0 ]; then
  open -a "omni" >/dev/null 2>&1 || open "/Applications/omni.app" >/dev/null 2>&1
  exit 0
fi

exec "/Applications/omni.app/Contents/MacOS/omni-cli" "$@"
INNER
    chmod +x "$CLI_DIR/omni"

    echo ""
    echo -e "${GREEN}✓ Installed to /Applications/${APP_NAME}.app${NC}"
    echo "  Open with: open /Applications/${APP_NAME}.app"
    echo "  Or search '${APP_NAME}' in Spotlight"
    echo -e "${GREEN}✓ Installed CLI shim to ${CLI_DIR}/omni${NC}"
    echo "  Try: omni --help"

    # Check if in PATH
    if [[ ":$PATH:" != *":$CLI_DIR:"* ]]; then
      echo ""
      echo "⚠ Add to PATH by adding this to ~/.bashrc or ~/.zshrc:"
      echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
  fi

elif [ "$OS_NAME" = "linux" ]; then
  INSTALL_DIR="$HOME/.local/bin"
  mkdir -p "$INSTALL_DIR"

  if [ "$MODE" = "cli" ]; then
    INSTALL_PATH="$INSTALL_DIR/${APP_NAME}"
    echo "→ Installing to ${INSTALL_PATH}..."

    # CLI-only: archive contains a single binary named `omni`
    if [ ! -f "$TMP_DIR/omni" ]; then
      echo -e "${RED}✘ CLI binary not found in CLI-only archive (expected file named 'omni')${NC}"
      exit 1
    fi
    mv "$TMP_DIR/omni" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"

    echo ""
    echo -e "${GREEN}✓ Installed to ${INSTALL_PATH}${NC}"

  else
    # GUI + CLI (Linux, no shim):
    # - GUI is installed as `omni-app`
    # - CLI is installed as `omni`
    GUI_PATH="$INSTALL_DIR/${APP_NAME}-app"
    CLI_PATH="$INSTALL_DIR/${APP_NAME}"

    echo "→ Installing GUI to ${GUI_PATH}..."
    chmod +x "$TMP_DIR/${APP_NAME}.AppImage"
    mv "$TMP_DIR/${APP_NAME}.AppImage" "$GUI_PATH"

    # Also install CLI by downloading the CLI-only artifact for this platform.
    echo "→ Installing CLI to ${CLI_PATH}..."
    CLI_ARTIFACT="${APP_NAME}-cli-${OS_NAME}-${ARCH_NAME}.tar.gz"
    CLI_URL="${DOWNLOAD_BASE}/${CLI_ARTIFACT}"
    curl -fsSL "$CLI_URL" -o "$TMP_DIR/cli.tar.gz"
    tar -xzf "$TMP_DIR/cli.tar.gz" -C "$TMP_DIR"
    if [ ! -f "$TMP_DIR/omni" ]; then
      echo -e "${RED}✘ CLI binary not found in CLI archive (expected file named 'omni')${NC}"
      exit 1
    fi
    mv "$TMP_DIR/omni" "$CLI_PATH"
    chmod +x "$CLI_PATH"

    echo ""
    echo -e "${GREEN}✓ Installed GUI to ${GUI_PATH}${NC}"
    echo -e "${GREEN}✓ Installed CLI to ${CLI_PATH}${NC}"
    echo "  Run GUI: ${GUI_PATH}"
    echo "  Run CLI: omni --help"
  fi

  # Check if in PATH
  if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo "⚠ Add to PATH by adding this to ~/.bashrc or ~/.zshrc:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
fi

echo ""
echo -e "${GREEN}✓ Done!${NC}"
