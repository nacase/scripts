#!/bin/sh
#
# move X Window id $1 to current desktop and then raise it
#
# find window ID with "xwininfo -tree -root" or similar
#

usage() {
    >&2 echo "usage: $0 <X window ID>"
    >&2 echo ""
    >&2 echo "Find X window ID with 'xwininfo -tree -root' or similar"
    exit 1
}

[ -n "$1" ] || usage

# 0-based desktop number
CUR_DESKTOP=$(xdotool get_desktop)

xdotool set_desktop_for_window "$1" "${CUR_DESKTOP}"
xdotool windowraise "$1"
xdotool windowactivate "$1"
