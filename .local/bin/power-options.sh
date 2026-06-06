#!/usr/bin/env bash

action="$1"

# Close notification center
swaync-client -cp
sleep 0.5

case "$action" in
  shutdown)
    shutdown
    ;;
  reboot)
    systemctl reboot
    ;;
  logout)
    hyprctl dispatch exit 0
    ;;
  lock)
    hyprlock
    ;;
  suspend)
    systemctl suspend
    ;;
  *)
    exit 1
    ;;
esac
