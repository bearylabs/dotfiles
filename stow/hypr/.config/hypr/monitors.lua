-- Omarchy's monitor watcher handles hot-plugging and clamshell mode. This
-- fallback accepts any output at its preferred mode and automatic scale.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- The laptop sits to the left of the ultrawide and is vertically centered.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x180", scale = 1 })
hl.monitor({ output = "DP-1", mode = "preferred", position = "1920x0", scale = 1 })

-- Keep the numbered workspaces on the external main display. The laptop panel
-- remains a normal secondary display and owns workspace 10.
for workspace = 1, 9 do
  hl.workspace_rule({ workspace = tostring(workspace), monitor = "DP-1" })
end

hl.workspace_rule({ workspace = "10", monitor = "eDP-1", default = true })
