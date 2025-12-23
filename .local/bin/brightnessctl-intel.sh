#!/bin/bash

# Define the target backlight device
DEVICE="intel_backlight"

# Define the step size (e.g., 5% or 10%)
STEP=5

if [ "$1" == "up" ]; then
    brightnessctl -d $DEVICE set +$STEP% # Increase brightness by 5%
elif [ "$1" == "down" ]; then
    brightnessctl -d $DEVICE set $STEP%- # Decrease brightness by 5%
fi

# Get the current brightness percentage of the specific device
# brightnessctl uses an integer percentage for swayosd
current_brightness=$(brightnessctl -d $DEVICE get)
max_brightness=$(brightnessctl -d $DEVICE max)
percentage=$(( (current_brightness * 100) / max_brightness ))

swayosd-client --brightness $percentage

