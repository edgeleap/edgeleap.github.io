#!/usr/bin/env bash
set -euo pipefail

# Bootstrap installer for diffsense.
# Intended to be hosted at: https://edgeleap.github.io/install.sh
# It downloads the latest diffsense.sh asset from the latest release of edgeleap/diffsense and runs it.

OWNER="edgeleap"
REPO="diffsense"
API_URL="https://api.github.com/repos/${OWNER}/${REPO}/releases/latest"

echo "Fetching latest release for ${OWNER}/${REPO} ..."
JSON=$(curl -fsSL "$API_URL")

# Find the browser_download_url for asset named exactly diffsense.sh
ASSET_URL=$(printf '%s\n' "$JSON" \
  | grep -oE '"browser_download_url": *"[^"]*diffsense\.sh"' \
  | head -n1 \
  | sed -E 's/.*\"browser_download_url\": *\"([^\"]*)\".*/\1/')

if [[ -z "${ASSET_URL:-}" ]]; then
  echo "No asset named 'diffsense.sh' found in latest release for ${OWNER}/${REPO}." >&2
  exit 1
fi

echo "Downloading latest diffsense.sh from: $ASSET_URL"
TMP_SCRIPT="$(mktemp /tmp/diffsense.latest.XXXXXX.sh)"
curl -fsSL "$ASSET_URL" -o "$TMP_SCRIPT"
chmod +x "$TMP_SCRIPT"

echo "Running downloaded diffsense.sh ..."
exec "$TMP_SCRIPT"
