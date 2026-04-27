#!/usr/bin/env bash

wallpaperDir="$HOME/.local/share/backgrounds"
themesDir="$HOME/.config/rofi"

if pidof swaybg > /dev/null; then
    pkill swaybg
fi

mapfile -t PICS < <(
    find -L "$wallpaperDir" -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) \
        | sort
)

if [[ ${#PICS[@]} -eq 0 ]]; then
    notify-send "Wallpaper error" "No wallpapers found in $wallpaperDir"
    exit 1
fi

randomNumber=$(( ($(date +%s) + RANDOM) + $$ ))
randomPicture="${PICS[$(( randomNumber % ${#PICS[@]} ))]}"
randomChoice="[${#PICS[@]}] Random"

rofiCommand="rofi -show -dmenu -theme ${themesDir}/wallpaper-select.rasi"

executeCommand() {
    file="$1"

    if command -v hyprctl >/dev/null 2>&1; then
        "$HOME/.local/bin/hyprwall-init.sh" "$file"
    else
        echo "No supported wallpaper setter found."
        exit 1
    fi
}

menu() {
    printf "%s\n" "$randomChoice"

    for i in "${!PICS[@]}"; do
        if [[ "${PICS[$i]}" != *.gif ]]; then
            printf "%s\x00icon\x1f%s\n" \
                "$(basename "${PICS[$i]}" | cut -d. -f1)" \
                "${PICS[$i]}"
        else
            printf "%s\n" "$(basename "${PICS[$i]}")"
        fi
    done
}

main() {
    choice=$(menu | ${rofiCommand})

    if [[ -z "$choice" ]]; then
        exit 0
    fi

    if [[ "$choice" == "$randomChoice" ]]; then
        executeCommand "$randomPicture"
        return 0
    fi

    selectedFile=""

    for file in "${PICS[@]}"; do
        if [[ "$(basename "$file" | cut -d. -f1)" == "$choice" || "$(basename "$file")" == "$choice" ]]; then
            selectedFile="$file"
            break
        fi
    done

    if [[ -n "$selectedFile" ]]; then
        executeCommand "$selectedFile"
    else
        notify-send "Wallpaper error" "Image not found."
        exit 1
    fi
}

main
