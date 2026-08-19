#!/usr/bin/env bash
# preview-url.sh - fetch a remote image and show it inline with kitten icat.
# Invoked by ~/.config/kitty/open-actions.conf when an image link is clicked
# in kitty (works inside WeeChat too: hold ctrl+shift and click the link).
#
# Runs inside a kitty overlay window. kitten icat --hold keeps the image up
# until you press a key, then the overlay closes and the temp file is removed.

set -euo pipefail

url="${1:-}"
if [ -z "$url" ]; then
    echo "preview-url.sh: no URL given"
    read -r -n1 -s
    exit 0
fi

tmp="$(mktemp --suffix=.img)"
trap 'rm -f "$tmp"' EXIT

if curl -fsSL --max-time 30 "$url" -o "$tmp"; then
    kitten icat --hold "$tmp"
else
    printf 'preview-url.sh: failed to fetch %s\n\nPress any key to close.' "$url"
    read -r -n1 -s
fi
