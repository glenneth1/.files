#!/usr/bin/env bash
#
# weechat-modern.sh - apply (or print) a modern WeeChat look/feel + scripts.
#
# This is the single source of truth for the WeeChat customization. Keep it in
# version control. It is idempotent: running it again just re-applies the same
# settings.
#
# Usage:
#   ./weechat-modern.sh           Apply to a RUNNING WeeChat via its FIFO pipe.
#   ./weechat-modern.sh --print   Print the raw /commands (paste into WeeChat,
#                                 or use on a brand-new install).
#
# Notes:
#   * Designed for kitty (Nerd Font glyphs + color emoji + inline images).
#     Run WeeChat inside kitty: `kitty -e weechat`.
#   * The FIFO pipe must be enabled (it is by default). If the script cannot
#     find it, run this inside WeeChat:  /set fifo.file.enabled on
#   * Color numbers are 256-color codes; with kitty you may also use hex,
#     e.g. ${color:#89b4fa}. Tweak to match your theme.

set -euo pipefail

# --- desktop-notification helper -------------------------------------------
# The "notify" trigger (below) calls this wrapper instead of inlining
# notify-send, which keeps quoting sane and is safe for messages containing
# spaces or shell metacharacters.
notify_helper="$HOME/.config/weechat/notify.sh"
if [[ ! -x "$notify_helper" ]]; then
  cat > "$notify_helper" <<'SH'
#!/bin/sh
notify-send -a WeeChat -i weechat "$1" "$2"
canberra-gtk-play -i message-new-instant >/dev/null 2>&1 \
  || paplay /usr/share/sounds/freedesktop/stereo/message-new-instant.oga >/dev/null 2>&1
SH
  chmod +x "$notify_helper"
fi

# --- weemoji (emoji :shortcode: completion) --------------------------------
# kattrali/weemoji is a single self-contained Python script that is NOT in the
# official WeeChat script repo, so `/script install` cannot find it. Fetch it
# once and symlink into python/autoload so it loads on every start.
weechat_data="$HOME/.local/share/weechat"
weemoji="$weechat_data/python/weemoji.py"
if [[ ! -f "$weemoji" ]]; then
  mkdir -p "$weechat_data/python/autoload"
  if curl -fsSL https://raw.githubusercontent.com/kattrali/weemoji/master/weemoji.py -o "$weemoji"; then
    ln -sf ../weemoji.py "$weechat_data/python/autoload/weemoji.py"
  else
    echo "warning: could not download weemoji.py (no network?); skipping." >&2
    rm -f "$weemoji"
  fi
fi

