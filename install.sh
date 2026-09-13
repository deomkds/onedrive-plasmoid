#!/usr/bin/env bash
# Installation script for OneDrive Plasma 6 Applet
set -euo pipefail

APPLET_ID="org.kde.plasma.onedrive"
DEST_DIR="${HOME}/.local/share/plasma/plasmoids/${APPLET_ID}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Installing OneDrive KDE Plasma 6 Applet ==="
echo "Source: ${SOURCE_DIR}"
echo "Target: ${DEST_DIR}"

# Ensure parent directory exists
mkdir -p "${HOME}/.local/share/plasma/plasmoids"

# If kpackagetool6 is available, try using it first
if command -v kpackagetool6 >/dev/null 2>&1; then
    echo "Registering with kpackagetool6..."
    if kpackagetool6 -t Plasma/Applet --show "${APPLET_ID}" >/dev/null 2>&1; then
        kpackagetool6 -t Plasma/Applet --upgrade "${SOURCE_DIR}" || true
    else
        kpackagetool6 -t Plasma/Applet --install "${SOURCE_DIR}" || true
    fi
fi

# Ensure direct files are cleanly synced to the user plasmoid directory
rm -rf "${DEST_DIR}"
mkdir -p "${DEST_DIR}"
cp -r "${SOURCE_DIR}/metadata.json" "${DEST_DIR}/"
cp -r "${SOURCE_DIR}/contents" "${DEST_DIR}/"
if [ -d "${SOURCE_DIR}/images" ]; then
    cp -r "${SOURCE_DIR}/images" "${DEST_DIR}/"
fi

echo "=== Installation Successful! ==="
echo ""
echo "To test the plasmoid in a standalone window, run:"
echo "    plasmawindowed ${APPLET_ID}"
echo ""
echo "To add it to your KDE Plasma Panel or System Tray:"
echo "    Right-click on your panel -> 'Add Widgets...' -> Search for 'OneDrive'."
