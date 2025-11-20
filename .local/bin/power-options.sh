#!/usr/bin/env bash

# Power menu script using wofi --dmenu

options=" Lock
 Suspend
   Logout
   Reboot
 Shutdown
   Hibernate"

# Run wofi synchronously; it exits after selection
choice=$(echo -e "$options" \
    | rofi -dmenu --prompt "Power")

case "$choice" in
    " Lock")
        sleep 0.2
        hyprlock
        ;;
    " Suspend")
        systemctl suspend
        ;;
    "   Logout")
        hyprctl dispatch exit 0
        ;;
    "   Reboot")
        systemctl reboot
        ;;
    " Shutdown")
        shutdown
        ;;
    "   Hibernate")
        systemctl hibernate
        ;;
esac

