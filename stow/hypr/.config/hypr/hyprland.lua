-- Hyprland configuration converted from stow/i3/.config/i3/config.
-- Omarchy still provides session services, environment setup, app integration,
-- and its shell; its default keybindings are replaced below.

dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

omarchy_default_bindings = false
require("default.hypr.omarchy")

require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("default.hypr.toggles")
