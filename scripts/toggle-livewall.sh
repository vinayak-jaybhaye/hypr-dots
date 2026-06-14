#!/bin/sh
# toggle-livewall.sh — Toggle live wallpaper on/off
# Purpose: Starts or kills mpvpaper (live video wallpaper).
# Called by: Keybind SUPER+W (config/hypr/keybinds.conf)
# Dependencies: mpvpaper, livewall.sh (in same directory)
if pgrep mpvpaper >/dev/null; then
  pkill mpvpaper
else
  ~/hypr-dots/scripts/livewall.sh &
fi

