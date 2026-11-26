#!/bin/sh
# hyprsunset-toggle.sh — Toggle night mode (hyprsunset) on/off
# Purpose: Kills hyprsunset if running, starts it if not.
# Called by: Settings and the session login hook
# Dependencies: hyprsunset, procps-ng, flock, timeout

set -eu
: "${WAYLAND_DISPLAY:?Wayland session required}"
uid=$(id -u)
display="WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
running() {
	pgrep -u "$uid" --env "$display" -x hyprsunset >/dev/null && return 0
	rc=$?
	[ "$rc" -eq 1 ] || exit "$rc"
	return 1
}

case ${1:-toggle} in
	status) if running; then echo on; else echo off; fi; exit ;;
	on|off|toggle) ;;
	*) echo "Usage: $0 [on|off|toggle|status]" >&2; exit 2 ;;
esac

# Serialize login and Settings changes. The daemon must release the lock FD.
exec 9>"${XDG_RUNTIME_DIR:?}/hypr-dots-night-light.lock"
flock 9
if running; then
	if [ "${1:-toggle}" != on ]; then
		pkill -u "$uid" --env "$display" -x hyprsunset || [ "$?" -eq 1 ]
		timeout 2 pidwait -u "$uid" --env "$display" -x hyprsunset || [ "$?" -eq 1 ] || {
			echo "Could not stop hyprsunset in time" >&2
			exit 1
		}
	fi
elif [ "${1:-toggle}" != off ]; then
	hyprsunset 9>&- </dev/null >/dev/null 2>&1 &
	pid=$!
	sleep 0.1
	kill -0 "$pid" 2>/dev/null || { echo "Could not start hyprsunset" >&2; exit 1; }
fi
