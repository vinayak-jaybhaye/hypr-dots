#!/bin/sh
# power.sh — Battery power draw display for Waybar
# Purpose: Shows current battery charge/discharge rate in watts.
# Called by: Waybar custom/power module (config/waybar/modules/custom.jsonc)
# Output: Plain text (not JSON) — e.g. "⚡ -12.5W" or "⚡ +45.2W"
# Dependencies: upower (not in pkglist.txt — usually pre-installed)
# Note: Outputs nothing if no battery is detected (desktop systems).

bat_dev=$(upower -e | grep BAT | head -n1)
if [ -n "$bat_dev" ]; then
    rate=$(upower -i "$bat_dev" | awk '/energy-rate/ {print $2}')
    state=$(upower -i "$bat_dev" | awk '/state/ {print $2}')
    if [ -n "$rate" ] && [ "$rate" != "0" ] && [ "$rate" != "0.0" ]; then
        if [ "$state" = "discharging" ]; then
            echo "⚡ -${rate}W"
        elif [ "$state" = "charging" ]; then
            echo "⚡ +${rate}W"
        else
            echo "⚡ ${rate}W"
        fi
    fi
fi
