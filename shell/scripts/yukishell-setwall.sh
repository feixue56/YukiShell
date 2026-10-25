#!/bin/sh
# Set the YukiShell wallpaper: a picture (awww) or an animated one (video -> mpvpaper on every monitor).
#   yukishell-setwall.sh <file>        apply it
#   yukishell-setwall.sh --restore     re-apply the saved animated wallpaper at login (no-op if none)
#   yukishell-setwall.sh --prepare <video>   only build the cached files (thumbnail frame + optimized copy)
# Prints the still image the Liquid Glass should refract (the picture itself, or a frame grabbed from the video).
# The current animated wallpaper is remembered in ~/.config/yukishell/wallpaper-video (YukiLock reads it too).
#
# Performance: videos are never played as-is. A 4K clip decoded once per monitor cost ~45% CPU. Each video gets a cached
# copy sized to the largest monitor, at the clip's own frame rate up to 60 fps (H.264, hardware-decoded through VA-API: the
# Intel iGPU when there is one, NVDEC through nvidia-vaapi-driver otherwise). It used to be cut to 30 fps, which made a
# 60 fps wallpaper visibly choppy. The copy is built once in the background; the still frame shows meanwhile.
state="$HOME/.config/yukishell/wallpaper-video"
cache="$HOME/.cache/yukishell"
mkdir -p "$HOME/.config/yukishell" "$cache/frames" "$cache/anim"

# Intel render node (never the NVIDIA one, so the dGPU can stay asleep)
igpu=""
for n in /dev/dri/renderD*; do
    [ "$(basename "$(readlink -f "/sys/class/drm/$(basename "$n")/device/driver")")" = i915 ] && { igpu="$n"; break; }
    [ "$(basename "$(readlink -f "/sys/class/drm/$(basename "$n")/device/driver")")" = xe ] && { igpu="$n"; break; }
done
# video-sync=display-resample + interpolation: a 60 fps clip on a 100 / 144 Hz monitor is blended to the monitor's own rate instead of
# holding each frame for 1 or 2 refreshes (a visible judder). Measured: +2 % of a core, no extra GPU load. The monitor's rate is
# handed to each player as display-fps-override (below), since mpvpaper's render loop does not report it to mpv by itself.
MPV_OPTS="no-audio loop-file=inf profile=fast panscan=1.0 hwdec=vaapi${igpu:+ vaapi-device=$igpu} vd-lavc-threads=2 framedrop=vo video-sync=display-resample interpolation=yes tscale=oversample"

is_video() { case "$(printf %s "$1" | tr 'A-Z' 'a-z')" in *.mp4|*.webm|*.mkv|*.mov|*.m4v) return 0 ;; esac; return 1; }
key_of() { printf '%s:%s' "$1" "$(stat -c %Y "$1" 2>/dev/null)" | md5sum | cut -c1-16; }

# A cached copy is only trusted when ffprobe can read a video stream from it. "Non-empty" is not enough: two overlapping runs
# (a login restore plus the shell re-applying the wallpaper) used to share one temp file and left a big, unplayable mp4
# that was then trusted for ever, so mpvpaper sat idle on a blank wallpaper.
valid_video() { [ -s "$1" ] && [ "$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_type -of csv=p=0 "$1" 2>/dev/null | head -n1)" = video ]; }
# run a command while holding a per-file lock, so a second caller waits for the first conversion instead of racing it
with_lock() {  # with_lock <lockfile> <command...>
    l="$1"; shift
    if command -v flock >/dev/null 2>&1; then ( flock 8; "$@" ) 8>"$l"; else "$@"; fi
}

frame_for() {
    out="$cache/frames/$(key_of "$1").png"
    if [ ! -s "$out" ]; then
        tmp="$out.$$.part.png"     # written aside and renamed, so a half-written frame is never picked up
        { ffmpeg -loglevel error -y -ss 1 -i "$1" -frames:v 1 "$tmp" </dev/null \
            || ffmpeg -loglevel error -y -i "$1" -frames:v 1 "$tmp" </dev/null; } && mv -f "$tmp" "$out" || rm -f "$tmp"
    fi
    printf '%s' "$out"
}

# small looping preview for the pickers (animated WebP: no video player needed inside the shell)
preview_for() {
    k=$(key_of "$1"); mkdir -p "$cache/thumbs"
    t="$cache/thumbs/$k.jpg"; w="$cache/thumbs/$k.webp"
    if [ ! -s "$t" ]; then
        ffmpeg -loglevel error -y -ss 1 -i "$1" -frames:v 1 -vf "scale=480:-2" "$t.$$.part.jpg" </dev/null && mv -f "$t.$$.part.jpg" "$t" || rm -f "$t.$$.part.jpg"
    fi
    if [ ! -s "$w" ]; then
        nice -n 15 ffmpeg -loglevel error -y -t 4 -i "$1" -an -vf "fps=12,scale=360:-2:flags=lanczos" \
            -c:v libwebp_anim -lossless 0 -q:v 60 -loop 0 "$w.$$.part.webp" </dev/null && mv -f "$w.$$.part.webp" "$w" || rm -f "$w.$$.part.webp"
    fi
}

