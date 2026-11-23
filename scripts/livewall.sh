#!/bin/sh
# livewall.sh — Start live wallpaper using mpvpaper
# Purpose: Plays a video as the desktop wallpaper on the specified monitor.
# Called by: toggle-livewall.sh
# Dependencies: mpvpaper (aur-pkglist.txt)
# Set LIVEWALL_OUTPUT in the session environment to target one monitor.
# LIVEWALL_VIDEO can point to any readable video file.

MONITOR="${LIVEWALL_OUTPUT:-ALL}"
VIDEO="${LIVEWALL_VIDEO:-$HOME/Pictures/live-wallpapers/stone-bridge.mp4}"
if [ ! -r "$VIDEO" ]; then
	printf 'Cannot read live wallpaper: %s\n' "$VIDEO" >&2
	exit 1
fi

exec mpvpaper \
	-o "--loop-file=inf \
	    --no-audio \
	    --hwdec=auto \
	    --vo=gpu \
	    --profile=low-latency \
	    --scale=bilinear" \
	"$MONITOR" "$VIDEO"
