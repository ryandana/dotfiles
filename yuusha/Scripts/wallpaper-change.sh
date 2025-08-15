#!/bin/bash

# --- Settings ---
WALLPAPER_DIR="$HOME/dotfiles/yuusha/Pictures/Wallpapers"
THUMB_DIR="$HOME/.cache/wallpaper_thumbs"
LOCKFILE="/tmp/rofi_wallpaper.lock"

# Prevent multiple instances
if [ -e "$LOCKFILE" ]; then
    echo "Wallpaper picker already running."
    exit 1
fi
trap "rm -f $LOCKFILE" EXIT
touch "$LOCKFILE"

mkdir -p "$THUMB_DIR"

# Generate thumbnails in the background if missing
find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | while read -r wallpaper; do
    filename=$(basename "$wallpaper")
    thumb_path="$THUMB_DIR/${filename%.*}.png"

    if [ ! -f "$thumb_path" ]; then
        # Generate in the background
        convert "$wallpaper" -thumbnail 96x96^ -gravity center -extent 96x96 "$thumb_path" 2>/dev/null &
    fi
done
wait # ensure all thumbnails are ready

# Build Rofi entries
ROFI_ENTRIES=""
while IFS= read -r wallpaper; do
    filename=$(basename "$wallpaper")
    thumb_path="$THUMB_DIR/${filename%.*}.png"
    [ -f "$thumb_path" ] && ROFI_ENTRIES+="${filename}\0icon\x1f${thumb_path}\n"
done < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | sort)

# Show Rofi menu (safe launch)
SELECTED=$(echo -en "$ROFI_ENTRIES" | rofi -dmenu -i -no-lazy-grab -p "Select wallpaper:" -show-icons)

# Apply selected wallpaper with random animation
if [ -n "$SELECTED" ]; then
    FULL_PATH=$(find "$WALLPAPER_DIR" -name "$SELECTED" | head -n1)
    if [ -f "$FULL_PATH" ]; then
        TRANSITIONS=("wipe" "grow")
        TRANSITION=${TRANSITIONS[$RANDOM % ${#TRANSITIONS[@]}]}
        swww img "$FULL_PATH" \
            --transition-type "$TRANSITION" \
            --transition-duration 2 \
            --transition-fps 240
    fi
fi
