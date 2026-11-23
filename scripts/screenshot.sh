#!/bin/sh
# Capture first so cancelling a region selection leaves the clipboard intact.
set -eu

mode=${1:-}
case "$mode" in
	full) set -- ;;
	region|clipboard)
		geometry=$(slurp) || exit 0
		[ -n "$geometry" ] || exit 0
		set -- -g "$geometry"
		;;
	*) echo "Usage: $0 full|region|clipboard" >&2; exit 2 ;;
esac

if [ "$mode" = clipboard ]; then
	dir=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}
else
	dir="$HOME/Pictures"
	mkdir -p -- "$dir"
fi
temp=$(mktemp "$dir/.hypr-screenshot.XXXXXX")
trap 'rm -f -- "$temp"' 0
grim "$@" - > "$temp"

if [ "$mode" = clipboard ]; then
	wl-copy --type image/png < "$temp"
	notify-send "Screenshot copied to clipboard"
else
	image="$dir/screenshot-$(date +%F-%T).png"
	# Preserve the usual filename and keep both captures in a same-second burst.
	if ! ln -T -- "$temp" "$image" 2>/dev/null; then
		image="${image%.png}-${temp##*.}.png"
		mv -T -- "$temp" "$image"
	fi
	if [ "$mode" = region ]; then
		wl-copy --type image/png < "$image"
		notify-send "Screenshot saved & copied" "$image"
	else
		notify-send "Screenshot saved" "$image"
	fi
fi
