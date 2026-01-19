#!/bin/sh

if makoctl mode | grep -q do-not-disturb; then
	echo '{"text":"󰂛","class":"enabled","tooltip":"Do Not Disturb enabled"}'
else
	echo '{"text":"󰂚","class":"disabled","tooltip":"Notifications enabled"}'
fi
