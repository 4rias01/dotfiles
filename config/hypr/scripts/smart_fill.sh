#!/usr/bin/env bash

wallpaper="$1"
screen_w=1920
screen_h=1080

read wall_w wall_h < <(identify -format "%w %h\n" "$wallpaper")

wall_cross=$(( wall_w * screen_h ))
screen_cross=$(( screen_w * wall_h ))

if (( wall_cross < screen_cross )); then
    mode="fill"
else
    mode="fit"
fi

# Solo reaplica si el modo necesario no es el que ya está en el config
current=$(grep "^fill" ~/.config/waypaper/config.ini | awk -F= '{print tolower($2)}' | tr -d ' ')

if [ "$current" != "$mode" ]; then
    sed -i "s/^fill = .*/fill = $mode/" ~/.config/waypaper/config.ini
    waypaper --wallpaper "$wallpaper" --fill "$mode" --no-post-command
fi
