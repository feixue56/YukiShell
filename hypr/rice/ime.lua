-- Multi-language typing: fcitx5 (Vietnamese Telex/VNI via Bamboo, Chinese Pinyin; more in fcitx5-configtool).
-- Ctrl+Space switches between the plain keyboard and the input method.
-- The apps here are native Wayland and talk to fcitx5 through the text-input protocol; these variables cover the rest:
hl.env("XMODIFIERS", "@im=fcitx")       -- XWayland apps
hl.env("QT_IM_MODULE", "fcitx")         -- Qt apps and the shell (fcitx5-qt)
hl.env("SDL_IM_MODULE", "fcitx")        -- SDL games / apps
hl.env("GLFW_IM_MODULE", "ibus")        -- GLFW apps (kitty): fcitx5 offers the ibus interface they speak
-- GTK_IM_MODULE is left unset on purpose: GTK uses the Wayland text-input protocol itself, which is the more reliable path.

hl.on("hyprland.start", function()
    hl.exec_cmd("fcitx5 -d --replace")
end)
