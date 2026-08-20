#!/usr/bin/env bash
#
# Starts one bar per connected output, the way the zebar widget this is a port
# of targets every monitor. Run from i3's `exec_always`, so it has to be safe
# to call repeatedly: any previous bar and its script modules are torn down
# first.

set -u

polybar-msg cmd quit >/dev/null 2>&1

# The script modules outlive a plain quit if polybar is killed rather than
# asked to stop, and a stale `i3-msg -t subscribe` would keep a dead pipe open.
pkill -x polybar >/dev/null 2>&1
pkill -f "$HOME/.config/polybar/scripts/" >/dev/null 2>&1

while pgrep -x polybar >/dev/null; do sleep 0.2; done

for monitor in $(polybar --list-monitors | cut -d: -f1); do
  MONITOR=$monitor polybar --reload main >/dev/null 2>&1 &
done
