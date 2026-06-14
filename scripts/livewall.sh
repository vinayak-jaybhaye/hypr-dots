#!/bin/sh
# livewall.sh — Start live wallpaper using mpvpaper
# Purpose: Plays a video as the desktop wallpaper on the specified monitor.
# Called by: toggle-livewall.sh
# Dependencies: mpvpaper (not in pkglist.txt — install separately)
# CAUTION: MONITOR is hardcoded to "eDP-1" — update if monitor name changes.
# CAUTION: VIDEO path must exist or mpvpaper will fail silently.

MONITOR="eDP-1"
VIDEO="$HOME/Pictures/live-wallpapers/stone-bridge.mp4"

mpvpaper \
  -o "--loop-file=inf \
      --no-audio \
      --hwdec=auto \
      --vo=gpu \
      --profile=low-latency \
      --scale=bilinear" \
  "$MONITOR" "$VIDEO"
