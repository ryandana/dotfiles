#!/bin/bash

# Directory containing wallpapers
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Temporary directory for thumbnails
THUMB_DIR="/tmp/wallpaper_thumbs"
mkdir -p "$THUMB_DIR"

# Clean up thumbnails on exit
trap "rm -rf $THUMB_DIR" EXIT

# Build rofi entries with thumbnails
ROFI_ENTRIES=""
while IFS= read -r wallpaper; do
    filename=$(basename "$wallpaper")
    thumb_path="$THUMB_DIR/${filename%.*}.png"
    
    # Generate thumbnail (bigger - 96x96)
    convert "$wallpaper" -thumbnail 96x96^ -gravity center -extent 96x96 "$thumb_path" 2>/dev/null
    
    # Add entry with thumbnail
    [ -f "$thumb_path" ] && ROFI_ENTRIES="${ROFI_ENTRIES}${filename}\0icon\x1f${thumb_path}\n"
done < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | sort)

# Show rofi selector with thumbnails on left
SELECTED=$(echo -en "$ROFI_ENTRIES" | rofi -dmenu -i -p "Select wallpaper:" -show-icons)

# Set wallpaper if selected
if [ -n "$SELECTED" ]; then
    FULL_PATH=$(find "$WALLPAPER_DIR" -name "$SELECTED" | head -n1)
    if [ -f "$FULL_PATH" ]; then
        # Change wallpaper
        swww img "$FULL_PATH" --transition-type grow --transition-duration 2 --transition-fps 240
    fi
fi
