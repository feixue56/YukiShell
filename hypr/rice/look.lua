local c = require("rice.theme")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("QT_QPA_PLATFORMTHEME", "kde")

hl.config({
    general = {
        gaps_in     = 6,
        gaps_out    = 12,
        border_size = 2,
        col = {
            active_border   = { colors = { c.accent, c.accent2 }, angle = 45 },
            inactive_border = c.muted,
        },
        resize_on_border = true,
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

        blur = {
            enabled  = true,
            size     = 8,
            passes   = 2,
            vibrancy = 0.35,
            noise    = 0.015,
            contrast = 0.95,
            brightness = 0.9,
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

hl.config({ animations = { enabled = true } })
hl.animation({ leaf = "global",        enabled = true, speed = 10,  bezier = "smooth" })
hl.animation({ leaf = "windows",       enabled = true, speed = 5.5, spring = "bounce" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 5.5, spring = "bounce", style = "popin 80%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 3, bezier = "snap",   style = "popin 88%" })
hl.animation({ leaf = "border",        enabled = true, speed = 6,   bezier = "smooth" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3,   bezier = "smooth" })
hl.animation({ leaf = "layers",        enabled = true, speed = 4,   bezier = "snap" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,   bezier = "snap",   style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 2,   bezier = "linear", style = "fade" })
hl.curve("wsSpring", { type = "spring", mass = 1, stiffness = 110, dampening = 19 }) -- softer + slightly underdamped: floats, settles with a tiny drift
hl.animation({ leaf = "workspaces",    enabled = true, speed = 5,   spring = "wsSpring", style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 5,   spring = "wsSpring", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5,   spring = "wsSpring", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, spring = "wsSpring", style = "slidevert" })
