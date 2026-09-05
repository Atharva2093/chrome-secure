#!/usr/bin/env bash

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/chrome-lock"

mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"

cp "$PROJECT_DIR/scripts/chrome-secure.sh" \
   "$INSTALL_DIR/chrome-secure"

chmod 700 "$INSTALL_DIR/chrome-secure"

echo
echo "Chrome Secure installed."
echo
echo "Launcher:"
echo "  $INSTALL_DIR/chrome-secure"
echo
echo "Next steps:"
echo "  1. Configure passwords."
echo "  2. Prepare isolated Chrome profiles."
echo "  3. Configure the Chrome desktop entry."
