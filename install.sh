#!/usr/bin/env bash
set -euo pipefail

# Bootstrap installer for diffsense.
# Intended to be hosted at: https://edgeleap.github.io/install.sh
# Downloads the latest diffsense.sh from the latest release of edgeleap/diffsense and installs it permanently.

OWNER="edgeleap"
REPO="diffsense"
API_URL="https://api.github.com/repos/${OWNER}/${REPO}/releases/latest"
INSTALL_PATH="/usr/local/bin/diffsense"

# Fetch latest release information from GitHub API
echo "Fetching latest release for ${OWNER}/${REPO}..."
JSON=$(curl -fsSL "$API_URL")

# Extract the download URL for diffsense.sh from the GitHub release JSON
ASSET_URL=$(printf '%s\n' "$JSON" \
  | grep -oE '"browser_download_url": *"[^"]*diffsense\.sh"' \
  | head -n1 \
  | sed -E 's/.*\"browser_download_url\": *\"([^\"]*)\".*/\1/')

# Verify we found the asset URL
if [[ -z "${ASSET_URL:-}" ]]; then
  echo "❌ No asset named 'diffsense.sh' found in latest release." >&2
  exit 1
fi

# Download the script to a temporary location
echo "Downloading diffsense.sh from: $ASSET_URL"
TMP_SCRIPT="$(mktemp)"
curl -fsSL "$ASSET_URL" -o "$TMP_SCRIPT"

# Install the script permanently (requires sudo for /usr/local/bin)
echo "Installing to $INSTALL_PATH..."
sudo cp "$TMP_SCRIPT" "$INSTALL_PATH"  # Use cp instead of mv to allow overwriting
sudo chmod +x "$INSTALL_PATH"
rm "$TMP_SCRIPT"  # Clean up temp file

echo "✅ diffsense installed successfully!"
echo "Run 'diffsense' in any git repository to get started."
