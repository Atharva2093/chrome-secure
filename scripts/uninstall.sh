#!/usr/bin/env bash

set -u

LAUNCHER="$HOME/.local/bin/chrome-secure"

if [ -f "$LAUNCHER" ]; then
    rm -f "$LAUNCHER"
    echo "Chrome Secure launcher removed."
else
    echo "Chrome Secure launcher was not found."
fi

echo
echo "Chrome profile data and password hashes were NOT deleted."
echo "This is intentional to prevent accidental data loss."
