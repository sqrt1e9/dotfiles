#!/usr/bin/env bash

BAT="${BAT:-BAT0}"

BAT_PATH="/sys/class/power_supply/${BAT}"
PROFILE_FILE="/sys/devices/platform/tuxedo_keyboard/charging_profile/charging_profile"
SWAYNC_CONFIG="$HOME/.config/swaync/config.json"

show_usage() {
    cat <<EOF
Usage:
  power-manager status [plain|waybar]
  power-manager stationary
  power-manager balanced
  power-manager high_capacity
EOF
}

get_profile() {
    cat "$PROFILE_FILE" 2>/dev/null || echo "unknown"
}

update_swaync() {
    local profile="$1"

    [[ -f "$SWAYNC_CONFIG" ]] || return 0

    local tmp
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' RETURN

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
    ' "$SWAYNC_CONFIG" > "$tmp" || return 1

    mv "$tmp" "$SWAYNC_CONFIG"

    pkill swaync 2>/dev/null
    pkill swaync-client 2>/dev/null

    sleep 0.5
    swaync-client -t >/dev/null 2>&1 &
}

set_profile() {
    local profile="$1"

    echo "$profile" | sudo tee "$PROFILE_FILE" >/dev/null || return 1

    local current
    current=$(cat "$PROFILE_FILE" 2>/dev/null)

    if [[ "$current" != "$profile" ]]; then
        echo "Failed to set profile"
        return 1
    fi

    update_swaync "$profile"

    printf 'Profile changed to: %s\n' "$profile"
}

show_status() {
    local mode="${1:-plain}"

    capacity=$(cat "$BAT_PATH/capacity" 2>/dev/null || echo "?")
    status=$(cat "$BAT_PATH/status" 2>/dev/null || echo "Unknown")
    current=$(cat "$BAT_PATH/current_now" 2>/dev/null || echo 0)
    profile=$(get_profile)

    ac_online=0

    for ps in /sys/class/power_supply/*; do
        [[ -d "$ps" ]] || continue

        type=$(cat "$ps/type" 2>/dev/null)

        if [[ "$type" == "Mains" ]]; then
            ac_online=$(cat "$ps/online" 2>/dev/null || echo 0)
            break
        fi
    done

    abs_current=${current#-}
    ma=$((abs_current / 1000))

    if [[ "$ac_online" -eq 0 ]]; then
        state="🔋 Battery"
        class="battery"
    elif [[ "$ma" -lt 50 ]]; then
        state="🔌 AC Only"
        class="ac"
    else
        state="⚡ Charging"
        class="charging"
    fi

    text="${state} ${capacity}% (${ma}mA) [${profile}]"

    case "$mode" in
        waybar)
            tooltip="State: ${state}
Battery: ${capacity}%
Current: ${ma}mA
Profile: ${profile}
Kernel Status: ${status}"

            printf '{"text":"%s","tooltip":"%s","class":"%s","percentage":%s}\n' \
                "$text" \
                "$tooltip" \
                "$class" \
                "${capacity:-0}"
            ;;
        *)
            echo "$text"
            ;;
    esac
}

command="${1:-status}"

case "$command" in
    status)
        show_status "${2:-plain}"
        ;;
    stationary|balanced|high_capacity)
        set_profile "$command"
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
