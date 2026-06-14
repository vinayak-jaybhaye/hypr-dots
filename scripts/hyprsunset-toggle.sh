#!/usr/bin/env bash
# hyprsunset-toggle.sh — Toggle night mode (hyprsunset) on/off
# Purpose: Kills hyprsunset if running, starts it if not.
# Called by: Waybar on-click (custom/hyprsunset) + keybind in keybinds.conf
# Signal: Sends RTMIN+2 to waybar after toggle for instant status update.
# Dependencies: pkill, pgrep, hyprsunset, waybar


if pgrep -x hyprsunset >/dev/null; then
	pkill -x hyprsunset
else
	hyprsunset &
fi

sleep 0.1
pkill -RTMIN+2 waybar
