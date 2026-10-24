# hypr-rice
Catppuccin Mocha + mauve/pink rice for Hyprland (Lua config). Standalone: not part of MacShell or its install.sh.
Covers Hyprland (look, input, binds, rules), kitty (glass), fastfetch, btop, cava, fish, GTK 3/4, Qt/KDE.
Palette lives in `hypr/rice/theme.lua`. Install with `./install.sh`.
Note: MacShell's matugen templates can overwrite `gtk.css`; re-run `./install.sh` to restore.

## MacShell motion
`macshell/motion.py` retunes the Spotlight pop (spring-like open, softer close). Backs up MacBar.qml once; re-run after macshell-update.
