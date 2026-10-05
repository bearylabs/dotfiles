-- Keep keyboard focus stable while the pointer moves, matching i3's
-- focus_follows_mouse no. Clicking still focuses windows normally.
hl.config({
  input = {
    follow_mouse = 0,
    mouse_refocus = false,
    float_switch_override_focus = 0,
    -- Global pointer setting: applies automatically to every connected mouse.
    natural_scroll = true,
    touchpad = {
      natural_scroll = true,
    },
  },
})
