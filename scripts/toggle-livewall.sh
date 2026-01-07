#!/bin/sh
if pgrep mpvpaper >/dev/null; then
  pkill mpvpaper
else
  ~/hypr-dots/scripts/livewall.sh &
fi

