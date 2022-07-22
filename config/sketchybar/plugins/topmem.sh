#!/usr/bin/env sh

TOPMEM=$(ps axo "rss,ucomm" | sort -nr | tail +1 | head -n1 | awk '{printf "%.0fMB %s\n", $1 / 1024, $2}' | sed -e 's/com.apple.//g')
MEM=$(echo $TOPMEM | sed -nr 's/([^MB]+).*/\1/p')

if [ $MEM -gt 1024 ]; then
  sketchybar --set $NAME label="$TOPMEM" drawing=on
else
  sketchybar --set $NAME drawing=off
fi
