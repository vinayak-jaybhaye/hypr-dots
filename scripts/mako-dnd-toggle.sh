#!/bin/sh
# mako-dnd-toggle.sh — Toggle Mako Do Not Disturb mode
# Purpose: Toggles DND mode via makoctl, then signals waybar for instant update.
# Called by: Waybar on-click (custom/dnd) + keybind in keybinds.conf
# Signal: Sends RTMIN+3 to waybar after toggle.
# Dependencies: makoctl, waybar
makoctl mode -t do-not-disturb
pkill -RTMIN+3 waybar
