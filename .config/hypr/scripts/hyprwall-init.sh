#!/usr/bin/env bash

# Log everything
LOG_FILE="$HOME/.cache/hypr-refresh-all.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec >>"$LOG_FILE" 2>&1

echo "--- hypr-refresh-all start $(date) ---"

# Wallpaper to use (change if you want)
IMG="${1:-$HOME/Pictures/Wallpapers/default.jpg}"

CACHE_DIR="$HOME/.cache/wal"
COLORS_FILE="$CACHE_DIR/colors.json"

echo "Using image: $IMG"

wait_for_hyprctl() {
    echo "Waiting for Hyprland (hyprctl)..."
    local attempts=0 max_attempts=40
    while ! hyprctl version &>/dev/null; do
        if [ "$attempts" -ge "$max_attempts" ]; then
            echo "hyprctl not available after $max_attempts attempts."
            return 1
        fi
        sleep 0.25
        ((attempts++))
    done
    echo "hyprctl OK"
    return 0
}

wait_for_hyprpaper() {
    echo "Waiting for hyprpaper..."
    local attempts=0 max_attempts=40
    while ! pgrep -x hyprpaper >/dev/null 2>&1; do
        if [ "$attempts" -ge "$max_attempts" ]; then
            echo "hyprpaper not running after $max_attempts attempts."
            return 1
        fi
        sleep 0.25
        ((attempts++))
    done
    echo "hyprpaper OK"
    return 0
}

echo "Clearing old Pywal cache..."
rm -rf "$CACHE_DIR"

echo "Running pywal..."
wal -n -i "$IMG" || echo "wal failed"

echo "Waiting for Pywal colors.json..."
for i in {1..40}; do
    [ -f "$COLORS_FILE" ] && break
    sleep 0.1
done

if [ -f "$COLORS_FILE" ]; then
    echo "Pywal ready: $COLORS_FILE"
else
    echo "Warning: colors.json not found; continuing anyway"
fi

# Ensure Hyprland + hyprpaper
wait_for_hyprctl || echo "Warning: hyprctl not confirmed."
if ! pgrep -x hyprpaper >/dev/null 2>&1; then
    echo "hyprpaper not running; starting it."
    hyprpaper &
    sleep 0.5
fi
wait_for_hyprpaper || echo "Warning: hyprpaper not confirmed."

echo "Setting wallpaper via hyprpaper..."

MONITORS="$(hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null || true)"

if [ -z "$MONITORS" ]; then
    echo "No monitors found from hyprctl; skipping wallpaper set."
else
    echo "Monitors:"
    echo "$MONITORS"

    hyprctl hyprpaper unload all 2>/dev/null || true
    hyprctl hyprpaper preload "$IMG"

    while read -r MON; do
        [ -z "$MON" ] && continue
        echo "  -> setting $MON"
        hyprctl hyprpaper wallpaper "$MON,$IMG"
    done <<< "$MONITORS"
fi

echo "Restarting swaync and swayosd-server..."
pkill -x swaync         2>/dev/null || echo "swaync not running."
pkill -x swayosd-server 2>/dev/null || echo "swayosd-server not running."

sleep 0.3
swaync &
sleep 0.2
swayosd-server &

echo "Reloading Waybar (if running)..."
if pgrep -x waybar >/dev/null 2>&1; then
    # USR2 = reload config in Waybar
    pkill -USR2 waybar || echo "Failed to send USR2 to waybar."
else
    echo "waybar not running; starting it."
    waybar &
fi

echo "--- hypr-refresh-all end $(date) ---"

