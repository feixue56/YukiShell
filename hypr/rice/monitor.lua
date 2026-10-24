-- Pinned in the config so a reload never falls back to the 60 Hz "preferred" mode.
-- (MacShell's Display settings write ~/.config/macshell/displays.json and apply it at runtime only.)
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080@100",
    position = "0x0",
    scale    = 1,
})