# --- configuration, expressed as WeeChat commands --------------------------
# Entries are SINGLE-quoted so the shell does not touch WeeChat's ${...} eval
# syntax. The double quotes inside values are part of the WeeChat command and
# are required to preserve leading/trailing spaces.
commands=(
  # ---- general look ----
  '/mouse enable'
  '/set weechat.look.prefix_align_max 16'
  '/set weechat.look.prefix_suffix "│"'
  '/set weechat.look.buffer_time_format "${color:240}%H:%M"'
  '/set weechat.look.separator_horizontal ""'
  '/set weechat.look.prefix_same_nick "↳"'
  '/set weechat.look.align_end_of_lines message'
  '/set weechat.look.prefix_join "→"'
  '/set weechat.look.prefix_quit "←"'
  '/set weechat.look.read_marker_always_show on'
  '/set weechat.look.bar_more_down "▼"'
  '/set weechat.look.bar_more_up "▲"'

  # ---- colors ----
  '/set weechat.color.chat_prefix_join 73'
  '/set weechat.color.chat_prefix_quit 131'
  '/set weechat.color.chat_nick_colors "31,73,75,110,139,141,168,175,210,212,114,180"'
  '/set weechat.color.chat_read_marker 130'
  '/set weechat.look.color_nick_offline on'
  '/set weechat.color.chat_nick_offline 244'
  '/set weechat.color.separator 237'
  '/set weechat.color.status_count_highlight 203'
  '/set weechat.color.status_name 110'

  # ---- bars ----
  '/set weechat.bar.title.color_bg 236'
  '/set weechat.bar.status.color_bg 236'
  '/set weechat.bar.status.color_fg 250'
  '/set weechat.bar.input.color_bg 234'
  '/set weechat.bar.nicklist.color_bg 235'

  # ---- completion ----
  # Add weemoji's "emoji_names" completer to the default Tab-completion template
  # so typing ":smi<Tab>" in the input bar completes to ":smile:" (etc.).
  # Keep the built-in nick/channel completers too.
  '/set weechat.completion.default_template "%(nicks)|%(irc_channels)|%(emoji_names)"'

  # ---- irc look ----
  '/set irc.look.color_nicks_in_names on'
  '/set irc.look.color_nicks_in_server_messages on'
  '/set irc.look.smart_filter on'

  # ---- buflist (sidebar) ----
  '/set buflist.look.enabled on'
  # Group buffers by network, server buffer first, channels alphabetical.
  # Uses buflist's built-in IRC fields (no ${...} eval, so it is safe).
  '/set buflist.look.sort "irc_server.name,irc_channel.type,~name"'
  '/set buflist.format.indent "${color:237}│ "'
  '/set buflist.format.buffer_current "${color:236,73} ${format_buffer} "'
  '/set buflist.format.hotlist " ${color:green}${hotlist}"'
  # Per-type Nerd Font icons. These are SEQUENTIAL, single-level ${if:} blocks
  # (not nested), each self-contained, so exactly one matches per buffer and
  # WeeChat's eval never sees an ambiguous branch. ${type} is server/channel/
  # private for IRC buffers. Swap the glyphs below to taste (any Nerd Font):
  #   = nf-fa-server (U+F233)   = nf-fa-hashtag (U+F292)   = nf-fa-user (U+F007)
  '/set buflist.format.buffer "${format_number}${indent}${format_nick_prefix}${color_hotlist}${if:${type}==server?${color:31} }${if:${type}==channel?${color:109} }${if:${type}==private?${color:175} }${if:${hotlist}?${color_hotlist}}${format_name}"'

  # ---- smart join/part/quit filtering ----
  '/filter add irc_smart * irc_smart_filter *'

  # ---- desktop notifications via native trigger (replaces notify_send.pl) ----
  # Calls the wrapper ~/.config/weechat/notify.sh (created above) to avoid
  # fragile nested quoting and stay safe with spaces/metachars in messages.
  # NOTE: no "--" after -bg; WeeChat /exec parses its own options and "--" breaks it.
  "/trigger addreplace notify print \"\" \"\${tg_displayed} && (\${tg_highlight} || \${tg_msg_pv}) && \${tg_tags} !!- ,notify_none,\" \"\" \"/exec -bg $HOME/.config/weechat/notify.sh '\${buffer.short_name}' '\${tg_prefix}: \${tg_message}'\""

  # ---- scripts ----
  # Refresh the script repo index first; otherwise installs can silently no-op
  # if the local plugins.xml.gz cache is stale or missing.
  '/script update'
  '/script install colorize_nicks.py'
  '/script install autosort.py'
  '/script install go.py'
  '/script install buffer_autoset.py'
  '/script install highmon.pl'
  # NOTE: iset.pl was REMOVED from the script repo (deprecated). WeeChat 4.x has
  # a built-in fast-set browser: use /fset instead.
  # NOTE: emoji support is provided by kattrali/weemoji (weemoji.PY, a Python
  # script that is NOT in the official repo, so /script install cannot find it).
  # It is fetched + symlinked into python/autoload by the shell block above;
  # this load makes it active immediately on a live run.
  '/script load weemoji.py'
  # REMOVED: notify_send.pl - on connect it spammed the buffer with eval
  # errors ("Invalid number of options") + a hotlist dump. Use a trigger or
  # the desktop-notification approach below instead.
  # NOTE: colorize_lines.py and autojoin.py do not exist in the script repo.
  # WeeChat 4.x has autojoin built in: join your channels, then run
  #   /autojoin --run     (apply) and  /autojoin save  (persist per server).

  # ---- persist everything ----
  '/save'
)

# --- print mode ------------------------------------------------------------
if [[ "${1:-}" == "--print" ]]; then
  printf '%s\n' "${commands[@]}"
  exit 0
fi

# --- locate the running WeeChat FIFO pipe ----------------------------------
fifo=""
for candidate in \
  "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/weechat"/weechat_fifo* \
  "$HOME/.local/state/weechat"/weechat_fifo* \
  "$HOME/.local/share/weechat"/weechat_fifo* \
  "$HOME/.config/weechat"/weechat_fifo*; do
  if [[ -p "$candidate" ]]; then
    fifo="$candidate"
    break
  fi
done

if [[ -z "$fifo" ]]; then
  echo "No WeeChat FIFO pipe found." >&2
  echo "Is WeeChat running? If so, enable the pipe inside WeeChat:" >&2
  echo "    /set fifo.file.enabled on" >&2
  echo "Then re-run this script. Or paste the commands manually:" >&2
  echo "    $0 --print" >&2
  exit 1
fi

# --- stream commands into WeeChat ------------------------------------------
# FIFO line format: '*<text>' sends <text> to the core buffer; a leading '/'
# makes it a command.
for cmd in "${commands[@]}"; do
  printf '*%s\n' "$cmd" > "$fifo"
done

echo "Applied ${#commands[@]} commands to WeeChat via:"
echo "    $fifo"
