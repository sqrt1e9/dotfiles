#!/usr/bin/env bash

# --- Environment + Daemons ---
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland
/usr/bin/gnome-keyring-daemon --start --components=secrets &
blueman-daemon &

# Start XDG portals using a fallback method
exec-once = systemctl --user import-environment DISPLAY WAYLAND_DISPLAY
exec-once = hash xdg-desktop-portal-hyprland 2>/dev/null && xdg-desktop-portal-hyprland || xdg-desktop-portal-gnome || xdg-desktop-portal-kde

# --- GTK Theme, Icons ---
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-Dark"
gsettings set org.gnome.desktop.interface icon-theme "Adwaita"

# --- Fonts ---
gsettings set org.gnome.desktop.interface font-name "FiraCode Nerd Font 11"
gsettings set org.gnome.desktop.interface monospace-font-name "FiraCode Nerd Font 11"
gsettings set org.gnome.desktop.interface document-font-name "FiraCode Nerd Font 11"

# --- Antialiasing / Hinting ---
gsettings set org.gnome.settings-daemon.plugins.xsettings antialiasing "rgba"
gsettings set org.gnome.settings-daemon.plugins.xsettings hinting "slight"

# --- Dark Mode ---
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

