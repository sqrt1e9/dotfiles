#!/bin/bash

notify-send "Wi-Fi" "Scanning for networks..."
wifi_list=$(nmcli --fields "SECURITY,SSID" device wifi list | sed 1d | sed 's/  */ /g' | sed -E "s/WPA*.?\S/ /g" | sed "s/^--/ /g" | sed "s/  //g" | sed "/--/d")

connected=$(nmcli -fields WIFI g)
if [[ "$connected" =~ "enabled" ]]; then
    toggle="󰖪  Disable Wi-Fi"
elif [[ "$connected" =~ "disabled" ]]; then
    toggle="󰖩  Enable Wi-Fi"
fi

chosen_network=$(echo -e "$toggle\n$wifi_list" | uniq -u | \
    wofi --dmenu --prompt "Wi-Fi SSID:")

read -r chosen_id <<< "${chosen_network:3}"

if [ -z "$chosen_network" ]; then
    exit
elif [ "$chosen_network" = "󰖩  Enable Wi-Fi" ]; then
    nmcli radio wifi on
elif [ "$chosen_network" = "󰖪  Disable Wi-Fi" ]; then
    nmcli radio wifi off
else
    success_message="You are now connected to the Wi-Fi network \"$chosen_id\"."
    active_id=$(nmcli -t -f NAME,DEVICE connection show --active | grep ":wlp0s20f3" | cut -d: -f1)
    if [ "$chosen_id" = "$active_id" ]; then
        notify-send "Already Connected" "$success_message"
    else
        wifi_password=$(wofi --dmenu --password --prompt "Password for $chosen_id:")
        if [ -n "$wifi_password" ]; then
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

