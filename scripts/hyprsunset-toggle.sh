#!/bin/sh
# hyprsunset-toggle.sh — Toggle night mode (hyprsunset) on/off
# Purpose: Kills hyprsunset if running, starts it if not.
# Called by: Waybar on-click (custom/hyprsunset)
# Signal: Sends RTMIN+2 to waybar after toggle for instant status update.
# Dependencies: pkill, pgrep, hyprsunset, waybar

if pgrep -u "$(id -u)" -x hyprsunset >/dev/null; then
	pkill -u "$(id -u)" -x hyprsunset
else
	hyprsunset &
fi

sleep 0.1
pkill -u "$(id -u)" -x -RTMIN+2 waybar
