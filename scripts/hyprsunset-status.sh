#!/bin/sh

if pgrep -x hyprsunset >/dev/null 2>&1; then
	echo '{"text":"󰖔","tooltip":"Hyprsunset Enabled","class":"enabled"}'
else
	echo '{"text":"󰖙","tooltip":"Hyprsunset Disabled","class":"disabled"}'
fi
