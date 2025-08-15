#!/bin/bash

NOTIF_ID=1001

# Adjust brightness
brightnessctl set "$1"

# Get percentage
BRI=$(brightnessctl get)
MAX=$(brightnessctl max)
PCT=$((BRI * 100 / MAX))

# Show OSD without icon
dunstify -a "brightness" -u low -r $NOTIF_ID \
    -h int:value:"$PCT" "🔅 Brightness: ${PCT}%"
