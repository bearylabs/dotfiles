#!/usr/bin/env bash
#
# Starts one bar per connected output, the way the zebar widget this is a port
# of targets every monitor. Run from i3's `exec_always`, so it has to be safe
# to call repeatedly: any previous bar and its script modules are torn down
# first.

set -u

# Matched against the command line rather than the process name: the binary on
# PATH is a wrapper script, so the kernel reports a running bar's comm as
# `.polybar-wrappe` and neither `pkill -x polybar` nor `pgrep -x polybar` ever
# matches one.
readonly BAR='/bin/polybar'

polybar-msg cmd quit >/dev/null 2>&1

# The script modules outlive a plain quit if polybar is killed rather than
# asked to stop. A stale `i3-msg -t subscribe` outlives even that: it sits
# blocked on the i3 socket and only notices its pipe is gone at the next event,
# which can be minutes away.
pkill -f "$BAR" >/dev/null 2>&1
pkill -f "$HOME/.config/polybar/scripts/" >/dev/null 2>&1
pkill -f 'i3-msg -t subscribe' >/dev/null 2>&1

# Let the old bars unmap before the new ones claim the struts, but never block
# i3's startup on one that refuses to die.
for _ in {1..25}; do
  pgrep -f "$BAR" >/dev/null || break
  sleep 0.2
done

for monitor in $(polybar --list-monitors | cut -d: -f1); do
  MONITOR=$monitor polybar --reload main >/dev/null 2>&1 &
done
