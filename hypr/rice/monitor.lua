-- Pinned in the config so a reload never falls back to the 60 Hz "preferred" mode.
-- Settings -> Displays can pick another resolution / refresh rate: it saves "output<TAB>WxH@Hz" lines in
-- ~/.config/yukishell/monitor-modes.tsv, and those win over the defaults below (same idea as keys.lua).
local home = os.getenv("HOME") or ""
local picked = {}
local f = io.open((os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")) .. "/yukishell/monitor-modes.tsv", "r")
if f then
    for line in f:lines() do
        local out, mode = line:gsub("\r$", ""):match("^([^\t]+)\t(%d+x%d+@[%d.]+)$")
        if out then picked[out] = mode end
    end
    f:close()
end

local pinned = {
    { output = "HDMI-A-1", mode = "1920x1080@100", position = "0x0", scale = 1 },
}
local seen = {}
for _, m in ipairs(pinned) do
    seen[m.output] = true
    hl.monitor({ output = m.output, mode = picked[m.output] or m.mode, position = m.position, scale = m.scale })
end
-- a monitor that isn't pinned above but got a mode in Settings
for out, mode in pairs(picked) do
    if not seen[out] then hl.monitor({ output = out, mode = mode, position = "auto", scale = 1 }) end
end
