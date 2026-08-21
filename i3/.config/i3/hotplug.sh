#!/usr/bin/env bash
#
# Reacts to monitors being plugged in or pulled out.
#
# The kernel fires a `change` uevent on the drm subsystem for the whole card
# (not the individual connector) whenever a sink appears or disappears, so this
# just listens for those and re-runs the layout. `udevadm monitor --udev` reads
# the already-processed event stream, which unprivileged users may open — the
# `--kernel` stream would need root.

set -u

readonly CONFIG_DIR="$HOME/.config/i3"
readonly LOCK="${XDG_RUNTIME_DIR:-/tmp}/i3-hotplug.lock"

# i3 re-runs this on every reload, so re-exec under a lock and give up if a
# watcher is already running. Killing the old one by name instead would be
# fragile: a `pkill -f` pattern broad enough to match the watcher also matches
# the shell i3 spawns to start it, so the new instance would kill itself.
if [[ ${HOTPLUG_LOCKED:-} != 1 ]]; then
  export HOTPLUG_LOCKED=1
  exec flock --nonblock "$LOCK" "$0" "$@"
fi

apply() {
  "$CONFIG_DIR/displays.sh"
  # polybar binds a bar to a named output at startup, so a new or removed
  # screen needs the bars respawned rather than reloaded.
  "$HOME/.config/polybar/launch.sh"
}

udevadm monitor --udev --subsystem-match=drm | while read -r _; do
  # A single plug event produces a burst of uevents. Swallow the rest of the
  # burst so the layout is applied once, after the connector has settled.
  sleep 1
  while read -r -t 0.5 _; do :; done
  apply
done
