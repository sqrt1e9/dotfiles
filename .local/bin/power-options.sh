#!/usr/bin/env bash

action="$1"

swaync-client -cp
sleep 0.5

case "$action" in
  shutdown)
    prompt="Shut down?"
    run_cmd="systemctl poweroff"
    cancel_cmd="shutdown -c 2>/dev/null || true"
    ;;
  reboot)
    prompt="Reboot?"
    run_cmd="systemctl reboot"
    cancel_cmd="shutdown -c 2>/dev/null || true"
    ;;
  logout)
    prompt="Log out?"
    run_cmd="hyprctl dispatch exit 0"
    cancel_cmd="true"
    ;;
  lock)
    prompt="Lock screen?"
    run_cmd="hyprlock"
    cancel_cmd="true"
    ;;
  suspend)
    prompt="Suspend?"
    run_cmd="systemctl suspend"
    cancel_cmd="true"
    ;;
  *)
    exit 1
    ;;
esac

choice="$(printf 'Confirm\nCancel\n' | rofi -dmenu -i -p "$prompt")"

case "$choice" in
  Confirm)
      killall rofi
      sleep 1
    eval "$run_cmd"
    ;;
  Cancel|"")
    eval "$cancel_cmd"
    ;;
esac
