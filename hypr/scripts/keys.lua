-- Rebindable keyboard shortcuts.
--
--   local bind = require("scripts.keys").bind
--   bind("SUPER + Return", hl.dsp.exec_cmd("kitty"), "Open Terminal")
--
-- It is hl.bind with a description (the description is the shortcut's name everywhere), and two extras:
--   * what the user picked in System Settings -> Keyboard -> Keyboard Shortcuts replaces the keys given here. Those choices live in
--     ~/.config/yukishell/keybinds.tsv, one "description<TAB>keys" line each; empty keys mean "no shortcut".
--   * every shortcut is written to ~/.cache/yukishell/keybinds.tsv ("description<TAB>default keys<TAB>1 if it can be changed"), the list
--     Settings edits. opts.fixed = true keeps one out of the editor: a group of keys that belong together, or a key the shell itself waits for.
-- Settings writes the choices and runs `hyprctl reload`; nothing else is needed to try a change by hand.
local M = {}

local home = os.getenv("HOME") or ""
local conf = (os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")) .. "/yukishell/keybinds.tsv"
local cache = (os.getenv("XDG_CACHE_HOME") or (home .. "/.cache")) .. "/yukishell/keybinds.tsv"

local overrides, rows = {}, {}

local f = io.open(conf, "r")
if f then
    for line in f:lines() do
        local desc, keys = line:gsub("\r$", ""):match("^([^\t]+)\t(.*)$")
        if desc then overrides[desc] = keys end
    end
    f:close()
end

function M.bind(keys, dispatcher, description, opts)
    opts = opts or {}
    local fixed = opts.fixed
    opts.fixed = nil
    if description then
        rows[#rows + 1] = description .. "\t" .. keys .. "\t" .. (fixed and "0" or "1")
        opts.description = description
        if not fixed and overrides[description] ~= nil then keys = overrides[description] end
    end
    if keys ~= "" then hl.bind(keys, dispatcher, opts) end
end

-- the list Settings reads; call it once, after the last module has bound its keys
function M.flush()
    pcall(os.execute, "mkdir -p '" .. cache:match("^(.*)/[^/]*$") .. "'")
    local out = io.open(cache, "w")
    if not out then return end
    out:write(table.concat(rows, "\n"), "\n")
    out:close()
end

-- Settings switches to this submap while it listens for a new shortcut: no bind of the rice is active in it, so Super+Return and
-- friends reach the Settings window instead of starting a terminal. The one bind in it only gives the submap something to hold.
hl.define_submap("yuki-capture", function()
    hl.bind("SUPER + F24", hl.dsp.no_op())
end)

return M
