#!/bin/sh
if hyprctl monitors -j | grep -q '"HDMI-A-1"'; then
    hyprctl keyword monitor "HDMI-A-1,3840x2160@60,0x0,2.0"
    hyprctl keyword monitor "eDP-1,disable"
else
    hyprctl keyword monitor "eDP-1,3200x2000@165,0x0,2.0"
fi

