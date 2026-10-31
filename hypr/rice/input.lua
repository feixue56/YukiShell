hl.config({
    input = {
        kb_layout    = "us",
        follow_mouse = 1,
        focus_on_close = 1,   -- a closed window hands focus to the window under the pointer (YukiShell: the desktop if none)
        sensitivity  = 0,
        repeat_rate  = 40,
        repeat_delay = 250,
        touchpad = { natural_scroll = true, tap_to_click = true },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
