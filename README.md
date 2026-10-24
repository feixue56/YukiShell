# YukiShell

A Catppuccin Mocha (mauve + pink) rice for **Hyprland** with its own desktop shell, built on **Quickshell**.

- **YukiShell**: menu bar, dock, Spotlight, Control Center, widgets, notifications and a Settings app
- **YukiLock**: the lock screen
- The Hyprland config (Lua), kitty, fish, fastfetch, btop, cava, GTK 3/4 and Qt/KDE themes to match

YukiShell is a fork of [MacShell](https://github.com/0-ss/MacShell) by Rickky and vSuol (MIT). It is completely separate from
upstream: it has its own name, config path, installer and Settings app, and it never phones home to MacShell.

Made by [Phong (@feixue56)](https://github.com/feixue56).

## Install

Needs Hyprland with the **Lua config** (written and tested on 0.56.2, CachyOS, NVIDIA) and Quickshell.

```sh
git clone https://github.com/feixue56/YukiShell.git ~/hypr-rice
cd ~/hypr-rice && ./install.sh
```

`install.sh` symlinks the files into `~/.config` (anything already there is moved to `*.pre-rice` once), adds one `require`
line to `~/.config/hypr/hyprland.lua`, and sets the GTK/Qt/btop themes. Re-run it any time; it is idempotent.

Packages the rice expects: `kitty fish fastfetch btop cava tty-clock fcitx5 fcitx5-bamboo adw-gtk-theme papirus-icon-theme
plasma-integration ddcutil brightnessctl` and the Bibata cursor and JetBrainsMono Nerd Font. The shell itself uses `nmcli`, `playerctl`,
`powerprofilesctl`, `grim`, `wl-clipboard` and `hyprsunset` for the matching features; whatever is missing just disables that feature.

Before using it, check:

- `hypr/rice/monitor.lua`: resolution and refresh rate (it is pinned to 1920x1080@100 for my monitor)
- `fastfetch/config.jsonc`: `logo.source` points at a personal picture that is not in this repo; change it or remove the image

## Keybinds

`Super` is the main modifier.

| Keys | Action |
| --- | --- |
| `Super+Enter` | terminal (kitty) |
| `Super+Shift+Enter` | floating terminal |
| `Super+W` / `Super+E` | Chromium / Dolphin |
| `Super+Q` | close window |
| `Super+F` | fullscreen |
| `Super+T` or `Super+Alt+Space` | toggle floating |
| `Super+Shift+Tab` | terminal opacity: solid → liquid glass → completely transparent |
| `Super+Alt+D` | dashboard (fastfetch, clock, cava) |
| `Super+1..0` | go to workspace 1-10 |
| `Super+Shift+1..0` or `Super+Alt+1..0` | move window to workspace |
| `Super+Scroll` | next / previous workspace |
| `Super+Arrows` (or `H K N`) | move focus |
| `Super+Ctrl+Arrows` | resize the window from the keyboard |
| `Super+Left/Right mouse` | drag / resize a window |
| `Super+S`, `Super+Shift+S` | scratchpad, send window to it |

There is deliberately no key that exits Hyprland. The full list is in `hypr/rice/binds.lua`.

## Multi-language typing

`hypr/rice/ime.lua` starts **fcitx5** with the session and exports the input-method variables; `chromium/chromium-flags.conf`
lets Chromium use it on Wayland. The fcitx5 profile (Vietnamese Bamboo, Pinyin) lives in `~/.config/fcitx5`.
**Ctrl+Space** switches the input method on and off (Telex: `chaof` → `chào`). Apps that were already running when fcitx5
was added need a restart.

## Layout

| Path | What |
| --- | --- |
| `hypr/rice/` | Hyprland Lua modules: `theme monitor look input ime binds rules shell` |
| `hypr/bin/` | `dashboard`, `toggle-opacity` |
| `shell/YukiShell`, `shell/YukiLock` | the Quickshell shell and lock screen (`qs -c YukiShell`, `qs -c YukiLock`) |
| `shell/bin/` | `yuki-start` (keeps the shell running), `yuki-brightness` |
| `kitty fish fastfetch btop cava gtk-3.0 gtk-4.0 qt chromium` | app configs and themes |
| `tools/` | one-off helpers |

The palette lives in `hypr/rice/theme.lua`. Env overrides go in `~/.config/hypr-rice/env`; the shell log is
`~/.local/state/hypr-rice/YukiShell.log`. Open Settings with `qs -c YukiShell ipc call settings open`.

The shell still reads and writes MacShell's data directories (`~/.config/macbar`, `macdock`, `macshell`), because the QML
uses those paths. YukiShell never runs MacShell's installer or updater.

## Credits and license

MIT, see [LICENSE](LICENSE). YukiShell and YukiLock are derived from [MacShell](https://github.com/0-ss/MacShell) by
Rickky (original author) and vSuol (contributor), whose copyright notice is kept in the license. Bundled third-party pieces
(the Open Runde fonts, GitHub gemoji data, icons) keep their own licenses.
