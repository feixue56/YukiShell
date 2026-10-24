hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Small utility windows float.
hl.window_rule({ name = "float-pavucontrol", match = { class = "^(org.pulseaudio.pavucontrol|pavucontrol)$" }, float = true })
hl.window_rule({ name = "float-polkit",      match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, float = true })
hl.window_rule({ name = "pip-float",         match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true })


-- Liquid-glass kitty: heavy blur behind a translucent window, frosted white rim instead of the accent border.
hl.window_rule({
    name  = "glass-kitty",
    match = { class = "^(kitty|dash-.*)$" },
    border_color = { colors = { "rgba(ffffff55)", "rgba(cba6f755)", "rgba(ffffff22)" }, angle = 135 },
    opacity  = "1.0 override 1.0 override",
    xray     = false,
    rounding = 20,
})

-- Workspaces 1-10 always exist, so the YukiShell bar shows all ten and Super+scroll can reach any of them.
for i = 1, 10 do
    hl.workspace_rule({ workspace = tostring(i), persistent = true })
end

-- YukiShell Settings: born floating, centred, at its own size (the shell used to float it only after it mapped as a tile).
hl.window_rule({
    name  = "yukishell-settings",
    match = { class = "^org\\.quickshell$", title = "^YukiShell Settings$" },
    float = true,
    center = true,
    size = "800 880",
    min_size = "720 480",    -- below this the panes no longer fit their widest controls (the sidebar alone is 232px)
})
