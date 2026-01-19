#!/bin/sh

SOURCE=$(pactl get-default-source)
MUTED=$(pactl get-source-mute "$SOURCE" | awk '{print $2}')

if [ "$MUTED" = "yes" ]; then
	echo '{"text":"󰍭","tooltip":"Microphone muted","class":"disabled"}'
else
	echo '{"text":"󰍬","tooltip":"Microphone active","class":"enabled"}'
fi
