#!/bin/sh
# mako-dnd-status.sh — Waybar custom module status script
# Purpose: Outputs JSON indicating whether Mako's Do Not Disturb mode is active.
# Called by: Waybar custom/dnd module (config/waybar/modules/custom.jsonc)
# Output: JSON with text (icon), tooltip, and class (for CSS state styling)
# Dependencies: makoctl

if makoctl mode | grep -q do-not-disturb; then
	echo '{"text":"󰂛","class":"enabled","tooltip":"Do Not Disturb enabled"}'
else
	echo '{"text":"󰂚","class":"disabled","tooltip":"Notifications enabled"}'
fi
