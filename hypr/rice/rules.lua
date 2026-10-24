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

-- Workspaces 1-10 always exist, so the MacShell bar shows all ten and Super+scroll can reach any of them.
for i = 1, 10 do
    hl.workspace_rule({ workspace = tostring(i), persistent = true })
end

-- YukiShell Settings: born floating, centred, at its own size (the shell used to float it only after it mapped as a tile).
hl.window_rule({
    name  = "yukishell-settings",
    match = { class = "^org\\.quickshell$", title = "^macshell Settings$" },
    float = true,
    center = true,
    size = "800 880",
})

-- Apps made see-through with Super+Shift+Tab (hypr/bin/toggle-opacity keeps this list, one window class per line).
-- Hyprland can only fade a whole window, text included: kitty is handled separately and never ends up here.
do
    local f = io.open(os.getenv("HOME") .. "/.config/hypr-rice/transparent-apps.txt")
    if f then
        for cls in f:lines() do
            if cls ~= "" then
                hl.window_rule({
                    name    = "yuki-transparent-" .. cls,
                    match   = { class = "^" .. cls:gsub("%p", "\\%0") .. "$" },
                    opacity = "0.8 0.8",
                })
            end
        end
        f:close()
    end
end
