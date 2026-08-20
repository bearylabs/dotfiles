#!/usr/bin/env bash
#
# Picks the active output. X only *detects* a hot-plugged DisplayPort sink
# (USB-C monitors and docks show up as DP-*); it never assigns it a mode, so
# without this the monitor sits "connected" in xrandr with the screen dark.
#
# This is a single-screen setup by choice: whenever an external monitor is
# attached it becomes the only enabled output and the laptop panel is switched
# off. i3 migrates the workspaces off an output as it is disabled, so
# everything lands on the monitor on its own, and closing the lid changes
# nothing because the panel was already off.
#
# Run from i3's `exec_always` and from hotplug.sh, so it has to be safe to call
# repeatedly: xrandr is declarative and re-applying the same layout is a no-op.

set -u

readonly INTERNAL=eDP-1

mapfile -t connected < <(xrandr --query | awk '/ connected/ {print $1}')

externals=()
for output in "${connected[@]}"; do
  [[ $output == "$INTERNAL" ]] || externals+=("$output")
done

args=()

if [[ ${#externals[@]} -gt 0 ]]; then
  previous=""
  for output in "${externals[@]}"; do
    args+=(--output "$output" --auto)
    if [[ -z $previous ]]; then
      args+=(--primary)
    else
      # More than one external is not the normal case, but stacking them at
      # 0+0 would leave the extra ones mirrored and unusable.
      args+=(--right-of "$previous")
    fi
    previous=$output
  done
  args+=(--output "$INTERNAL" --off)
else
  args+=(--output "$INTERNAL" --auto --primary)
fi

# Outputs that went away still hold their CRTC until they are explicitly turned
# off, which would otherwise keep the framebuffer sized for a screen that is no
# longer there.
for output in $(xrandr --query | awk '/ disconnected/ {print $1}'); do
  args+=(--output "$output" --off)
done

xrandr "${args[@]}"

# The wallpaper is sized for the framebuffer that was current when feh ran, so
# it has to be repainted after every layout change or it stays at the old
# resolution. --bg-fill scales to cover and crops the overflow, which is what
# fills an ultrawide instead of letter-boxing it.
feh --bg-fill "$HOME/.config/i3/wallpaper.jpg"
