#!/usr/bin/env bash

set -u

CONFIG="$HOME/.config/chrome-lock"

mkdir -p "$CONFIG"
chmod 700 "$CONFIG"

echo "======================================"
echo " Chrome Secure Password Setup"
echo "======================================"
echo
echo "This creates a password hash."
echo "The plaintext password is not stored."
echo

read -rsp "Enter Chrome master password: " MASTER_PASSWORD
echo

printf '%s\n' "$MASTER_PASSWORD" |
    openssl passwd -6 -stdin > "$CONFIG/password.hash"

unset MASTER_PASSWORD

chmod 600 "$CONFIG/password.hash"

echo
echo "Master password hash created."
echo
echo "Profile password hashes should be created separately"
echo "for each configured profile."
