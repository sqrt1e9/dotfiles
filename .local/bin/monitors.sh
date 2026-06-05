#!/bin/sh
if hyprctl monitors -j | grep -q '"HDMI-A-1"'; then
    hyprctl keyword monitor "HDMI-A-1, 3840x2160@60, 0x0, 1.6"
    hyprctl keyword monitor "eDP-1, disable"
else
    hyprctl keyword monitor "eDP-1, 2560x1600@240, 0x0, 1.33"
fi

