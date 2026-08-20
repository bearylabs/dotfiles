#!/usr/bin/env bash
#
# CPU and memory readouts, mirroring the load stats in the zebar widget this
# bar is a port of: sampled every 3s, amber from 70%, red from 90%, and only
# the number reacts -- the icon keeps its hue.
#
# Runs as a tail module rather than an interval one because CPU usage is a
# delta between two samples, and keeping the previous sample in a variable
# beats writing it to a file every tick.

set -u

readonly INTERVAL=3

sapphire='#74c7ec'
teal='#94e2d5'
subtext0='#a6adc8'
peach='#fab387'
red='#f38ba8'

# md-memory, despite the name, is the processor die -- which is what the
# widget's CPU SVG draws.
readonly CPU_ICON=$'\U000f035b'  # md-memory
# The memory glyph comes from Font Awesome rather than Material Design: the MD
# candidates are all chip packages, near-identical to the CPU die beside them
# at 11px. This one is a DIMM stick, matching the widget's memory SVG -- a wide
# rounded rect with contact lines and two legs.
readonly MEM_ICON=$''      # fa-memory

case "${1:-}" in
  cpu) icon=$CPU_ICON; colour=$sapphire ;;
  mem) icon=$MEM_ICON; colour=$teal ;;
  *)   printf 'usage: load.sh [cpu|mem]\n' >&2; exit 1 ;;
esac

# Busy and total jiffies since boot; usage is the ratio of their deltas.
cpu_sample() {
  local _ user nice system idle iowait irq softirq steal total
  read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
  total=$((user + nice + system + idle + iowait + irq + softirq + steal))
  printf '%s %s' "$((total - idle - iowait))" "$total"
}

# Used is total minus available, the same figure the widget's provider reports.
mem_usage() {
  awk '/^MemTotal:/ { t = $2 } /^MemAvailable:/ { a = $2 }
       END { printf "%d", (t - a) * 100 / t }' /proc/meminfo
}

# Bands are wide enough that a busy compile does not paint the bar red on
# every tick.
emit() {
  local percent=$1 value=$subtext0

  if ((percent >= 90)); then
    value=$red
  elif ((percent >= 70)); then
    value=$peach
  fi

  # The value is padded to the width of "100%" so the bar never twitches as
  # the number grows a digit.
  printf '%%{O10}%%{T5}%%{F%s}%s%%{F-}%%{T-}%%{O5}%%{F%s}%3d%%%%{F-}\n' \
    "$colour" "$icon" "$value" "$percent"
}

if [[ $1 == mem ]]; then
  while :; do
    emit "$(mem_usage)"
    sleep "$INTERVAL"
  done
fi

read -r prev_busy prev_total < <(cpu_sample)

while :; do
  sleep "$INTERVAL"
  read -r busy total < <(cpu_sample)

  delta=$((total - prev_total))
  ((delta > 0)) && emit $(((busy - prev_busy) * 100 / delta))

  prev_busy=$busy
  prev_total=$total
done
