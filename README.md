<p align="center"><img src="shell/YukiShell/assets/yukishell-logo.png" width="128" alt="YukiShell"></p>

# YukiShell

A Catppuccin Mocha (mauve + pink) rice for **Hyprland** with its own desktop shell, built on **Quickshell**.

- **YukiShell**: menu bar, dock, Spotlight, Control Center, widgets, notifications and a Settings app
- **YukiLock**: the lock screen
- The Hyprland config (Lua), kitty, fish, fastfetch, btop, cava, GTK 3/4 and Qt/KDE themes to match

YukiShell is a fork of [MacShell](https://github.com/0-ss/MacShell) by Rickky and vSuol (MIT). It is completely separate from
upstream: it has its own name, config path, installer and Settings app, and it never phones home to MacShell.

Made by [雪風 (@xuefeng1331)](https://github.com/xuefeng1331).

## Install

Needs Hyprland with the **Lua config** (written and tested on 0.56.2, CachyOS, NVIDIA) and Quickshell.

```sh
git clone https://github.com/xuefeng1331/YukiShell.git ~/hypr-rice
cd ~/hypr-rice && ./install.sh
```

`install.sh` symlinks the files into `~/.config` (anything already there is moved to `*.pre-rice` once), adds one `require`
line to `~/.config/hypr/hyprland.lua`, and sets the GTK/Qt/btop themes. Re-run it any time; it is idempotent.

Packages the rice expects: `kitty fish fastfetch btop cava tty-clock fcitx5 fcitx5-bamboo adw-gtk-theme papirus-icon-theme
plasma-integration ddcutil brightnessctl python-numpy` and the Bibata cursor and JetBrainsMono Nerd Font. The shell itself uses `nmcli`, `playerctl`,
`powerprofilesctl`, `grim`, `imagemagick`, `wl-clipboard`, `cliphist` and `hyprsunset` for the matching features; whatever is missing just disables that feature.
`python-numpy` is only for generating the UI sound effects. **`tools/doctor`** (run by the installer too) lists exactly what is missing on your machine and what it would disable.

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
| `Super+Shift+W` / `Super+Shift+E` | floating Chromium / Dolphin (1280×800 / 1100×700, centred) |
| `Super+Q` | close window |
| `Super+F` | fullscreen |
| `Super+Alt+Space` | toggle floating |
| `Super+Shift+Tab` | terminal and Dolphin opacity: solid → liquid glass → completely transparent (a terminal fades only its background, Dolphin fades the whole window) |
| `Super+Alt+D` | dashboard (fastfetch, clock, cava) |
| `Super+1..0` | go to workspace 1-10 |
| `Super+Shift+1..0` or `Super+Alt+1..0` | move window to workspace |
| `Super+Scroll` | next / previous workspace |
| `Super+Arrows` (or `H K N`) | move focus |
| `Super+Ctrl+Arrows` | resize the window from the keyboard |
| `Super+Left/Right mouse` | drag / resize a window |
| `Super+S`, `Super+Shift+S` | scratchpad, send window to it |
| `Super+Shift+Arrows` | swap the window with its neighbour |
| `Super+Z` | System Settings |
| `Super+Space` / `Super+V` / `Super+.` | Spotlight / clipboard history / emoji |
| `Alt+Tab` | window switcher |
| `Print` / `Shift+Print` / `Ctrl+Print` | screenshot: region / screen / window |
| `Super+G` | Game Mode (the shell pauses its effects) |
| `Super+,` | notification centre |
| `Super+L` | lock screen |
| `Super+Shift+R` | restart the shell cleanly (`yuki-restart`) |
| `Super+Shift+C` | reload the Hyprland config |

There is deliberately no key that exits Hyprland. The full list is in `hypr/rice/binds.lua` and `shell.lua`.

**Every shortcut can be changed** in **System Settings → Keyboard → Keyboard Shortcuts** (translated, and read live from the running Hyprland): click
the keys, press the new combination, and it is applied at once. Esc cancels, Backspace removes the shortcut, *Reset* brings the default back, and a combination that
is already taken is refused with the name of its owner. Groups of keys that belong together (the workspace numbers, the arrow keys) and `Alt+Tab` (the switcher waits for Alt to be
let go) stay as they are. While it listens, Settings switches Hyprland to an empty `yuki-capture` submap so your own binds do not fire; `Ctrl+Alt+F1…F12` cannot be recorded, because the
compositor keeps them for switching VTs.

How it works: `hypr/rice/keys.lua` provides `bind(keys, dispatcher, "Description", opts)`. Your choices are kept in `~/.config/yukishell/keybinds.tsv`
(`description<TAB>keys`, empty keys = no shortcut) and replace the defaults when the config loads, then Settings runs `hyprctl reload`. Binds written with the
helper show up in Settings by their description, and `tools/i18n-check.py` reminds you to translate it. Pass `{ fixed = true }` to keep one out of the editor.

## What it does

- **Liquid Glass** menus, Dock, widgets and Settings, optionally with the *animated wallpaper playing inside the glass*.
- **Animated wallpaper** (mpvpaper): it keeps playing behind your windows and workspaces. The **menu bar button** (a picture frame, shown only while
  the wallpaper is a video) pauses and resumes it by hand, also for the copy inside the glass, and the choice survives a restart. Game Mode stops it on its
  own. **Settings → Wallpaper → Pause behind windows** (off by default) stops it while windows hide the desktop, to save power on a laptop.
- Hover feedback everywhere: the menu bar and Dock buttons get a frosted-glass tile with a rim light that follows the pointer,
  workspaces that have windows keep a resting glass tile, and the Dock's last button is a gear that opens Settings.
- **Audio visualizer**: bars (or a mirrored row, or a smooth wave) that move with the music behind the Now Playing widget and next to the cover in the
  Control Center tile. It uses `cava` and only listens while something is playing and a visualizer is on screen; **Settings → Widgets → Audio Visualizer**
  has the style, the colour (cover / white / accent), the height and a live preview. Without `cava` it just stays off.
- The chosen option is always a **Liquid Glass** capsule: the segmented controls in Settings, and the selected pane in the Settings sidebar (a glass tile that slides to it).
- **Any colour you like**: the accent colour, the Dock icon tint, the Control Center highlight and the lock screen clock colour each have a row of presets plus a
  rainbow dot that opens a palette and a field taking a **hex code** (`#0A84FF`, `0a84ff`, `#08f`) or an **RGB code** (`rgb(10, 132, 255)`, `10, 132, 255`).
- **Your own apps in the Dock**: **Settings → Applications → Add to Dock** picks any installed app from a searchable list, or makes a *custom app* (a name, a command,
  an icon and "run in a terminal"), saved as `~/.local/share/applications/yuki-custom-<name>.desktop` and removed again when you take it out of the Dock.
- **A Control Center you can shape by hand**: *Edit Controls* (or **Settings → Control Center**) lets you add and remove controls, **drop any control on any free
  cell** of the 4-column grid (an empty cell shows where; dropping on a control of the same size swaps them, *Tidy Up* packs everything together again), **pull the
  corner handle to resize** it to whole cells (1–4 wide, 1–2 tall, sliders 2–4 wide), or tap the grey `2×1` badge to cycle through the common sizes. Seven extra controls are
  available besides the usual switches: Lock Screen, Screenshot, Color Picker, Wallpapers, System Settings, Microphone and Power Mode (power-profiles-daemon).
  **Microphone** is a slider like Sound (with a mute button beside it) that sets the input volume.
  Settings has sliders for the row height and the gap between controls (in pixels), and the colour a switched-on control turns (white by default). A panel taller than
  the screen scrolls. All of it is saved and has a Reset.
- **Settings → Users & Groups → Picture** lets you crop your profile picture (drag, scroll to zoom) before it is saved.
- **Hardware that is not there is not offered**: Airplane Mode follows the real radio switches (rfkill), and on a PC with no Wi-Fi or Bluetooth adapter
  those Control Center tiles are greyed out (N/A), the Bluetooth icon leaves the menu bar and the two Settings panes disappear. Plug an adapter in and they come back.
- **Wallpapers from as many folders as you like** (Settings → Wallpaper → Wallpaper folders, or *Add Folder…* in the Ctrl+Alt+W picker). Pictures and videos you drop into
  any of them, or delete, show up in the pickers by themselves (inotify, no refresh button).
- **A picture chooser made for pictures**: the profile picture, image widgets and wallpaper folders open YukiShell's own chooser: big thumbnails (size slider),
  a large preview of whatever you point at, places in a sidebar, a path bar and search. No zenity or kdialog needed. Other apps' dialogs ("Open", "Save") still float, centred, instead of tiling.

## Multi-language typing

`hypr/rice/ime.lua` starts **fcitx5** with the session and exports the input-method variables; `chromium/chromium-flags.conf`
lets Chromium use it on Wayland. The fcitx5 profile (Vietnamese Bamboo, Pinyin) lives in `~/.config/fcitx5`.
**Ctrl+Space** switches the input method on and off (Telex: `chaof` → `chào`). Apps that were already running when fcitx5
was added need a restart.

## Interface language

**System Settings → General → Language** switches the whole shell (menu bar, Dock, Spotlight, Control Center, Settings, the
widgets and the lock screen) live, no restart: English, 简体中文, 繁體中文, 日本語, 한국어, Tiếng Việt and Русский, or
*Automatic* to follow `LANG`. Dates, day and month names follow the chosen language too. Anything without a translation
falls back to English.

The tables are `shell/YukiShell/lang/<code>.js` (keys are the English texts used in the QML) plus a small block per language in
`shell/YukiLock/I18n.js`. To add a language, copy `lang/vi.js`, translate the values, and register it in `dicts` and
`languages` in `shell/YukiShell/I18n.js`. Typing in Japanese, Korean or Traditional Chinese needs the matching fcitx5 input
method (`fcitx5-mozc`, `fcitx5-hangul`, `fcitx5-chewing`); the profile only ships Bamboo and Pinyin.

## Layout

| Path | What |
| --- | --- |
| `hypr/rice/` | Hyprland Lua modules: `theme monitor look input ime keys binds rules shell` |
| `hypr/bin/` | `dashboard`, `toggle-opacity` |
| `shell/YukiShell`, `shell/YukiLock` | the Quickshell shell and lock screen (`qs -c YukiShell`, `qs -c YukiLock`) |
| `shell/bin/` | `yuki-start` (keeps the shell running), `yuki-restart` (restarts it cleanly), `yuki-brightness` |
| `shell/scripts/` | helpers the shell calls: wallpaper (`yukishell-setwall.sh`, `-dynwall.sh`, `-wallpause.sh`), Game Mode, UI sound generator |
| `kitty fish fastfetch btop cava gtk-3.0 gtk-4.0 qt chromium` | app configs and themes |
| `tools/` | `doctor` (what is missing on this machine), `check` (lints the repo), `i18n-check.py` (missing translations), `make-logo.py`, `fix-font-loops.py` |

The palette lives in `hypr/rice/theme.lua`. Env overrides go in `~/.config/hypr-rice/env`; the shell log is
`~/.local/state/hypr-rice/YukiShell.log`. Open Settings with `qs -c YukiShell ipc call settings open`.

The shell keeps its settings in `~/.config/yukibar`, `yukidock`, `yukishell`, `yukilock` and `yukiwidgets`. They are its own
folders: YukiShell never reads or writes MacShell's, and never runs MacShell's installer or updater.

## Hacking on it

QML changes hot-reload as soon as you save; language tables (`lang/*.js`) are cached, so use `yuki-restart` (or `Super+Shift+R`)
after editing those. Run `tools/check` before committing: it syntax-checks the Lua, fish, shell, Python, JSON, JS and QML files and
reports every interface string that a language is missing. A quick CPU check: `top -p $(pgrep -f '^qs -c YukiShell')`.

## Credits and license

MIT, see [LICENSE](LICENSE). YukiShell and YukiLock are derived from [MacShell](https://github.com/0-ss/MacShell) by
Rickky (original author) and vSuol (contributor), whose copyright notice is kept in the license. Bundled third-party pieces
(the Open Runde fonts, GitHub gemoji data, icons) keep their own licenses.
