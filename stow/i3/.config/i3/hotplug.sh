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

# i3 re-runs this on every restart (a plain `reload` re-reads the config but
# does not re-run exec_always), so take a lock and give up if a watcher is
# already running. Killing the old one by name instead would be fragile: a
# `pkill -f` pattern broad enough to match the watcher also matches the shell
# i3 spawns to start it, so the new instance would kill itself.
#
# The lock is taken on an explicit descriptor rather than through `flock LOCK
# CMD`, because the lock lives for as long as *any* process holds that file
# open. polybar is started from apply() and outlives the watcher, so it would
# inherit the descriptor and keep the lock held after this process is gone,
# locking out every later instance. apply() closes fd 9 for its children.
exec 9>"$LOCK"
flock --nonblock 9 || exit 0

# The set of sinks the last relayout was made for, so a uevent that leaves it
# unchanged can be dropped.
outputs() {
  xrandr --query | awk '/ connected/ {print $1}' | sort | tr '\n' ' '
}

last=$(outputs)

apply() {
  local current
  current=$(outputs)

  # Resume from suspend re-probes every connector and emits the same drm
  # `change` event a real plug does, so the layout would be torn down and
  # rebuilt on every wakeup: the screen flashes and the bars respawn for
  # nothing. Only act when a sink actually appeared or went away.
  [[ $current == "$last" ]] && return
  last=$current

  "$CONFIG_DIR/displays.sh" 9>&-
  # polybar binds a bar to a named output at startup, so a new or removed
  # screen needs the bars respawned rather than reloaded.
  "$HOME/.config/polybar/launch.sh" 9>&-
}

udevadm monitor --udev --subsystem-match=drm | while read -r _; do
  # A single plug event produces a burst of uevents. Swallow the rest of the
  # burst so the layout is applied once, after the connector has settled.
  sleep 1
  while read -r -t 0.5 _; do :; done
  apply
done
