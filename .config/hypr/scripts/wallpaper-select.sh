#!/usr/bin/env bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# This script for selecting wallpapers (SUPER W)

# Wallpapers Path
wallpaperDir="$HOME/.local/share/backgrounds"
themesDir="$HOME/.config/rofi"

# Transition config
FPS=60
TYPE="any"
DURATION=3
BEZIER="0.4,0.2,0.4,1.0"

# Check if swaybg is running
if pidof swaybg > /dev/null; then
	pkill swaybg
fi

# Retrieve image files as a list
PICS=($(find -L "${wallpaperDir}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | sort))

# Use date variable to increase randomness
randomNumber=$(( ($(date +%s) + RANDOM) + $$ ))
randomPicture="${PICS[$(( randomNumber % ${#PICS[@]} ))]}"
randomChoice="[${#PICS[@]}] Random"

# Rofi command
rofiCommand="rofi -show -dmenu -theme ${themesDir}/wallpaper-select.rasi"

# Execute command according to the wallpaper manager
executeCommand() {
	file="$1"
	if command -v hyprctl >/dev/null 2>&1; then
	    ~/.config/hypr/scripts/hyprwall-init.sh "$file"
	else
		echo "No supported wallpaper setter found (swaybg or Hyprpaper)."
		exit 1
	fi
}

# Show the images
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

# Execution
main() {
	choice=$(menu | ${rofiCommand})

	# No choice case
	if [[ -z "$choice" ]]; then
		exit 0
	fi

	# Random choice case
	if [[ "$choice" == "$randomChoice" ]]; then
		executeCommand "${randomPicture}"
		return 0
	fi
	# Find selected file
	for file in "${PICS[@]}"; do
		if [[ "$(basename "$file" | cut -d. -f1)" == "$choice" ]]; then
			selectedFile="$file"
			break
		fi
	done

	# Check the file and execute
	if [[ -n "$selectedFile" ]]; then
		executeCommand "${selectedFile}"
	else
		echo "Image not found."
		exit 1
	fi
}

# Check if rofi is already running
if pidof rofi > /dev/null; then
	pkill rofi
	exit 0
fi
main

