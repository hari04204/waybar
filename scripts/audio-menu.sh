#!/usr/bin/env bash
MENU=(fuzzel --dmenu --anchor top-right --x-margin 10 --y-margin 34 --width 38 --lines 8)

default=$(pactl get-default-sink)
vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oE '[0-9]+%' | head -1)

devices=$(pactl --format=json list sinks \
  | jq -r --arg d "$default" '.[] | (if .name==$d then "● " else "  " end) + .description')

choice=$(printf '%s\n%s\n%s\n%s' "$devices" "  🔊 Volume up ($vol)" "  🔉 Volume down" "  🔇 Toggle mute" \
  | "${MENU[@]}" --prompt "Output  ")

[ -z "$choice" ] && exit 0

case "$choice" in
  *"Volume up"*)   pactl set-sink-volume @DEFAULT_SINK@ +5%; exit 0 ;;
  *"Volume down"*) pactl set-sink-volume @DEFAULT_SINK@ -5%; exit 0 ;;
  *"Toggle mute"*) pactl set-sink-mute @DEFAULT_SINK@ toggle; exit 0 ;;
esac

desc=$(printf '%s' "$choice" | sed 's/^..//')
name=$(pactl --format=json list sinks \
  | jq -r --arg d "$desc" '.[] | select(.description==$d) | .name')

[ -z "$name" ] && exit 1
pactl set-default-sink "$name"
# Move anything already playing to the new device
pactl list short sink-inputs | cut -f1 | while read -r id; do
  pactl move-sink-input "$id" "$name"
done
notify-send "Audio" "Output: $desc"