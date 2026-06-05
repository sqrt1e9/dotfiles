#!/usr/bin/env bash
set -euo pipefail

wallpaperDir="$HOME/.local/share/backgrounds"
themesDir="$HOME/.config/rofi"
syncScript="$HOME/.local/bin/hyprsync.sh"

mapfile -t PICS < <(
    find -L "$wallpaperDir" -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) \
        | sort
)

if [[ ${#PICS[@]} -eq 0 ]]; then
    notify-send "Wallpaper error" "No wallpapers found in $wallpaperDir"
    exit 1
fi

randomChoice="[${#PICS[@]}] Random"

rofiCommand=(rofi -show -dmenu -theme "$themesDir/wallpaper-select.rasi")

menu() {
    printf "%s\n" "$randomChoice"

    for file in "${PICS[@]}"; do
        name="$(basename "$file")"
        label="${name%.*}"

        if [[ "$file" == *.gif ]]; then
            printf "%s\n" "$name"
        else
            printf "%s\x00icon\x1f%s\n" "$label" "$file"
        fi
    done
}

main() {
    local choice selectedFile=""

    choice="$(menu | "${rofiCommand[@]}")"

    [[ -z "$choice" ]] && exit 0

    if [[ "$choice" == "$randomChoice" ]]; then
        "$syncScript"
        exit 0
    fi

    for file in "${PICS[@]}"; do
        name="$(basename "$file")"
        label="${name%.*}"

        if [[ "$choice" == "$label" || "$choice" == "$name" ]]; then
            selectedFile="$file"
            break
        fi
    done

    if [[ -z "$selectedFile" ]]; then
        notify-send "Wallpaper error" "Selected wallpaper not found"
        exit 1
    fi

    "$syncScript" "$selectedFile"
}

main
