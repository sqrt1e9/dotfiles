#!/bin/bash

# Local theme directory (containing theme.conf or theme.txt)
THEME_SRC_DIR=${THEME_SRC_DIR:-"./where_is_my_sddm_theme"}

# Destination in SDDM
SDDM_THEMES_DIR="/usr/share/sddm/themes"
THEME_NAME="where_is_my_sddm_theme"

# File to modify inside theme
THEME_FILE="theme.conf"   # change to theme.txt if needed

# Value to write (example)
NEW_BACKGROUND="/usr/share/sddm/themes/${THEME_NAME}/background.jpg"

#########################################

# Validate
if [[ ! -d "$THEME_SRC_DIR" ]]; then
    echo "Theme directory not found: $THEME_SRC_DIR"
    exit 1
fi

if [[ ! -f "$THEME_SRC_DIR/$THEME_FILE" ]]; then
    echo "Theme file not found: $THEME_FILE"
    exit 1
fi

# Modify theme file
echo "Modifying $THEME_FILE..."

# Example sed – change Background= line
sed -i "s|^Background=.*|Background=${NEW_BACKGROUND}|" "$THEME_SRC_DIR/$THEME_FILE"

# Copy to SDDM
echo "Installing theme..."
sudo rm -rf "$SDDM_THEMES_DIR/$THEME_NAME"
sudo cp -r "$THEME_SRC_DIR" "$SDDM_THEMES_DIR/$THEME_NAME"

echo "Done."

# Set as current if requested
if [[ "$1" == "current" ]]; then
    CONF="/etc/sddm.conf.d/kde_settings.conf"
    if [[ -f $CONF ]]; then
        sudo sed -i "s|^Current=.*|Current=${THEME_NAME}|" "$CONF"
    else
        echo "Could not find $CONF. Set Current=${THEME_NAME} manually."
    fi
fi

