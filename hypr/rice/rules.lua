hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Small utility windows float.
hl.window_rule({ name = "float-pavucontrol", match = { class = "^(org.pulseaudio.pavucontrol|pavucontrol)$" }, float = true })
hl.window_rule({ name = "float-polkit",      match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, float = true })
hl.window_rule({ name = "float-utilities",   match = { class = "^(nm-connection-editor|blueman-manager|org\\.gnome\\.Calculator|org\\.kde\\.kcalc|qalculate-gtk|io\\.github\\.Qalculate\\.qalculate-gtk|org\\.kde\\.kdeconnect.*|org\\.gnome\\.Characters)$" }, float = true, center = true })
hl.window_rule({ name = "pip-float",         match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true })

-- File pickers float, centred, instead of tiling next to your work. "Choose a picture", Chromium's Open/Save, Dolphin and the like all
-- go through the desktop portal (xdg-desktop-portal-gtk / -kde); zenity, kdialog and yad are covered too, and so are the GTK/Qt
-- dialogs that name themselves "Open File", "Save As" etc. (Chromium page titles end in " - Chromium", so they never match.)
hl.window_rule({
    name  = "float-file-pickers",
    match = { class = "^(xdg-desktop-portal-gtk|xdg-desktop-portal-kde|org\\.freedesktop\\.impl\\.portal\\.desktop\\.(gtk|kde)|zenity|org\\.gnome\\.Zenity|kdialog|yad)$" },
    float = true,
    center = true,
    size = "1000 680",
})
hl.window_rule({
    name  = "float-file-dialogs",
    match = { title = "^(Open Files?|Open Folder|Save Files?|Save As|Select (a )?([Ff]iles?|[Ff]olders?)|File Upload|Choose Files?|Choose a [Ff]ile)$" },
    float = true,
    center = true,
    size = "1000 680",
})


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

-- Super+Shift+W (hypr/bin/float-chromium): a floating Chromium window, born floating. The rule is off by default; the script
-- switches it on just before it starts the window and off again once the window exists, so other Chromium windows stay tiled.
FLOAT_CHROMIUM_RULE = hl.window_rule({
    name  = "float-chromium-once",
    enabled = false,
    match = { class = "^[Cc]hromium$" },
    float = true,
    center = true,
    size = "1280 800",
})
