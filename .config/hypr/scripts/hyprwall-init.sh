#!/usr/bin/env bash

# Log everything
LOG_FILE="$HOME/.cache/hypr-refresh-all.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec >>"$LOG_FILE" 2>&1

echo "--- hypr-refresh-all start $(date) ---"

WALL_DIR="$HOME/Pictures/Wallpapers"
URL_CACHE_DIR="$HOME/.cache/hypr-wall-url"
mkdir -p "$URL_CACHE_DIR"

pick_random_wallpaper() {
    # Find images and pick one randomly
    if [ ! -d "$WALL_DIR" ]; then
        echo "Wallpaper directory not found: $WALL_DIR"
        return 1
    fi

    local img
    img="$(find "$WALL_DIR" -maxdepth 1 -type f \( \
            -iname '*.jpg' -o -iname '*.jpeg' -o \
            -iname '*.png' -o -iname '*.webp' \
        \) | shuf -n 1)"

    if [ -z "$img" ]; then
        echo "No wallpapers found in $WALL_DIR"
        return 1
    fi

    echo "$img"
    return 0
}

download_wallpaper_from_url() {
    local url="$1"

    echo "Downloading wallpaper from URL: $url"

    local filename
    filename="$(basename "$url")"
    local dest="$URL_CACHE_DIR/$filename"

    # Curl with silent mode + follow redirects
    if curl -L --fail -o "$dest" "$url"; then
        echo "Downloaded to: $dest"
        echo "$dest"
        return 0
    else
        echo "Failed to download image from: $url"
        return 1
    fi
}

# Decide image:
if [ -n "$1" ]; then
    if [[ "$1" =~ ^https?:// ]]; then
        echo "Argument is a URL, downloading..."
        IMG="$(download_wallpaper_from_url "$1")" || exit 1
    else
        echo "Using local image from argument: $1"
        IMG="$1"
    fi
else
    echo "No image given; picking random from $WALL_DIR"
    IMG="$(pick_random_wallpaper)" || exit 1
    echo "Random image chosen: $IMG"
fi

CACHE_DIR="$HOME/.cache/wal"
COLORS_FILE="$CACHE_DIR/colors.json"

echo "Final image path: $IMG"

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
    pkill -USR2 waybar || echo "Failed to send USR2 to waybar."
else
    echo "waybar not running; starting it."
    waybar &
fi

echo "--- hypr-refresh-all end $(date) ---"

