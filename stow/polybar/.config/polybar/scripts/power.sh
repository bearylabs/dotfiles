#!/usr/bin/env bash
#
# Lock / log out / shut down, mirroring the power controls in the zebar widget
# this bar is a port of, including its inline confirmation.
#
# Polybar modules hold no state, so the two rows are two IPC hooks on one
# custom/ipc module and the buttons switch between them. Polybar has no timers
# either, so the widget's 8s auto-cancel is a guarded background sleep that
# pushes the module back to its resting hook. There is no Esc to cancel --
# polybar takes no keyboard input -- so cancelling means clicking the cross.

set -u

subtext0='#a6adc8'
text='#cdd6f4'
green='#a6e3a1'
red='#f38ba8'

readonly LOCK=$'\U000f0341'    # md-lock_outline
readonly LOGOUT=$'\U000f0343'  # md-logout
readonly POWER=$'\U000f0425'   # md-power
readonly CHECK=$'\U000f012c'   # md-check
readonly CROSS=$'\U000f0156'   # md-close

readonly CONFIRM_TIMEOUT=8
readonly TIMER_PID="${XDG_RUNTIME_DIR:-/tmp}/polybar-powermenu.pid"

readonly LOCK_CMD='loginctl lock-session'
readonly LOGOUT_CMD='i3-msg exit'
readonly SHUTDOWN_CMD='systemctl poweroff'

hook() { printf "polybar-msg action '#powermenu.hook.%s'" "$1"; }

# A button: click action, glyph, colour.
button() {
  printf '%%{A1:%s:}%%{T2}%%{F%s}%s%%{F-}%%{T-}%%{A}' "$1" "$3" "$2"
}

# The timer is its own process group, so the sleep goes with it.
stop_timer() {
  [[ -r $TIMER_PID ]] && kill -- "-$(<"$TIMER_PID")" 2>/dev/null
  rm -f "$TIMER_PID"
  return 0
}

# setsid, because polybar reaps the process group of a hook command once that
# command exits -- a plain background job would be killed long before it fires.
# The redirect keeps the timer off this script's stdout, which polybar reads as
# the module's content and would otherwise wait on.
start_timer() {
  stop_timer
  setsid --fork sh -c \
    "echo \$\$ > '$TIMER_PID'; sleep $CONFIRM_TIMEOUT; $(hook 0)" \
    >/dev/null 2>&1
}

menu() {
  stop_timer

  # The widget spaces these 2px apart, but its buttons are 22px wide boxes
  # around a 14px glyph. Polybar draws the glyph alone, so the gap has to
  # carry the padding those boxes provided.
  printf '%%{O14}'
  button "$LOCK_CMD" "$LOCK" "$subtext0"
  printf '%%{O10}'
  button "$(hook 1)" "$LOGOUT" "$subtext0"
  printf '%%{O10}'
  button "$(hook 2)" "$POWER" "$red"
  printf '%%{O8}\n'
}

confirm() {
  local label=$1 action=$2

  start_timer

  printf '%%{O14}%%{F%s}%s%%{F-}%%{O6}' "$text" "$label"
  button "$(hook 0); $action" "$CHECK" "$green"
  printf '%%{O6}'
  button "$(hook 0)" "$CROSS" "$red"
  printf '%%{O8}\n'
}

case "${1:-}" in
  menu)
    menu
    ;;
  confirm)
    case "${2:-}" in
      logout)   confirm 'Log out?' "$LOGOUT_CMD" ;;
      shutdown) confirm 'Shut down?' "$SHUTDOWN_CMD" ;;
      *)        printf 'usage: power.sh confirm [logout|shutdown]\n' >&2; exit 1 ;;
    esac
    ;;
  *)
    printf 'usage: power.sh [menu|confirm <action>]\n' >&2
    exit 1
    ;;
esac
