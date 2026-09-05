#!/usr/bin/env bash

set -u

# ============================================================
# Chrome Secure
# Two-stage authentication launcher
# ============================================================

BASE="$HOME/.var/app/com.google.Chrome/config/chrome-lock-profiles"
CONFIG="$HOME/.config/chrome-lock"

MASTER_HASH="$CONFIG/password.hash"

declare -A PROFILE_DIR
declare -A PROFILE_HASH

# ------------------------------------------------------------
# Generic profile configuration
# ------------------------------------------------------------

PROFILE_DIR["Profile 01"]="profile-01"
PROFILE_DIR["Profile 02"]="profile-02"
PROFILE_DIR["Profile 03"]="profile-03"
PROFILE_DIR["Profile 04"]="profile-04"
PROFILE_DIR["Profile 05"]="profile-05"
PROFILE_DIR["Profile 06"]="profile-06"
PROFILE_DIR["Profile 07"]="profile-07"
PROFILE_DIR["Profile 08"]="profile-08"
PROFILE_DIR["Profile 09"]="profile-09"
PROFILE_DIR["Profile 10"]="profile-10"
PROFILE_DIR["Profile 11"]="profile-11"
PROFILE_DIR["Profile 12"]="profile-12"

PROFILE_HASH["Profile 01"]="profile-01.hash"
PROFILE_HASH["Profile 02"]="profile-02.hash"
PROFILE_HASH["Profile 03"]="profile-03.hash"
PROFILE_HASH["Profile 04"]="profile-04.hash"
PROFILE_HASH["Profile 05"]="profile-05.hash"
PROFILE_HASH["Profile 06"]="profile-06.hash"
PROFILE_HASH["Profile 07"]="profile-07.hash"
PROFILE_HASH["Profile 08"]="profile-08.hash"
PROFILE_HASH["Profile 09"]="profile-09.hash"
PROFILE_HASH["Profile 10"]="profile-10.hash"
PROFILE_HASH["Profile 11"]="profile-11.hash"
PROFILE_HASH["Profile 12"]="profile-12.hash"

# ------------------------------------------------------------
# Validate configuration
# ------------------------------------------------------------

if [ ! -f "$MASTER_HASH" ]; then
    zenity --error \
        --title="Chrome Locked" \
        --text="Chrome master password is not configured."
    exit 1
fi

if [ ! -d "$BASE" ]; then
    zenity --error \
        --title="Chrome Locked" \
        --text="Chrome secure profiles directory not found."
    exit 1
fi

# ------------------------------------------------------------
# Prevent multiple Chrome environments
# ------------------------------------------------------------

if pgrep -x chrome >/dev/null 2>&1 ||
   pgrep -x google-chrome >/dev/null 2>&1; then

    zenity --error \
        --title="Chrome Already Running" \
        --text="Please close all Chrome windows before opening a locked profile."

    exit 1
fi

# ------------------------------------------------------------
# Stage 1: Master password
# ------------------------------------------------------------

MASTER_PASSWORD=$(zenity --password \
    --title="Chrome Locked" \
    --text="Enter Chrome master password:")

if [ $? -ne 0 ]; then
    unset MASTER_PASSWORD
    exit 1
fi

SALT=$(cut -d'$' -f3 "$MASTER_HASH")

if ! printf '%s\n' "$MASTER_PASSWORD" |
    openssl passwd -6 -stdin -salt "$SALT" |
    cmp -s - "$MASTER_HASH"; then

    unset MASTER_PASSWORD

    zenity --error \
        --title="Access Denied" \
        --text="Incorrect Chrome master password."

    exit 1
fi

unset MASTER_PASSWORD

# ------------------------------------------------------------
# Stage 2: Select profile
# ------------------------------------------------------------

PROFILE=$(zenity --list \
    --title="Chrome Profiles" \
    --text="Select the Chrome profile you want to open:" \
    --column="Profile" \
    "Profile 01" \
    "Profile 02" \
    "Profile 03" \
    "Profile 04" \
    "Profile 05" \
    "Profile 06" \
    "Profile 07" \
    "Profile 08" \
    "Profile 09" \
    "Profile 10" \
    "Profile 11" \
    "Profile 12" \
    --height=500 \
    --width=450 \
    --print-column=1)

if [ $? -ne 0 ] || [ -z "$PROFILE" ]; then
    exit 1
fi

DIR_NAME="${PROFILE_DIR[$PROFILE]}"
HASH_NAME="${PROFILE_HASH[$PROFILE]}"

PROFILE_DIR_PATH="$BASE/$DIR_NAME"
PROFILE_HASH_PATH="$CONFIG/$HASH_NAME"

# ------------------------------------------------------------
# Validate selected profile
# ------------------------------------------------------------

if [ ! -d "$PROFILE_DIR_PATH" ]; then
    zenity --error \
        --title="Chrome Locked" \
        --text="Profile data not found for: $PROFILE"
    exit 1
fi

if [ ! -f "$PROFILE_HASH_PATH" ]; then
    zenity --error \
        --title="Chrome Locked" \
        --text="Password configuration not found for: $PROFILE"
    exit 1
fi

# ------------------------------------------------------------
# Stage 3: Profile password
# ------------------------------------------------------------

PROFILE_PASSWORD=$(zenity --password \
    --title="$PROFILE" \
    --text="Enter password for $PROFILE:")

if [ $? -ne 0 ]; then
    unset PROFILE_PASSWORD
    exit 1
fi

SALT=$(cut -d'$' -f3 "$PROFILE_HASH_PATH")

if ! printf '%s\n' "$PROFILE_PASSWORD" |
    openssl passwd -6 -stdin -salt "$SALT" |
    cmp -s - "$PROFILE_HASH_PATH"; then

    unset PROFILE_PASSWORD

    zenity --error \
        --title="Access Denied" \
        --text="Incorrect password for $PROFILE."

    exit 1
fi

unset PROFILE_PASSWORD

# ------------------------------------------------------------
# Launch selected isolated profile
# ------------------------------------------------------------

exec flatpak run com.google.Chrome \
    --user-data-dir="$PROFILE_DIR_PATH" \
    --no-first-run
