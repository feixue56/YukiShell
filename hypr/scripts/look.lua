local c = require("scripts.theme")

-- The cursor: Settings -> Cursor saves its theme and size in ~/.config/yukishell/cursor (two lines), read here at login.
local cursorTheme, cursorSize = "Bibata-Modern-Classic", "24"
do
    local f = io.open((os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/yukishell/cursor", "r")
    if f then
        local t, s = f:read("l"), f:read("l")
        f:close()
        if t and t ~= "" then cursorTheme = t end
        if s and tonumber(s) then cursorSize = s end
    end
end
hl.env("XCURSOR_SIZE", cursorSize)
hl.env("HYPRCURSOR_SIZE", cursorSize)
hl.env("XCURSOR_THEME", cursorTheme)
hl.env("HYPRCURSOR_THEME", cursorTheme)
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")   -- Qt apps (Dolphin ...): Catppuccin colours, Breeze, Papirus (qt/qt6ct, set up by install.sh); no Plasma needed

hl.config({
    general = {
        gaps_in     = 6,
        gaps_out    = 12,
        border_size = 1,     -- Settings -> Desktop & Dock -> Windows -> Border thickness overrides it
        col = {
            active_border   = { colors = { c.accent, c.accent2 }, angle = 45 },
            inactive_border = c.muted,
        },
        resize_on_border = true,
        extend_border_grab_area = 20,   -- easier to grab the edge of a window to resize it
        snap = {                        -- floating windows snap to the screen edges and to each other while moving / resizing
            enabled      = true,
            window_gap   = 12,
            monitor_gap  = 12,
            respect_gaps = true,
        },
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 16,
        rounding_power = 3, -- squircle-ish corners, closer to macOS
        active_opacity   = 1.0,
        inactive_opacity = 0.94,

        shadow = {
            enabled      = true,
            range        = 24,
            render_power = 3,
            color        = c.shadow,
        },

        -- matched to YukiShell's Liquid Glass (the Dock / widgets): a light blur (size 4, one pass) that keeps the wallpaper's shapes, a little
        -- extra colour and no darkening, so translucent windows (kitty) read as the same clear glass
        blur = {
            enabled  = true,
            size     = 4,
            passes   = 1,
            vibrancy = 0.5,
            noise    = 0.015,
            contrast = 1.0,
            brightness = 1.0,
            popups   = true,
            new_optimizations = true,
        },
    },

    dwindle = { preserve_split = true },
    master  = { new_status = "master" },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
    },

    cursor = { hide_on_key_press = true, inactive_timeout = 5 },
})

-- Animations: springy windows, soft fades, quick layers.
hl.curve("smooth",  { type = "bezier", points = { {0.22, 1},   {0.36, 1}   } })
hl.curve("snap",    { type = "bezier", points = { {0.16, 1},   {0.3, 1}    } })
hl.curve("linear",  { type = "bezier", points = { {0, 0},      {1, 1}      } })
hl.curve("bounce",  { type = "spring", mass = 1, stiffness = 140, dampening = 17 })
hl.curve("glide",   { type = "spring", mass = 1, stiffness = 170, dampening = 26 }) -- critically damped: resizes/moves never overshoot, so app contents never lag behind the frame
hl.curve("pop",     { type = "spring", mass = 1, stiffness = 190, dampening = 21 }) -- open: fast, one soft overshoot
hl.curve("fadeIO",  { type = "bezier", points = { {0.25, 0.1}, {0.25, 1} } })
hl.curve("exit",    { type = "bezier", points = { {0.4, 0},    {1, 1}    } })

hl.config({ animations = { enabled = true } })
hl.animation({ leaf = "global",        enabled = true, speed = 10,  bezier = "smooth" })
hl.animation({ leaf = "windows",       enabled = true, speed = 5.5, spring = "glide" })
-- moving / resizing (tile <-> float, layout changes): a short curve with a definite end. The spring above takes ~0.7 s to settle and
-- its last few pixels crept along one by one, so apps that re-lay-out on every size (Chromium, Electron) kept resizing their
-- toolbar after the frame had visibly arrived. 0.35 s, no tail: the app gets fewer sizes and catches up with the frame.
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 3.5, bezier = "snap" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 5.5, spring = "pop", style = "popin 72%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 3.2, bezier = "exit", style = "popin 92%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 3.6, bezier = "fadeIO" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 2.6, bezier = "exit" })
hl.animation({ leaf = "fadeShadow",    enabled = true, speed = 4,   bezier = "fadeIO" })
hl.animation({ leaf = "fadeDim",       enabled = true, speed = 4,   bezier = "fadeIO" })
hl.animation({ leaf = "border",        enabled = true, speed = 6,   bezier = "smooth" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3,   bezier = "smooth" })
hl.animation({ leaf = "layers",        enabled = true, speed = 4,   bezier = "snap" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,   bezier = "snap",   style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 2,   bezier = "linear", style = "fade" })
hl.curve("wsSpring", { type = "spring", mass = 1, stiffness = 110, dampening = 21 }) -- critically damped (2·√110 ≈ 21): slides in and stops. Underdamped (19) overshot and crept back after every slide, so floating windows seemed to move by themselves
hl.animation({ leaf = "workspaces",    enabled = true, speed = 5,   spring = "wsSpring", style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 5,   spring = "wsSpring", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5,   spring = "wsSpring", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, spring = "wsSpring", style = "slidevert" })