# low-res looping animated WebP of the whole clip: what the Liquid Glass (widgets) refracts - it's blurred anyway,
# so 480 px at 15 fps is plenty, and an image needs no video player inside the shell
build_glass() {  # build_glass <video> <out.webp>
    [ -s "$2" ] && return 0
    tmp="$2.$$.part.webp"
    nice -n 15 ionice -c3 ffmpeg -loglevel error -y -i "$1" -an -vf "fps=15,scale=480:-2:flags=bilinear" \
        -c:v libwebp_anim -lossless 0 -q:v 45 -compression_level 3 -loop 0 "$tmp" </dev/null && mv -f "$tmp" "$2" || rm -f "$tmp"
}
glass_for() {
    k=$(key_of "$1"); g="$cache/anim/$k-glass.webp"
    with_lock "$g.lock" build_glass "$1" "$g"
    printf '%s' "$g"
}

# width of the widest monitor (logical px), at least 1280
target_width() {
    w=$(hyprctl -j monitors 2>/dev/null | jq '[.[] | (.width / .scale)] | max | floor' 2>/dev/null)
    case "$w" in ''|null|*[!0-9]*) w=1920 ;; esac
    [ "$w" -lt 1280 ] && w=1280
    printf '%s' "$w"
}

# optimized copy: largest-monitor width, the source's frame rate capped at 60 (-fpsmax keeps 24/25/30/50/60 fps clips as they
# are), H.264, a keyframe every second at 60 fps
build_anim() {  # build_anim <video> <out.mp4> <width>: re-checks under the lock, so a waiting second caller finds the finished copy
    valid_video "$2" && return 0
    rm -f "$2"
    tmp="$2.$$.part.mp4"       # one temp file per run: concurrent runs can no longer write into each other's output
    nice -n 15 ionice -c3 ffmpeg -loglevel error -y -i "$1" -an \
        -vf "scale='min($3,iw)':-2:flags=lanczos" -fpsmax 60 \
        -c:v libx264 -preset faster -crf 21 -pix_fmt yuv420p -g 60 -movflags +faststart "$tmp" </dev/null \
        && valid_video "$tmp" && mv -f "$tmp" "$2" || rm -f "$tmp"
}
anim_for() {
    tw=$(target_width)
    out="$cache/anim/$(key_of "$1")-$tw-f60.mp4"     # "-f60": built at up to 60 fps (the old 30 fps copies have no suffix)
    valid_video "$out" || with_lock "$out.lock" build_anim "$1" "$out" "$tw"
    # could not build a usable copy: play the original (heavier, but never a blank wallpaper)
    valid_video "$out" || { printf '%s' "$1"; return; }
    printf '%s' "$out"
}

awww_ready() {
    awww query >/dev/null 2>&1 && return 0
    pgrep -x awww-daemon >/dev/null || { setsid awww-daemon >/dev/null 2>&1 & }
    for i in 1 2 3 4 5 6 7 8 9 10; do awww query >/dev/null 2>&1 && return 0; sleep 0.3; done
    return 1
}

supfile="$cache/wallsup.pid"
stop_video() {
    # the supervisor runs in its own process group (setsid): stop the whole group, nothing else
    if [ -f "$supfile" ]; then
        # every supervisor appends its pid; the pid is only trusted if it is still one of ours (pids get reused)
        while read -r g; do
            [ -n "$g" ] && tr '\0' ' ' < "/proc/$g/cmdline" 2>/dev/null | grep -q ' wallsup ' && kill -TERM -- "-$g" 2>/dev/null
        done < "$supfile"
        rm -f "$supfile"
    fi
    # mpvpaper can ignore SIGTERM (and a Game Mode SIGSTOP blocks it): wake it, ask, then force it
    pkill -CONT -x mpvpaper 2>/dev/null
    pkill -TERM -x mpvpaper 2>/dev/null
    for i in 1 2 3 4 5; do pgrep -x mpvpaper >/dev/null || break; sleep 0.1; done
    pkill -KILL -x mpvpaper 2>/dev/null
}

