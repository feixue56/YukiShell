-- MacShell owns: SUPER+Z/V/Space/period/L, ALT+TAB, CTRL+ALT+W, PRINT and the hardware keys. Don't rebind those here.
local mod = "SUPER"

hl.bind(mod .. " + Return",         hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + E",              hl.dsp.exec_cmd("dolphin"))
hl.bind(mod .. " + W",              hl.dsp.exec_cmd("chromium"))
hl.bind(mod .. " + Q",              hl.dsp.window.close())
hl.bind(mod .. " + F",              hl.dsp.window.fullscreen())
hl.bind(mod .. " + T",              hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + ALT + space",  hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + ALT + D",      hl.dsp.exec_cmd("~/.config/hypr/bin/dashboard"))
hl.bind(mod .. " + P",              hl.dsp.window.pseudo())
hl.bind(mod .. " + J",              hl.dsp.layout("togglesplit"))

hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + H",     hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + K",     hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + N",     hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    hl.bind(mod .. " + ALT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

hl.bind(mod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })
