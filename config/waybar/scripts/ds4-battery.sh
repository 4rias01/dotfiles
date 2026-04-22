#!/bin/bash

BATTERY_PATH=$(ls /sys/class/power_supply/ | grep "ps-controller-battery")

if [ -z "$BATTERY_PATH" ]; then
    exit 0
fi

CAPACITY=$(cat "/sys/class/power_supply/$BATTERY_PATH/capacity" 2>/dev/null)
STATUS=$(cat "/sys/class/power_supply/$BATTERY_PATH/status" 2>/dev/null)

if [ "$STATUS" = "Charging" ]; then
    ICON="󰨢 "
    CAPACITY=$(( CAPACITY - 20 ))
     # Evitar que baje de 0
    [ "$CAPACITY" -lt 0 ] && CAPACITY=0
elif [ "$STATUS" = "Full" ]; then
    ICON="󰝍 "
elif [ "$CAPACITY" -ge 66 ]; then
    ICON="󰝏 "
elif [ "$CAPACITY" -ge 33 ]; then
    ICON="󰝎 "
else
    ICON="󰝋 "
fi

echo "{\"text\": \"$ICON $CAPACITY%\", \"tooltip\": \"DualShock 4: $CAPACITY% ($STATUS)\", \"class\": \"$STATUS\"}"
