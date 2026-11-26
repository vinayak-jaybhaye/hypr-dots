#!/bin/sh
# mako-dnd-status.sh — JSON status for custom integrations
# Purpose: Outputs JSON indicating whether Mako's Do Not Disturb mode is active.
# Output: JSON with text (icon), tooltip, and class (for CSS state styling)
# Dependencies: makoctl

if makoctl mode | grep -Fxq do-not-disturb; then
	echo '{"text":"󰂛","class":"enabled","tooltip":"Do Not Disturb enabled"}'
else
	echo '{"text":"󰂚","class":"disabled","tooltip":"Notifications enabled"}'
fi
