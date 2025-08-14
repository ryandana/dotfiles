#!/bin/bash

# === Downloader Script by yuusha ===

# Ask for URL
url=$(zenity --entry --title="Downloader" --text="Enter the video URL:" --width="600")
[ -z "$url" ] && exit 1

# Ask for type
choice=$(zenity --list --radiolist \
    --title="Download Type" \
    --text="Choose what to download:" \
    --column="Pick" --column="Type" \
    TRUE "Video (MP4 with AAC)" \
    FALSE "Audio (MP3)")

[ -z "$choice" ] && exit 1

# Setup format and output path
if [ "$choice" = "Video (MP4 with AAC)" ]; then
    outpath="$HOME/Videos/%(title).200s.%(ext)s"
    format="bv*[ext=mp4]+ba[acodec^=mp4a]/b[ext=mp4]/b"
    opts=(--merge-output-format mp4)
else
    outpath="$HOME/Music/%(title).200s.%(ext)s"
    format="bestaudio"
    opts=(--extract-audio --audio-format mp3)
fi

# Launch the download in background and show progress bar
(
    yt-dlp "$url" \
        -f "$format" \
        "${opts[@]}" \
        --embed-thumbnail \
        --embed-metadata \
        --add-metadata \
        --audio-quality 0 \
        --no-mtime \
        --newline \
        --progress-template "download:%(progress._percent_str)s" \
        -o "$outpath" 2>&1 |
    while read -r line; do
        if [[ "$line" =~ ([0-9]{1,3}\.[0-9])% ]]; then
            percent=${BASH_REMATCH[1]}
            echo "${percent%.*}"
        fi
    done
) |
zenity --progress \
    --title="Downloader" \
    --text="Downloading..." \
    --percentage=0 \
    --auto-close \
    --width=400 \
    --window-icon=info

# Completion notification
if [ $? -eq 0 ]; then
    notify-send "Downloader" "Download completed."
else
    notify-send "Downloader" "Download cancelled or failed."
fi
