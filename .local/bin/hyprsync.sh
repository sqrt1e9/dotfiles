#!/usr/bin/env bash

# Log everything
LOG_FILE="$HOME/.cache/hypr-refresh-all.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec >>"$LOG_FILE" 2>&1

echo "--- hypr-refresh-all start $(date) ---"

WALL_DIR="$HOME/.local/share/backgrounds"
URL_CACHE_DIR="$HOME/.cache/hypr-wall-url"
THEME_DIR="$HOME/.config/theme"

mkdir -p "$URL_CACHE_DIR"
mkdir -p "$THEME_DIR"

pick_random_wallpaper() {
    if [ ! -d "$WALL_DIR" ]; then
        echo "Wallpaper directory not found: $WALL_DIR"
        return 1
    fi

    local img
    img="$(find -L "$WALL_DIR" -maxdepth 1 -type f \( \
            -iname '*.jpg' -o -iname '*.jpeg' -o \
            -iname '*.png' -o -iname '*.webp' \
        \) | shuf -n 1)"

    if [ -z "$img" ]; then
        echo "No wallpapers found in $WALL_DIR"
        return 1
    fi

    echo "$img"
}

download_wallpaper_from_url() {
    local url="$1"

    echo "Downloading wallpaper from URL: $url"

    local filename
    filename="$(basename "$url")"
    local dest="$URL_CACHE_DIR/$filename"

    if curl -L --fail -o "$dest" "$url"; then
        echo "Downloaded to: $dest"
        echo "$dest"
    else
        echo "Failed to download image from: $url"
        return 1
    fi
}

apply_pywal_accent() {
    local img="$1"

    echo "Applying pywal accent from: $img"

    if ! command -v wal >/dev/null 2>&1; then
        echo "pywal not installed. Skipping accent generation."
        return 0
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo "jq not installed. Skipping accent generation."
        return 0
    fi

    wal -q -n -i "$img"

    local hex
    hex="$(jq -r '.colors.color5 // .colors.color4 // "#7287fd"' "$HOME/.cache/wal/colors.json")"

    if [ -z "$hex" ] || [ "$hex" = "null" ]; then
        hex="#7287fd"
    fi

    local r g b
    r=$((16#${hex:1:2}))
    g=$((16#${hex:3:2}))
    b=$((16#${hex:5:2}))

    echo "Accent chosen: $hex"

    cat > "$THEME_DIR/current.css" <<EOF
@define-color accent ${hex};
@define-color accent-soft rgba(${r},${g},${b},.20);
@define-color accent-hover rgba(${r},${g},${b},.32);
EOF

    cat > "$THEME_DIR/current.rasi" <<EOF
* {
    accent: ${hex};
    accent-soft: rgba(${r}, ${g}, ${b}, 0.20);
    accent-hover: rgba(${r}, ${g}, ${b}, 0.32);
}
EOF

    FIREFOX_THEME_FILE="$HOME/.mozilla/firefox/default/chrome/theme-vars.css"

    mkdir -p "$(dirname "$FIREFOX_THEME_FILE")"

    cat > "$FIREFOX_THEME_FILE" <<EOF
:root { --accent: ${hex}; --accent-soft: rgba(${r}, ${g}, ${b}, .10); --accent-hover: rgba(${r}, ${g}, ${b}, .16); }
EOF
}

# Decide image
if [ "${1:-}" ]; then
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

echo "Final image path: $IMG"

if [ ! -f "$IMG" ]; then
    echo "Image file does not exist: $IMG"
    exit 1
fi

wait_for_hyprctl() {
    echo "Waiting for Hyprland hyprctl..."
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
}

# Generate theme accent first
apply_pywal_accent "$IMG"

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

    cp "$IMG" "$HOME/.local/share/backgrounds/default.jpg"

    while read -r MON; do
        [ -z "$MON" ] && continue
        echo "  -> setting $MON"
        hyprctl hyprpaper wallpaper "$MON,$IMG"
    done <<< "$MONITORS"
fi

echo "Restarting swaync and swayosd-server..."

pkill -x swaync 2>/dev/null || echo "swaync not running."
pkill -x swayosd-server 2>/dev/null || echo "swayosd-server not running."

sleep 0.3
swaync &

sleep 0.2
swayosd-server &

echo "Reloading Waybar..."

pkill waybar 2>/dev/null || true
waybar >/dev/null 2>&1 &

sed -i '/^background /d' "$HOME/.cache/wal/colors-kitty-light.conf"

kitty @ set-colors --all --configured "$HOME/.config/kitty/kitty.conf" 2>/dev/null || true
kitty @ set-colors --all "background=#eff1f5" "foreground=#4c4f69"

echo "--- hypr-refresh-all end $(date) ---"
