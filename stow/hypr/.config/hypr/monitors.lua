-- Omarchy's monitor watcher handles hot-plugging and clamshell mode. This
-- fallback accepts any output at its preferred mode and automatic scale.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- The laptop sits to the left of the ultrawide and is vertically centered.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x180", scale = 1 })
hl.monitor({ output = "DP-1", mode = "preferred", position = "1920x0", scale = 1 })

-- Select workspace rules dynamically, including after monitor hot-plugging.
local numbered_rules = {}
local secondary_rule = hl.workspace_rule({
  workspace = "10", monitor = "eDP-1", default = true, enabled = false,
})

local previous_target
local function sync_workspaces()
  local laptop = hl.get_monitor("eDP-1")
  local external = hl.get_monitor("DP-1")
  -- Also support an external screen connected through a different output.
  if not external then
    for _, monitor in ipairs(hl.get_monitors()) do
      if monitor.name ~= "eDP-1" then external = monitor; break end
    end
  end
  local target = external and external.name or (laptop and laptop.name)
  if not target then return end

  secondary_rule:set_enabled(external ~= nil and laptop ~= nil)
  local layout = target .. (laptop and ":laptop" or ":no-laptop")
  if layout == previous_target then return end
  previous_target = layout
  for _, rule in ipairs(numbered_rules) do rule:set_enabled(false) end
  numbered_rules = {}
  for workspace = 1, 9 do
    numbered_rules[workspace] = hl.workspace_rule({
      workspace = tostring(workspace), monitor = target,
      default = not external and workspace == 1,
    })
  end

  local active = hl.get_active_workspace()
  local restore = active and active.name
  for _, workspace in ipairs(hl.get_workspaces()) do
    if workspace.id >= 1 and workspace.id <= 9 then
      hl.dispatch(hl.dsp.workspace.move({ workspace = workspace.name, monitor = target }))
    end
  end

  if external and laptop then
    hl.dispatch(hl.dsp.focus({ workspace = "10" }))
    if restore and restore ~= "10" then
      hl.dispatch(hl.dsp.focus({ workspace = restore }))
    end
  elseif not external then
    -- Retire workspace 10 without closing any of its windows.
    for _, window in ipairs(hl.get_workspace_windows("10")) do
      hl.dispatch(hl.dsp.window.move({
        window = "address:" .. window.address, workspace = "1", follow = false,
      }))
    end
    if not restore or restore == "10" then
      hl.dispatch(hl.dsp.focus({ workspace = "1" }))
    end
  end
end

-- Defer reconciliation until Hyprland has finished changing its monitor layout.
local sync_timer = hl.timer(sync_workspaces, { timeout = 300, type = "oneshot" })
local function schedule_sync()
  sync_timer:set_timeout(300)
  sync_timer:set_enabled(true)
end
hl.on("monitor.added", schedule_sync)
hl.on("monitor.removed", schedule_sync)
hl.on("monitor.layout_changed", schedule_sync)
hl.on("hyprland.start", schedule_sync)
