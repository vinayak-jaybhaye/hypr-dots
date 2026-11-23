#!/bin/sh
# toggle-livewall.sh — Toggle live wallpaper on/off
# Purpose: Starts or kills mpvpaper (live video wallpaper).
# Called by: Keybind SUPER+W (config/hypr/keybinds.lua)
# Dependencies: mpvpaper, livewall.sh (in same directory)
if pgrep -u "$(id -u)" -x mpvpaper >/dev/null; then
	pkill -u "$(id -u)" -x mpvpaper
else
	"$(dirname -- "$0")/livewall.sh" &
fi

