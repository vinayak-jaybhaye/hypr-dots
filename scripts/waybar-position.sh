#!/usr/bin/env bash
# waybar-position.sh — Switch Waybar position (top, bottom, left, right)
# Horizontal and vertical profiles supply the layout for each pair of edges.
# Usage: waybar-position.sh [top|bottom|left|right] or --start at session login.
# If called without arguments, prompt via wofi or show usage.
# Dependencies: waybar, wofi (for the interactive menu)

set -euo pipefail

bar_dir="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hypr-dots"
profile="$state_dir/waybar-position.jsonc"

start_bar() {
	# Waybar resolves relative includes from its working directory and search path.
	cd -- "$bar_dir"
	export WAYBAR_CONFIG_DIR=.
	if [[ -f "$profile" ]]; then
		export HYPR_DOTS_WAYBAR_DISPLAY="${WAYLAND_DISPLAY:-}"
		exec waybar -c "$profile"
	fi
	exec waybar
}

position="${1:-}"
if [[ "$position" == --start ]]; then
	start_bar
fi
if [[ -z "$position" ]]; then
	if [[ -z "${WAYLAND_DISPLAY:-}" ]] || ! command -v wofi >/dev/null; then
		echo "Usage: $0 [top|bottom|left|right]" >&2
		exit 1
	fi
	selection=$(printf '󰕒 Top\n󰕕 Bottom\n󰕘 Left\n󰕚 Right\n' | wofi --dmenu --prompt "Waybar Position") || exit 0
	[[ -n "$selection" ]] || exit 0
	position=${selection##* }
fi

position=${position,,}
case "$position" in
	top)    layout=horizontal; margin='6 4 0 4' ;;
	bottom) layout=horizontal; margin='0 4 6 4' ;;
	left)   layout=vertical;   margin='4 0 4 6' ;;
	right)  layout=vertical;   margin='4 6 4 0' ;;
	*) echo "Unknown Waybar position: $position" >&2; exit 2 ;;
esac

[[ -r "$bar_dir/config-$layout.jsonc" ]] || { echo "Missing Waybar layout in $bar_dir" >&2; exit 1; }
mkdir -p -- "$state_dir"
temp=$(mktemp "$state_dir/.waybar-position.XXXXXX")
trap 'rm -f -- "$temp"' EXIT
cat > "$temp" <<JSON
{
  "name": "$layout",
  "position": "$position",
  "margin": "$margin",
  "include": ["config-$layout.jsonc"]
}
JSON
mv -T -- "$temp" "$profile"

# Reload a bar using the saved profile. A bar using the project default
# needs one restart to adopt it. A stopped bar picks it up on login.
if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
	if ! pkill -USR2 -u "$UID" --env "HYPR_DOTS_WAYBAR_DISPLAY=$WAYLAND_DISPLAY" -x waybar &&
		pkill -u "$UID" --env "WAYLAND_DISPLAY=$WAYLAND_DISPLAY" -x waybar; then
		start_bar &
	fi
fi
echo "Waybar position set to $position"
