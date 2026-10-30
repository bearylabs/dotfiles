-- OpenWhispr's recording pill runs under XWayland and positions itself from a
-- stale cursor position, so it tends to stay on the laptop screen. Let Hyprland
-- place it bottom-center on the monitor it opens on (the focused one).
o.window({ class = "^open-whispr$", title = "^Voice Recorder$" }, {
  move = { "(monitor_w*0.5-window_w*0.5)", "(monitor_h-window_h-40)" },
})
