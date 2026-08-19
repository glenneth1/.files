#!/bin/sh
# WeeChat desktop-notification helper, called by the "notify" trigger:
#   /exec -bg ~/.config/weechat/notify.sh "<title>" "<body>"
# Using a wrapper avoids fragile nested quoting inside the trigger and is
# safe for titles/messages containing spaces or shell metacharacters.
notify-send -a WeeChat -i weechat "$1" "$2"

# Sound on highlight/PM (freedesktop theme, with a direct-file fallback).
canberra-gtk-play -i message-new-instant >/dev/null 2>&1 \
  || paplay /usr/share/sounds/freedesktop/stereo/message-new-instant.oga >/dev/null 2>&1
