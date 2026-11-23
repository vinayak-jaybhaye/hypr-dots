#!/bin/sh
# power.sh — Battery power draw display for Waybar
# Purpose: Shows current battery charge/discharge rate in watts.
# Called by: Waybar custom/power module (config/waybar/modules/custom.jsonc)
# Output: Plain text (not JSON) — e.g. "⚡ -12.5W" or "⚡ +45.2W"
# Dependencies: upower
# Note: Outputs nothing if no battery is detected (desktop systems).

# UPower aggregates system batteries here, regardless of their kernel names.
export LC_ALL=C
upower -i /org/freedesktop/UPower/devices/DisplayDevice | awk '
	$1 == "state:" { state = $2 }
	$1 == "energy-rate:" { rate = $2 }
	END {
		if (rate + 0 <= 0) exit
		if (state == "discharging") sign = "-"
		if (state == "charging") sign = "+"
		printf "⚡ %s%sW\n", sign, rate
	}'
