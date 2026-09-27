#!/usr/bin/env bash
#
# Battery readout, mirroring the one in the zebar widget this bar is a port of:
# amber from 30% down, red from 15% down, and a bolt while the cable is in.
#
# The widget scales the fill inside its icon continuously; polybar draws text,
# so the charge steps through the Material Design battery glyphs instead.
#
# Machines without a battery get nothing rather than a dead 0% readout --
# polybar hides a module whose script prints an empty line.

set -u

green='#a6e3a1'
subtext0='#a6adc8'
peach='#fab387'
red='#f38ba8'

readonly CHARGING=$'\U000f0084'  # md-battery_charging
# md-battery_outline, then _10 through _90, then md-battery.
readonly RAMP=(
  $'\U000f008e' $'\U000f007a' $'\U000f007b' $'\U000f007c' $'\U000f007d'
  $'\U000f007e' $'\U000f007f' $'\U000f0080' $'\U000f0081' $'\U000f0082'
  $'\U000f0079'
)

battery=
for candidate in /sys/class/power_supply/BAT*; do
  [[ -r $candidate/capacity ]] && battery=$candidate && break
done

if [[ -z $battery ]]; then
  printf '\n'
  exit
fi

percent=$(<"$battery/capacity")
status=$(<"$battery/status")

# `Full` still means the cable is in, so it keeps the bolt.
if [[ $status == Charging || $status == Full ]]; then
  glyph=$CHARGING
  icon=$green
  value=$subtext0
else
  glyph=${RAMP[percent / 10]}

  if ((percent <= 15)); then
    icon=$red value=$red
  elif ((percent <= 30)); then
    icon=$peach value=$peach
  else
    icon=$green value=$subtext0
  fi
fi

printf '%%{O10}%%{T5}%%{F%s}%s%%{F-}%%{T-}%%{O5}%%{F%s}%3d%%%%{F-}\n' \
  "$icon" "$glyph" "$value" "$percent"
