#!/bin/sh
# mic.sh — Microphone mute status for Waybar
# Purpose: Outputs JSON indicating whether the default audio source (mic) is muted.
# Called by: Could be used as a Waybar custom module (not currently wired in modules/)
# Output: JSON with text (icon), tooltip, and class
# Dependencies: pactl (PipeWire/PulseAudio)

SOURCE=$(pactl get-default-source)
MUTED=$(pactl get-source-mute "$SOURCE" | awk '{print $2}')

if [ "$MUTED" = "yes" ]; then
	echo '{"text":"󰍭","tooltip":"Microphone muted","class":"disabled"}'
else
	echo '{"text":"󰍬","tooltip":"Microphone active","class":"enabled"}'
fi
