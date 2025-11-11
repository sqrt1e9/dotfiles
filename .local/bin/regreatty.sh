#!/bin/bash
# sync-greetd.sh
# Sync greetd configs from ~/.config/greetd to /etc/greetd

SRC="$HOME/.config/greetd"
DST="/etc/greetd"

if [ ! -d "$SRC" ]; then
    echo "No greetd config found in $SRC"
    exit 1
fi

echo "Copying greetd config from $SRC to $DST ..."
sudo mkdir -p "$DST"
sudo cp -r "$SRC"/* "$DST"/

echo "Done. Restart greetd to apply changes:"
echo "  sudo systemctl restart greetd"