# keeps mpvpaper running for as long as this video is the chosen wallpaper (restarts it if it crashes)
start_video() {
    src="$1"; play="$2"
    valid_video "$play" || play="$src"      # never hand mpvpaper a file it cannot play: it would stay running and show nothing
    stop_video
    printf '%s\n' "$play" > "$HOME/.config/yukishell/wallpaper-video-play"     # the optimized copy (YukiLock plays this one)
    # one supervised mpvpaper per monitor, each with an IPC socket: YukiShell pauses a monitor's video while windows
    # cover it (or the screen is locked) and resumes it when the desktop shows again - no decoding nobody can see
    outs=$(hyprctl -j monitors 2>/dev/null | jq -r '.[].name' 2>/dev/null); [ -n "$outs" ] || outs=ALL
    run="${XDG_RUNTIME_DIR:-/tmp}"
    setsid sh -c '
        echo $$ >> "$5"
        src="$1"; play="$2"; state="$3"; opts="$4"; run="$6"; pausebin="$7"; shift 7
        for out in "$@"; do
            (
                fails=0
                while [ "$(cat "$state" 2>/dev/null)" = "$src" ] && [ "$fails" -lt 5 ]; do
                    t=$(date +%s)
                    rm -f "$run/yukishell-mpv-$out.sock"      # a stale socket (player was killed) would fool the wait below
                    # a fresh player starts playing, but the shell only sends "pause" when ITS state changes: if the desktop is already
                    # covered, tell the new player as soon as its socket exists (the shell lists the covered outputs in this file)
                    (
                        n=0; while [ ! -S "$run/yukishell-mpv-$out.sock" ] && [ "$n" -lt 40 ]; do n=$((n + 1)); sleep 0.25; done
                        grep -qx "$out" "$run/yukishell-wallpaused" 2>/dev/null && "$pausebin" "$out" pause
                    ) >/dev/null 2>&1 </dev/null &
                    hz=$(hyprctl -j monitors 2>/dev/null | jq -r --arg o "$out" ".[] | select(.name == \$o) | .refreshRate" 2>/dev/null | head -n1)
                    case "$hz" in [0-9]*) hzopt=" display-fps-override=$hz" ;; *) hzopt="" ;; esac
                    mpvpaper -o "$opts$hzopt input-ipc-server=$run/yukishell-mpv-$out.sock" "$out" "$play" >/dev/null 2>&1 </dev/null
                    [ "$(cat "$state" 2>/dev/null)" = "$src" ] || exit 0
                    [ $(( $(date +%s) - t )) -lt 10 ] && fails=$((fails + 1)) || fails=0
                    sleep 1
                done
            ) &
        done
        wait
    ' wallsup "$src" "$play" "$state" "$MPV_OPTS" "$supfile" "$run" "$(dirname "$(readlink -f "$0")")/yukishell-wallpause.sh" $outs >/dev/null 2>&1 </dev/null 8>&- &
}
# stopping the old player and starting the new one is one step: two callers at once (the login restore and the shell re-applying the
# wallpaper) each stopped "the" player, then each started their own, and the desktop ended up decoding the video twice
change_video() { with_lock "$cache/wallpaper-start.lock" "$@"; }

case "$1" in
    --prepare) [ -f "$2" ] && is_video "$2" && { preview_for "$2"; frame_for "$2" >/dev/null; a=$(anim_for "$2"); glass_for "$a" >/dev/null; }; exit 0 ;;
    --restore)
        [ -f "$state" ] || exit 0
        f=$(cat "$state")
        [ -f "$f" ] || { rm -f "$state"; exit 0; } ;;
    *) f="$1" ;;
esac
[ -f "$f" ] || { echo "no such file: $f" >&2; exit 1; }

if is_video "$f"; then
    still=$(frame_for "$f")
    printf '%s\n' "$f" > "$state"
    # the frame goes up first, so there is never a black flash and the glass has something to refract right away
    awww_ready && [ -s "$still" ] && awww img "$still" --transition-type grow --transition-duration 0.8 >/dev/null 2>&1
    printf '%s\n' "$still"
    # build the optimized copy in the background (only the first time), then play it
    (
        play=$(anim_for "$f")
        [ "$(cat "$state" 2>/dev/null)" = "$f" ] || exit 0      # another wallpaper was picked meanwhile
        change_video start_video "$f" "$play"
        g=$(glass_for "$play")
        [ "$(cat "$state" 2>/dev/null)" = "$f" ] && [ -s "$g" ] && printf '%s\n' "$g" > "$HOME/.config/yukishell/wallpaper-video-glass"
    ) >/dev/null 2>&1 </dev/null &
else
    rm -f "$state" "$HOME/.config/yukishell/wallpaper-video-play" "$HOME/.config/yukishell/wallpaper-video-glass"
    change_video stop_video
    awww_ready && awww img "$f" --transition-type grow --transition-duration 0.9 >/dev/null 2>&1
    printf '%s\n' "$f"
fi
