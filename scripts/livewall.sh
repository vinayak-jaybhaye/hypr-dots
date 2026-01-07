#!/bin/sh

MONITOR="eDP-1"
VIDEO="$HOME/Pictures/live-wallpapers/stone-bridge.mp4"

mpvpaper \
  -o "--loop-file=inf \
      --no-audio \
      --hwdec=auto \
      --vo=gpu \
      --profile=low-latency \
      --scale=bilinear" \
  "$MONITOR" "$VIDEO"
