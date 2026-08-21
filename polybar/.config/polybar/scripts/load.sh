#!/usr/bin/env bash
#
# CPU, memory and disk readouts, mirroring the load stats in the zebar widget
# this bar is a port of: amber from 70%, red from 90%, and only the number
# reacts -- the icon keeps its hue.
#
# CPU is a tail module polling every 3s because its usage is a delta between
# two samples, and keeping the previous sample in a variable beats writing it
# to a file every tick. Memory rides the same loop for simplicity. Disk fills
# slowly, so it polls on its own, much slower loop instead.

set -u

readonly INTERVAL=3
readonly DISK_INTERVAL=60

sapphire='#74c7ec'
teal='#94e2d5'
blue='#89b4fa'
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
readonly DISK_ICON=$'\U000f02ca' # md-harddisk

case "${1:-}" in
  cpu)  icon=$CPU_ICON;  colour=$sapphire ;;
  mem)  icon=$MEM_ICON;  colour=$teal ;;
  disk) icon=$DISK_ICON; colour=$blue ;;
  *)    printf 'usage: load.sh [cpu|mem|disk]\n' >&2; exit 1 ;;
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

# Used is total minus available blocks on the root filesystem, df's own math.
disk_usage() {
  df -P / | awk 'NR == 2 { gsub("%", "", $5); printf "%d", $5 }'
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

if [[ $1 == disk ]]; then
  while :; do
    emit "$(disk_usage)"
    sleep "$DISK_INTERVAL"
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
