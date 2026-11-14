#!/usr/bin/env bash
# waybar-position.sh — Switch Waybar position (top, bottom, left, right)
# Purpose: Switches Waybar layout between horizontal (top/bottom) and vertical (left/right).
# Usage:
#   waybar-position.sh [top|bottom|left|right]
#   If called without arguments, prompts via wofi menu.
# Dependencies: waybar, wofi (optional, for interactive menu)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$REPO_DIR/config/waybar/config.jsonc"

POSITION="${1:-}"

# If no argument given, prompt via wofi or show usage
if [ -z "$POSITION" ]; then
	if command -v wofi >/dev/null 2>&1 && [ -n "${WAYLAND_DISPLAY:-}" ]; then
		SELECTION=$(printf "󰕒 Top\n󰕕 Bottom\n󰕘 Left\n󰕚 Right" | wofi --dmenu --prompt "Waybar Position")
		case "$SELECTION" in
			*"Top"*)    POSITION="top" ;;
			*"Bottom"*) POSITION="bottom" ;;
			*"Left"*)   POSITION="left" ;;
			*"Right"*)  POSITION="right" ;;
			*)          exit 0 ;;
		esac
	else
		echo "Usage: $0 [top|bottom|left|right]"
		exit 1
	fi
fi

POSITION="$(echo "$POSITION" | tr '[:upper:]' '[:lower:]')"

case "$POSITION" in
	top)
		cat > "$CONFIG_FILE" <<-'EOF'
		{
		  "name": "horizontal",
		  "position": "top",
		  "margin-top": 6,
		  "margin-bottom": 0,
		  "margin-left": 4,
		  "margin-right": 4,

		  "include": [
		    "config-horizontal.jsonc"
		  ]
		}
		EOF
		;;
	bottom)
		cat > "$CONFIG_FILE" <<-'EOF'
		{
		  "name": "horizontal",
		  "position": "bottom",
		  "margin-top": 0,
		  "margin-bottom": 6,
		  "margin-left": 4,
		  "margin-right": 4,

		  "include": [
		    "config-horizontal.jsonc"
		  ]
		}
		EOF
		;;
	left)
		cat > "$CONFIG_FILE" <<-'EOF'
		{
		  "name": "vertical",
		  "position": "left",
		  "margin-top": 4,
		  "margin-bottom": 4,
		  "margin-left": 6,
		  "margin-right": 0,

		  "include": [
		    "config-vertical.jsonc"
		  ]
		}
		EOF
		;;
	right)
		cat > "$CONFIG_FILE" <<-'EOF'
		{
		  "name": "vertical",
		  "position": "right",
		  "margin-top": 4,
		  "margin-bottom": 4,
		  "margin-left": 0,
		  "margin-right": 6,

		  "include": [
		    "config-vertical.jsonc"
		  ]
		}
		EOF
		;;
	*)
		echo "Error: Unknown position '$POSITION'. Must be top, bottom, left, or right." >&2
		exit 1
		;;
esac

# Also update ~/.config/waybar/config.jsonc if it exists on a distinct file path
USER_CONFIG="$HOME/.config/waybar/config.jsonc"
if [ -f "$USER_CONFIG" ] && [ "$(realpath "$CONFIG_FILE" 2>/dev/null)" != "$(realpath "$USER_CONFIG" 2>/dev/null)" ]; then
	cp "$CONFIG_FILE" "$USER_CONFIG"
fi

# Restart Waybar if it is running
if pgrep -x waybar >/dev/null 2>&1; then
	pkill -x waybar
	sleep 0.2
	waybar &
fi

echo "Waybar position set to: $POSITION"
