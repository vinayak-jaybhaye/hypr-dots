#!/bin/sh

POWER=$(upower -i $(upower -e | grep BAT) | awk '/energy-rate/ {printf "%.1fW", $2}')
echo "$POWER"
