-- Match the compact, immediate i3 setup: no gaps, one-pixel square borders,
-- and no compositor animations, shadows, or blur.
hl.config({
  general = {
    gaps_in = 0,
    gaps_out = 0,
    border_size = 1,
    resize_on_border = false,
    layout = "dwindle",
  },
  decoration = {
    rounding = 0,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    fullscreen_opacity = 1.0,
    shadow = { enabled = false },
    blur = { enabled = false },
  },
  animations = {
    enabled = false,
  },
  dwindle = {
    preserve_split = true,
    force_split = 0,
  },
})

-- Omarchy applies a subtle default-opacity window rule. Override it for every
-- window so focused, unfocused, and fullscreen windows are fully opaque.
o.window(".*", { opacity = "1.0 override 1.0 override 1.0 override" })
