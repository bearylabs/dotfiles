-- i3 keybindings translated to Hyprland's Lua configuration.

local function bind(keys, description, dispatcher, options)
  o.bind(keys, description, dispatcher, options)
end

-- Applications and session control.
bind("SUPER + RETURN", "Terminal", { launch = "ghostty" })
bind("SUPER + SHIFT + Q", "Close window", hl.dsp.window.close())
bind("SUPER + D", "Application launcher", "omarchy menu toggle apps")
bind("SUPER + SHIFT + C", "Reload Hyprland configuration", "hyprctl reload")
-- Hyprland cannot restart in place like i3; a reload is the non-destructive equivalent.
bind("SUPER + SHIFT + R", "Reload Hyprland", "omarchy restart hyprctl")
bind("SUPER + SHIFT + E", "Log out", "omarchy system logout")

-- Focus follows the same Vim home-row and arrow-key layout as i3.
local directions = {
  H = "l",
  J = "d",
  K = "u",
  L = "r",
  LEFT = "l",
  DOWN = "d",
  UP = "u",
  RIGHT = "r",
}

for key, direction in pairs(directions) do
  bind("SUPER + " .. key, "Focus " .. direction, hl.dsp.focus({ direction = direction }))
  bind("SUPER + SHIFT + " .. key, "Move window " .. direction, hl.dsp.window.swap({ direction = direction }))
end

-- Workspaces 1-10 (the zero key selects workspace 10).
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  bind("SUPER + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace,
    hl.dsp.window.move({ workspace = tostring(workspace) }))
end

-- i3 layout concepts mapped to their closest Hyprland equivalents.
bind("SUPER + B", "Next window splits horizontally", hl.dsp.layout("preselect r"))
bind("SUPER + V", "Next window splits vertically", hl.dsp.layout("preselect d"))
bind("SUPER + S", "Toggle stacking-style group", hl.dsp.group.toggle())
bind("SUPER + W", "Toggle tabbed-style group", hl.dsp.group.toggle())
bind("SUPER + E", "Toggle split direction", hl.dsp.layout("togglesplit"))
bind("SUPER + F", "Toggle fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind("SUPER + SHIFT + SPACE", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))
bind("SUPER + SPACE", "Focus next tiled or floating window", hl.dsp.window.cycle_next())
-- Hyprland's dwindle layout has no focusable parent containers; focusmaster is
-- the closest useful equivalent to i3's "focus parent".
bind("SUPER + A", "Focus master window", hl.dsp.layout("focusmaster"))

-- Scratchpad.
bind("SUPER + SHIFT + MINUS", "Move window to scratchpad",
  hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
bind("SUPER + MINUS", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))

-- i3-style resize mode. Enter or Escape returns to the normal keymap.
hl.define_submap("resize", "reset", function()
  local resize = {
    H = { x = -10, y = 0 },
    J = { x = 0, y = 10 },
    K = { x = 0, y = -10 },
    L = { x = 10, y = 0 },
    LEFT = { x = -10, y = 0 },
    DOWN = { x = 0, y = 10 },
    UP = { x = 0, y = -10 },
    RIGHT = { x = 10, y = 0 },
  }

  for key, amount in pairs(resize) do
    hl.bind(key, hl.dsp.window.resize({ x = amount.x, y = amount.y, relative = true }), { repeating = true })
  end

  hl.bind("RETURN", hl.dsp.submap("reset"))
  hl.bind("ESCAPE", hl.dsp.submap("reset"))
end)
bind("SUPER + R", "Resize mode", hl.dsp.submap("resize"))

-- Multimedia keys and utilities.
bind("XF86AudioMute", "Mute audio", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", { locked = true })
bind("XF86AudioLowerVolume", "Volume down", "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-",
  { locked = true, repeating = true })
bind("XF86AudioRaiseVolume", "Volume up", "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+",
  { locked = true, repeating = true })
bind("XF86AudioMicMute", "Mute microphone", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", { locked = true })
bind("XF86MonBrightnessDown", "Brightness down", "brightnessctl set 5%-", { locked = true, repeating = true })
bind("XF86MonBrightnessUp", "Brightness up", "brightnessctl set 5%+", { locked = true, repeating = true })
bind("PRINT", "Region screenshot", "omarchy capture screenshot region")
bind("SUPER + PRINT", "Fullscreen screenshot", "omarchy capture screenshot fullscreen")
bind("SUPER + SHIFT + X", "Lock screen", "omarchy system lock")
bind("SUPER + CTRL + ESCAPE", "Toggle laptop display", "omarchy hyprland monitor internal toggle")

-- Mouse behavior from i3's floating_modifier.
bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })
