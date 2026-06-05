#!/usr/bin/env bash

BAT="${BAT:-BAT0}"
MODE="${1:-plain}"

BAT_PATH="/sys/class/power_supply/${BAT}"
PROFILE_FILE="/sys/devices/platform/tuxedo_keyboard/charging_profile/charging_profile"

# Battery info
capacity=$(cat "$BAT_PATH/capacity" 2>/dev/null || echo "?")
status=$(cat "$BAT_PATH/status" 2>/dev/null || echo "Unknown")
current=$(cat "$BAT_PATH/current_now" 2>/dev/null || echo 0)

# TUXEDO profile
profile=$(cat "$PROFILE_FILE" 2>/dev/null || echo "unknown")

# Find AC adapter automatically
ac_online=0

for file in /sys/class/power_supply/*/online; do
    [[ "$file" == *BAT* ]] && continue

    value=$(cat "$file" 2>/dev/null)

    if [[ "$value" =~ ^[01]$ ]]; then
        ac_online="$value"
        break
    fi
done

# Convert microamps -> milliamps
abs_current=${current#-}
ma=$((abs_current / 1000))

# Determine state
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

case "$MODE" in
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
