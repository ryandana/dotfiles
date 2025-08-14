#!/bin/bash

NOTIF_ID=1000

# Adjust volume
case "$1" in
    up)   pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
    down) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
    mute) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
esac

# Get volume percentage
VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -n1 | tr -d '%')
MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')

# Show OSD without icon
if [ "$MUTE" = "yes" ]; then
    dunstify -a "volume" -u low -r $NOTIF_ID \
        -h int:value:"0" "Volume: Muted"
else
    dunstify -a "volume" -u low -r $NOTIF_ID \
        -h int:value:"$VOL" "Volume: ${VOL}%"
fi
