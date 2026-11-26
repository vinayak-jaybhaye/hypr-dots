#!/bin/sh
# hyprsunset-status.sh — JSON status for custom integrations
# Purpose: Outputs JSON indicating whether hyprsunset (night mode) is running.
# Output: JSON with text (icon), tooltip, and class (for CSS state styling)
# Dependencies: pgrep

if [ "$("$(dirname -- "$0")/hyprsunset-toggle.sh" status)" = on ]; then
	echo '{"text":"󰖔","tooltip":"Hyprsunset Enabled","class":"enabled"}'
else
	echo '{"text":"","tooltip":"Hyprsunset Disabled","class":"disabled"}'
fi
