# hypr-rice
Catppuccin Mocha + mauve/pink rice for Hyprland (Lua config). Standalone: not part of MacShell or its install.sh.
Covers Hyprland (look, input, binds, rules), kitty (glass), fastfetch, btop, cava, fish, GTK 3/4, Qt/KDE.
Palette lives in `hypr/rice/theme.lua`. Install with `./install.sh`.
Note: MacShell's matugen templates can overwrite `gtk.css`; re-run `./install.sh` to restore.

## RiceShell (standalone fork)
`shell/RiceShell` and `shell/RiceLock` are this repo's own copy of MacShell and MacLock, with the motion/dock/menu-bar
tweaks already applied. They run as `qs -c RiceShell` / `qs -c RiceLock`, started by `shell/bin/rice-start` from
`hypr/rice/shell.lua`. Nothing here depends on MacShell's `install.sh` or `macshell-update`, and they never touch it.
MacShell's data files (`~/.config/macbar`, `macdock`, `macshell`) are still shared, since the QML reads those paths.
Env overrides: `~/.config/hypr-rice/env`. Log: `~/.local/state/hypr-rice/RiceShell.log`.
