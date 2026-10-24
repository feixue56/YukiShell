-- YukiShell owns (see shell.lua): SUPER+Z/V/G/L/Space/period/comma, ALT+TAB, CTRL+ALT+W, PRINT (+SHIFT/CTRL) and the hardware keys. Don't rebind those here.
local mod = "SUPER"

-- Every bind with a description is listed, translated, in System Settings → Keyboard → Keyboard Shortcuts (read live from hyprctl).
local function bind(keys, dispatcher, description, opts)
    opts = opts or {}
    opts.description = description
    hl.bind(keys, dispatcher, opts)
end

bind(mod .. " + Return",         hl.dsp.exec_cmd("kitty"), "Open Terminal")
bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd("kitty", { float = true, center = true, size = "900 560" }), "Open a Floating Terminal")   -- floating terminal
bind(mod .. " + E",              hl.dsp.exec_cmd("dolphin"), "Open Files")
bind(mod .. " + W",              hl.dsp.exec_cmd("chromium"), "Open Browser")
bind(mod .. " + SHIFT + E",      hl.dsp.exec_cmd("dolphin", { float = true, center = true, size = "1100 700" }), "Open a Floating Files Window")     -- floating file manager
bind(mod .. " + SHIFT + W",      hl.dsp.exec_cmd("~/.config/hypr/bin/float-chromium"), "Open a Floating Browser Window")                             -- floating browser window (script: a running Chromium ignores exec rules)
bind(mod .. " + Q",              hl.dsp.window.close(), "Close Window")
bind(mod .. " + F",              hl.dsp.window.fullscreen(), "Full Screen")
bind(mod .. " + T",              hl.dsp.window.float({ action = "toggle" }), "Toggle Floating")
hl.bind(mod .. " + ALT + space",  hl.dsp.window.float({ action = "toggle" }))
bind(mod .. " + ALT + D",      hl.dsp.exec_cmd("~/.config/hypr/bin/dashboard"), "Dashboard")
bind(mod .. " + SHIFT + Tab",   hl.dsp.exec_cmd("~/.config/hypr/bin/toggle-opacity"), "Terminal Transparency")
hl.bind(mod .. " + P",              hl.dsp.window.pseudo())
bind(mod .. " + J",              hl.dsp.layout("togglesplit"), "Toggle Split Direction")

bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }), "Move Focus (also → ↑ ↓)")
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + H",     hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + K",     hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + N",     hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }),       i == 1 and "Go to Workspace 1–10 (0 = 10)" or nil)
    bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), i == 1 and "Move Window to Workspace 1–10" or nil)
    hl.bind(mod .. " + ALT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

bind(mod .. " + S",         hl.dsp.workspace.toggle_special("magic"), "Scratchpad")
bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), "Send Window to Scratchpad")

hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })

-- move a tiled window through the layout (swaps it with its neighbour)
for key, dir in pairs({ left = "left", right = "right", up = "up", down = "down" }) do
    bind(mod .. " + SHIFT + " .. key, hl.dsp.window.swap({ direction = dir }), key == "left" and "Swap Window with Neighbour (also → ↑ ↓)" or nil)
end

-- housekeeping: restart the shell cleanly (yuki-restart), reload this Hyprland config
bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("sh ~/.local/bin/yuki-restart"), "Restart YukiShell")
bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprctl reload"), "Reload Hyprland Config")

-- resize the focused window from the keyboard (hold to keep going); tiled windows move the split, floating ones grow/shrink
for key, d in pairs({ left = { -40, 0 }, right = { 40, 0 }, up = { 0, -40 }, down = { 0, 40 } }) do
    bind(mod .. " + CTRL + " .. key, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), key == "left" and "Resize Window (also → ↑ ↓)" or nil, { repeating = true })
end
