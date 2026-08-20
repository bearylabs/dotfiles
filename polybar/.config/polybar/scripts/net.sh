#!/usr/bin/env bash
#
# Link type, signal and address, mirroring the network readout in the zebar
# widget this bar is a port of.
#
# The widget falls back to the negotiated link rate because Windows only hands
# out signal quality to callers allowed to use location services. Here the
# split is cleaner: a radio reports signal, a wired link reports its rate.

set -u

lavender='#b4befe'
overlay1='#7f849c'
subtext0='#a6adc8'
peach='#fab387'
red='#f38ba8'

readonly WIFI=$'\U000f05a9'    # md-wifi
readonly ETHER=$'\U000f0200'   # md-ethernet
readonly OFFLINE=$'\U000f05aa' # md-wifi_off

# APIPA means the adapter is up but never got a lease, so it is not worth
# printing -- same rule as the widget.
address() {
  ip -4 -oneline addr show dev "$1" 2>/dev/null \
    | awk '{ split($4, a, "/"); print a[1] }' \
    | grep -vE '^(169\.254\.|0\.0\.0\.0)' \
    | head -n1
}

# /proc/net/wireless reports link quality out of 70.
signal() {
  awk -v iface="$1:" '$1 == iface { printf "%d", $3 * 100 / 70 }' /proc/net/wireless
}

# Reported in Mb/s, and absent on adapters that do not negotiate a rate.
rate() {
  local mbit
  mbit=$(cat "/sys/class/net/$1/speed" 2>/dev/null) || return
  [[ $mbit =~ ^[0-9]+$ ]] && ((mbit > 0)) || return

  if ((mbit >= 1000)); then
    printf '%s Gb/s' "$((mbit / 1000))"
  else
    printf '%s Mb/s' "$mbit"
  fi
}

emit() {
  # $1 glyph, $2 glyph colour, $3 value, $4 value colour, $5 address,
  # $6 address colour
  printf '%%{O10}%%{T5}%%{F%s}%s%%{F-}%%{T-}' "$2" "$1"
  [[ -n $3 ]] && printf '%%{O5}%%{F%s}%s%%{F-}' "$4" "$3"
  [[ -n $5 ]] && printf '%%{O5}%%{F%s}%s%%{F-}' "$6" "$5"
  printf '\n'
}

iface=$(ip route show default 2>/dev/null | awk '{ print $5; exit }')

if [[ -z ${iface:-} ]]; then
  emit "$OFFLINE" "$red" '' '' offline "$red"
  exit
fi

if [[ -d /sys/class/net/$iface/wireless ]]; then
  quality=$(signal "$iface")

  # Signal reads the same way round as battery: low is the problem. Only the
  # number reacts, as in the load readouts -- the glyph keeps its hue, and the
  # unremarkable case is the same subtext0 the CPU and memory numbers use.
  colour=$subtext0
  if [[ -n $quality ]]; then
    if ((quality <= 25)); then
      colour=$red
    elif ((quality <= 50)); then
      colour=$peach
    fi
  fi

  emit "$WIFI" "$lavender" "${quality:+$(printf '%3d%%' "$quality")}" \
    "$colour" "$(address "$iface")" "$overlay1"
else
  # A link rate is not a quality reading, so it never takes a warning band.
  emit "$ETHER" "$lavender" "$(rate "$iface")" "$overlay1" \
    "$(address "$iface")" "$overlay1"
fi
