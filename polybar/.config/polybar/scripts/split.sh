#!/usr/bin/env bash
#
# Where the next window will open, mirroring the split indicator in the zebar
# widget this bar is a port of.
#
# i3's `split` command is not a pending flag: running it immediately wraps the
# focused window in a new split container. So the focused node's *parent*
# layout is literally the answer to "which way does the next window go".
# Tabbed and stacked have no counterpart in GlazeWM, but i3 has them and there
# the next window is not a spatial split at all, so they get their own glyph.
#
# Clicking toggles the direction. A fullscreen window has no direction to
# change, so it reports state instead and takes no click -- same as the widget.

set -u

overlay0='#6c7086'
peach='#fab387'

readonly SPLIT_H=$''   # cod-split_horizontal -- next window opens right
readonly SPLIT_V=$''   # cod-split_vertical   -- next window opens below
readonly TABBED=$'\U000f04e9'  # md-tab
readonly STACKED=$'\U000f09fe' # md-layers_outline
readonly FULL=$''      # cod-screen_full

# Walks the tree carrying the parent along, and reports the focused node's
# parent layout plus its own fullscreen state.
#
# The node has to be bound to $self before descending: after the `|` the input
# is already the child, so passing `.` there would hand every node itself as
# its own parent -- and the answer would always be the leaf's own layout.
# shellcheck disable=SC2016  # $parent and $self are jq bindings, not shell.
readonly QUERY='
  def walk($parent):
    (if .focused then { layout: ($parent.layout // "splith"), full: .fullscreen_mode }
     else empty end),
    (. as $self | (.nodes[]?, .floating_nodes[]?) | walk($self));
  walk(null) | "\(.layout) \(.full)"
'

build() {
  local layout full glyph

  read -r layout full < <(i3-msg -t get_tree | jq -r "$QUERY" | head -n1)

  if [[ -z ${layout:-} ]]; then
    return
  fi

  if [[ $full != 0 ]]; then
    # No tiling direction to change while fullscreen, so the glyph reports
    # state and carries no click region.
    printf '%%{O8}%%{T2}%%{F%s}%s%%{F-}%%{T-}%%{O8}' "$peach" "$FULL"
    return
  fi

  case $layout in
    splitv)  glyph=$SPLIT_V ;;
    tabbed)  glyph=$TABBED ;;
    stacked) glyph=$STACKED ;;
    *)       glyph=$SPLIT_H ;;
  esac

  printf '%%{O8}%%{A1:i3-msg split toggle:}%%{T2}%%{F%s}%s%%{F-}%%{T-}%%{A}%%{O8}' \
    "$overlay0" "$glyph"
}

# Only print when something actually changed, so the backstop tick below costs
# polybar nothing on the overwhelming majority of ticks.
last=
render() {
  local next
  next=$(build)

  if [[ $next != "$last" ]]; then
    last=$next
    printf '%s\n' "$next"
  fi
}

render

# Keybindings, new windows and focus moves all surface as one of these events,
# which covers every ordinary way the direction changes.
#
# `split` run any other way -- i3-msg, or this module's own click handler --
# emits no event at all, so a slow tick backstops it. Everything it catches is
# already on screen within a second, and an unchanged tick prints nothing.
{
  while :; do printf '\n'; sleep 1; done &
  i3-msg -t subscribe -m '["window","workspace","binding","mode"]'
} | while read -r _; do render; done
