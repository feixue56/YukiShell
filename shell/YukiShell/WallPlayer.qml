import QtQuick
import QtMultimedia
import YukiVideo

// WallPlayer - the ONE player of the animated wallpaper for all the Liquid Glass (bar, Spotlight, Dock, widgets, Settings). It needs
// the YukiVideo plugin (shell/plugins/yukivideo, built by tools/build-plugins): the player decodes into WallFeed, and every window's
// LiveWall shows those frames (LiveWallFeed.qml), so the whole shell runs one decoder and every piece of glass shows the same frame.
// Without the plugin this file does not load, and each LiveWall plays the video itself as before.
//   * it plays while any window wants the video (WallFeed.watching) and pauses the moment none does;
//   * it is torn down once nobody has wanted it for a while (30 s, or 60 s while a window still shows its paused frame): a missing
//     decoder costs nothing, and starting one again takes ~120 ms of main-thread time;
//   * the very first player of the shell costs ~1 s of main-thread time (Qt Multimedia setting itself up), so it waits until ~3 s
//     after the shell started, while the bar and the Dock slide in.
Item {
    id: wp
    required property var host                  // YukiBar: glassVideo, wallClock
    readonly property string video: host.glassVideo
    readonly property bool wanted: video !== "" && WallFeed.watching > 0
    readonly property bool held: video !== "" && WallFeed.holding > 0
    property bool active: false
    readonly property real born: Date.now()

    function update() {
        if (wanted) {
            stopT.stop();
            if (!active && !startT.running) {
                startT.interval = Math.max(1, born + 3000 - Date.now());
                startT.restart();
            }
        } else {
            startT.stop();
            if (active) { stopT.interval = held ? 60000 : 30000; stopT.restart(); }
        }
    }
    onWantedChanged: update()
    onHeldChanged: update()
    onVideoChanged: { active = false; WallFeed.clear(); update(); }     // another wallpaper: a new player
    Component.onCompleted: update()
    Timer { id: startT; onTriggered: wp.active = wp.wanted }
    Timer { id: stopT; onTriggered: { wp.active = false; WallFeed.clear(); } }

    Loader {
        active: wp.active && wp.video !== ""
        sourceComponent: Item {
            id: box
            readonly property bool hold: !wp.wanted          // frozen on its last frame while no window wants it playing
            onHoldChanged: { if (hold) mp.pause(); else { mp.play(); syncT.restart(); } }
            MediaPlayer {
                id: mp
                source: "file://" + wp.video
                loops: MediaPlayer.Infinite
                videoOutput: WallFeed.sink
                Component.onCompleted: play()
                onMediaStatusChanged: { if (mediaStatus === MediaPlayer.BufferedMedia || mediaStatus === MediaPlayer.LoadedMedia) syncT.restart(); }
            }
            // --- following mpv's clock (the desktop wallpaper), so the glass shows the very frame the desktop shows ---
            // A seek lands a little late (the decoder starts from the keyframe before the target), so the target is the clock's position
            // plus `lead`, and `lead` learns from how far off the previous seek ended up. Within 50 ms (3 frames at 60 fps) it is left
            // alone: the reported position moves in whole frames, and a seek costs a hiccup.
            property real lead: 40           // ms
            property real lastSeek: 0        // Date.now() of our last seek (its result is judged 1.5 s later)
            function clockMs() {
                var c = wp.host.wallClock;
                if (!c || !c.ok || Date.now() - c.at > 2500 || mp.duration <= 0) return -1;
                return ((c.pos * 1000 + (Date.now() - c.at)) % mp.duration + mp.duration) % mp.duration;
            }
            function resync() {
                if (box.hold || mp.playbackState !== MediaPlayer.PlayingState || !mp.seekable) return;
                var want = clockMs();
                if (want < 0) return;
                var d = mp.position - want;                       // > 0: the glass is ahead of the desktop
                if (d > mp.duration / 2) d -= mp.duration; else if (d < -mp.duration / 2) d += mp.duration;
                if (box.lastSeek > 0 && Date.now() - box.lastSeek < 4000) box.lead = Math.max(0, Math.min(400, box.lead - d * 0.7));
                if (Math.abs(d) <= 50) return;
                box.lastSeek = Date.now();
                mp.position = (want + box.lead) % mp.duration;
            }
            Timer {
                id: syncT
                interval: 1500
                repeat: true
                running: !box.hold
                onTriggered: box.resync()
            }
        }
    }
}
