#!/bin/sh
# mako-dnd-toggle.sh — Toggle Mako Do Not Disturb mode
# Used by Settings to change the active Mako mode.
case ${1:-toggle} in
	on) flag=-a ;;
	off) flag=-r ;;
	toggle) flag=-t ;;
	*) echo "Usage: $0 [on|off|toggle]" >&2; exit 2 ;;
esac
exec makoctl mode "$flag" do-not-disturb
