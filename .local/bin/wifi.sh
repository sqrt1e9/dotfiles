#!/bin/bash

# Send initial notification
notify-send "Wi-Fi" "Scanning for networks..."

# Fetch Wi-Fi list
wifi_list=$(nmcli --fields "SECURITY,SSID" device wifi list | sed 1d | sed 's/  */ /g' | sed -E "s/WPA*.?\S/ /g" | sed "s/^--/ /g" | sed "s/  //g" | sed "/--/d")

# Check if Wi-Fi is enabled or disabled
connected=$(nmcli -fields WIFI g)
if [[ "$connected" =~ "enabled" ]]; then
    toggle_enable="󰖩  Enable Wi-Fi"
    toggle_disable="󰖪  Disable Wi-Fi"
else
    toggle_enable="󰖩  Enable Wi-Fi"
    toggle_disable="󰖪  Disable Wi-Fi"
fi

# Adjust formatting for the toggle options
toggle_enabled=$(printf "%-2s %-25s\n" "󰖩" "Enable Wi-Fi")
toggle_disabled=$(printf "%-2s %-25s\n" "󰖪" "Disable Wi-Fi")

# Add the toggle option and Wi-Fi list to the menu
chosen_network=$(echo -e "$toggle_enabled\n$toggle_disabled\n$wifi_list" | uniq -u | rofi -dmenu -prompt "Wi-Fi SSID:")

# Extract the network SSID from the chosen option
read -r chosen_id <<< "${chosen_network:3}"

# Exit if no option is chosen
if [ -z "$chosen_network" ]; then
    exit
elif [ "$chosen_network" = "$toggle_enabled" ]; then
    # Enable Wi-Fi if that option is selected
    nmcli radio wifi on
    notify-send "Wi-Fi" "Wi-Fi Enabled"
elif [ "$chosen_network" = "$toggle_disabled" ]; then
    # Disable Wi-Fi if that option is selected
    nmcli radio wifi off
    notify-send "Wi-Fi" "Wi-Fi Disabled"
else
    # Connect to the chosen Wi-Fi network
    success_message="You are now connected to the Wi-Fi network \"$chosen_id\"."
    active_id=$(nmcli -t -f NAME,DEVICE connection show --active | grep ":wlp0s20f3" | cut -d: -f1)
    
    if [ "$chosen_id" = "$active_id" ]; then
        notify-send "Already Connected" "$success_message"
    else
        wifi_password=$(rofi -dmenu -config ~/.config/rofi/password.rasi -password -prompt "Password for $chosen_id:")
        
        if [ -n "$wifi_password" ]; then
            # Delete existing connection if any, and then try to connect to the chosen network
            nmcli connection delete id "$chosen_id" 2>/dev/null
            notify-send "Wi-Fi" "Connecting to $chosen_id..."
            nmcli device wifi connect "$chosen_id" password "$wifi_password" name "$chosen_id" >/tmp/wifi.log 2>&1
            
            if [ $? -eq 0 ]; then
                notify-send "Connection Established" "$success_message"
            else
                notify-send "Wi-Fi Connection Failed" "Could not connect to \"$chosen_id\"."
            fi
        else
            notify-send "Wi-Fi Connection Failed" "No password entered"
        fi
    fi
fi
