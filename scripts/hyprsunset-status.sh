#!/bin/sh
# hyprsunset-status.sh — Waybar custom module status script
# Purpose: Outputs JSON indicating whether hyprsunset (night mode) is running.
# Called by: Waybar custom/hyprsunset module (config/waybar/modules/custom.jsonc)
# Output: JSON with text (icon), tooltip, and class (for CSS state styling)
# Dependencies: pgrep

if pgrep -x hyprsunset >/dev/null 2>&1; then
	echo '{"text":"󰖔","tooltip":"Hyprsunset Enabled","class":"enabled"}'
else
	echo '{"text":"󰖙","tooltip":"Hyprsunset Disabled","class":"disabled"}'
fi
