#!/bin/bash

# Notification
notify-send "Wi-Fi" "Scanning for networks..."

# Get active SSID
active_id=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)

# Check Wi-Fi state
wifi_state=$(nmcli -fields WIFI g)

# Toggle option (only one shown)
if [[ "$wifi_state" =~ "enabled" ]]; then
    toggle_option="󰖪 Disable Wi-Fi"
else
    toggle_option="󰖩 Enable Wi-Fi"
fi

# Build Wi-Fi list (clean + filtered)
wifi_list=$(nmcli --fields "SECURITY,SSID" device wifi list | sed 1d | sed 's/  */ /g' | while read -r line; do
    ssid=$(echo "$line" | cut -d' ' -f2-)

    # Remove junk entries
    [[ -z "$ssid" || "$ssid" =~ ^-+$ ]] && continue

    if [[ "$ssid" == "$active_id" ]]; then
        printf "✓ %s\n" "$ssid"
    else
        printf " %s\n" "$ssid"
    fi
done | awk '!seen[$0]++')

# Show menu
chosen_network=$(echo -e "$toggle_option\n$wifi_list" | rofi -dmenu -prompt "Wi-Fi SSID:")

# Exit if nothing selected
[ -z "$chosen_network" ] && exit

# Handle toggle
if [[ "$chosen_network" == "$toggle_option" ]]; then
    if [[ "$wifi_state" =~ "enabled" ]]; then
        nmcli radio wifi off
        notify-send "Wi-Fi" "Wi-Fi Disabled"
    else
        nmcli radio wifi on
        notify-send "Wi-Fi" "Wi-Fi Enabled"
    fi
    exit
fi

# Extract SSID
chosen_id=$(echo "$chosen_network" | sed 's/^..//')

# Already connected?
if [ "$chosen_id" = "$active_id" ]; then
    notify-send "Already Connected" "You are already connected to \"$chosen_id\"."
    exit
fi

# Ask password
wifi_password=$(rofi -dmenu -config ~/.config/rofi/password.rasi -password -prompt "Password for $chosen_id:")

if [ -n "$wifi_password" ]; then
    nmcli connection delete id "$chosen_id" 2>/dev/null
    notify-send "Wi-Fi" "Connecting to $chosen_id..."

    nmcli device wifi connect "$chosen_id" password "$wifi_password" name "$chosen_id" >/tmp/wifi.log 2>&1

    if [ $? -eq 0 ]; then
        notify-send "Connection Established" "Connected to \"$chosen_id\"."
    else
        notify-send "Wi-Fi Connection Failed" "Could not connect to \"$chosen_id\"."
    fi
else
    notify-send "Wi-Fi Connection Failed" "No password entered"
fi
