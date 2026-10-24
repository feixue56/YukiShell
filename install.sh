#!/usr/bin/env bash
# Standalone installer for this rice. Independent of MacShell's repo/install.sh.
# Symlinks files into ~/.config (existing files are moved to *.pre-rice once), then wires Hyprland and Qt.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
cfg="${XDG_CONFIG_HOME:-$HOME/.config}"

link() {  # link <src> <dst>
    mkdir -p "$(dirname "$2")"
    if [ -e "$2" ] && [ ! -L "$2" ]; then mv "$2" "$2.pre-rice"; fi
    ln -sfn "$1" "$2"
}

link "$here/hypr/rice"                          "$cfg/hypr/rice"
link "$here/kitty/kitty.conf"                   "$cfg/kitty/kitty.conf"
link "$here/fastfetch/config.jsonc"             "$cfg/fastfetch/config.jsonc"
link "$here/btop/themes/mocha-glass.theme"      "$cfg/btop/themes/mocha-glass.theme"
link "$here/cava/config"                        "$cfg/cava/config"
link "$here/fish/config.fish"                   "$cfg/fish/config.fish"
for f in cll ll; do link "$here/fish/functions/$f.fish" "$cfg/fish/functions/$f.fish"; done
for v in 3 4; do
    link "$here/gtk-$v.0/gtk.css"      "$cfg/gtk-$v.0/gtk.css"
    link "$here/gtk-$v.0/settings.ini" "$cfg/gtk-$v.0/settings.ini"
done
link "$here/qt/CatppuccinMauve.colors" "$HOME/.local/share/color-schemes/CatppuccinMauve.colors"

# Hyprland: one require line, placed above any MacShell block so install.sh updates there never touch the rice.
lua="$cfg/hypr/hyprland.lua"
if [ -f "$lua" ] && ! grep -q 'rice.theme\|"rice\.' "$lua"; then
    cp "$lua" "$lua.pre-rice"
    { cat <<'LUA'
-- Rice (managed by ~/hypr-rice)
for _, m in ipairs({ "monitor", "look", "input", "binds", "rules" }) do
    local ok, err = pcall(require, "rice." .. m)
    if not ok then hl.exec_cmd("notify-send 'Hyprland rice' 'rice." .. m .. " failed: " .. tostring(err):gsub("'", "") .. "'") end
end

LUA
      cat "$lua.pre-rice"; } > "$lua"
fi

# btop / Qt / GTK settings that live in other files
sed -i 's/^color_theme = .*/color_theme = "mocha-glass"/; s/^theme_background = .*/theme_background = false/' "$cfg/btop/btop.conf" 2>/dev/null || true
if command -v kwriteconfig6 >/dev/null; then
    kwriteconfig6 --file kdeglobals --group General --key ColorScheme CatppuccinMauve
    kwriteconfig6 --file kdeglobals --group General --key AccentColor 203,166,247
    kwriteconfig6 --file kdeglobals --group Icons   --key Theme Papirus-Dark
    kwriteconfig6 --file kdeglobals --group KDE     --key widgetStyle Breeze
fi
if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark || true
    gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark || true
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark || true
fi
command -v hyprctl >/dev/null && hyprctl reload || true
echo "Rice installed. Needs: adw-gtk-theme, papirus-icon-theme, bibata cursor, JetBrainsMono Nerd Font, plasma-integration."
