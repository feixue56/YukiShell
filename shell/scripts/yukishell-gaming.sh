#!/bin/sh
# YukiShell Game Mode: frees the GPU/CPU for games, and puts everything back afterwards.
#   yukishell-gaming.sh on | off | status
# on : saves the current Hyprland blur / shadow / animation settings and the power profile, then turns blur,
#      shadows and animations off, pauses the animated wallpaper (mpvpaper gets SIGSTOP: no decoding at all) and
#      switches to the performance power profile.
# off: restores exactly what was saved. Safe to call twice; "off" without a saved state does nothing.
# YukiShell itself drops Liquid Glass to plain blur and stops its live window captures while Game Mode is on.
state="${XDG_RUNTIME_DIR:-/tmp}/yukishell-gaming.state"
want="${XDG_RUNTIME_DIR:-/tmp}/yukishell-gaming.want"

# The shell starts this in the background for every change, so an "on" and an "off" can overlap when Game Mode flips quickly (a
# game going fullscreen while its launcher windows take the focus). Unserialized, the "on" could freeze the wallpaper (SIGSTOP)
# AFTER the "off" had already resumed it, leaving the desktop frozen with Game Mode off. So: every call records what it was asked
# for, the calls take turns (flock), and each one applies the LATEST request, whichever call it was.
case "$1" in
on|off)
    echo "$1" > "$want"
    if command -v flock >/dev/null 2>&1; then exec 8>"$state.lock"; flock 8; fi
    set -- "$(cat "$want" 2>/dev/null || echo "$1")"
    ;;
esac

opt() { hyprctl getoption "$1" 2>/dev/null | awk 'NR==1 {print $2}'; }
lua_bool() { case "$1" in 1|true) echo true ;; *) echo false ;; esac; }

case "$1" in
on)
    if [ ! -f "$state" ]; then
        {
            echo "blur=$(opt decoration:blur:enabled)"
            echo "shadow=$(opt decoration:shadow:enabled)"
            echo "anim=$(opt animations:enabled)"
            echo "profile=$(powerprofilesctl get 2>/dev/null)"
        } > "$state"
    fi
    hyprctl eval 'hl.config({ decoration = { blur = { enabled = false }, shadow = { enabled = false } }, animations = { enabled = false } })' >/dev/null 2>&1
    pkill -STOP -x mpvpaper 2>/dev/null
    powerprofilesctl set performance 2>/dev/null
    ;;
off)
    pkill -CONT -x mpvpaper 2>/dev/null      # always: a wallpaper frozen by an earlier run must never stay frozen
    [ -f "$state" ] || exit 0
    . "$state"
    hyprctl eval "hl.config({ decoration = { blur = { enabled = $(lua_bool "${blur:-1}") }, shadow = { enabled = $(lua_bool "${shadow:-1}") } }, animations = { enabled = $(lua_bool "${anim:-1}") } })" >/dev/null 2>&1
    pkill -CONT -x mpvpaper 2>/dev/null
    [ -n "$profile" ] && powerprofilesctl set "$profile" 2>/dev/null
    rm -f "$state"
    ;;
status)
    [ -f "$state" ] && echo on || echo off
    ;;
*)
    echo "usage: $0 on|off|status" >&2; exit 2 ;;
esac
