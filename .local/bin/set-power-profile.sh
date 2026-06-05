#!/usr/bin/env bash

PROFILE_FILE="/sys/devices/platform/tuxedo_keyboard/charging_profile/charging_profile"
SWAYNC_CONFIG="$HOME/.config/swaync/config.json"

profile="$1"

case "$profile" in
    stationary|balanced|high_capacity)
        ;;
    current)
        cat "$PROFILE_FILE"
        exit 0
        ;;
    *)
        echo "Usage:"
        echo "  set-power-profile current"
        echo "  set-power-profile stationary"
        echo "  set-power-profile balanced"
        echo "  set-power-profile high_capacity"
        exit 1
        ;;
esac

sudo /usr/local/bin/set-tuxedo-profile.sh "$profile" || exit 1

tmp="$(mktemp)"

jq --arg profile "$profile" '
  .["widget-config"]["buttons-grid#powermodes"].actions |=
  map(
    if (.command | contains("high_capacity")) then
      .active = ($profile == "high_capacity")
    elif (.command | contains("balanced")) then
      .active = ($profile == "balanced")
    elif (.command | contains("stationary")) then
      .active = ($profile == "stationary")
    else
      .
    end
  )
' "$SWAYNC_CONFIG" > "$tmp" && mv "$tmp" "$SWAYNC_CONFIG"

pkill -x swaync 2>/dev/null
pkill -x swaync-client 2>/dev/null
sleep 0.3
nohup swaync >/dev/null 2>&1 &
sleep 0.2
nohup swaync-client >/dev/null 2>&1 &
swaync-client -t

echo "Battery profile set to: $profile"
