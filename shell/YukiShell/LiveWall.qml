// LiveWall - the animated wallpaper (video) for the Liquid Glass backdrops. The glass of the Dock, the menus, the widgets and the
// Settings window refracts a picture of the wallpaper; for an animated wallpaper this item plays a video (muted) on top of that
// picture, so the glass shows the wallpaper moving in real time.
// `video` is what the shell hands in as bar.glassVideo: "" while "Animated wallpaper in glass" is off (the default), otherwise a small
// 720 px copy of the wallpaper at its own frame rate (up to 60 fps). With `video` empty, `live` false, or the wallpaper a still picture again, the Loader is inactive
// and no decoder exists at all. While `paused` (Game Mode, the menu bar button, "Pause behind windows") the video freezes on its last frame
// at once (a paused decoder costs ~1% of a core, a playing one ~3%), and the decoder is torn down a good while later: a missing one costs
// nothing and frees its GPU memory (~100 MB each), and the still picture underneath is what shows until the video is back.
// `clock` (bar.wallClock) is mpvpaper's playback position: the copy lines itself up with it, so the glass shows the very frame the desktop
// shows instead of running seconds ahead or behind (every player used to start from 0 at its own moment).
// One window needs one LiveWall: the desktop widgets and the widget copies in the bar's backdrop show their part of it through a WallSlice.
import QtQuick
import QtMultimedia

Item {
    id: lw
    property string video: ""        // absolute path of the video wallpaper, "" = a still picture
    property bool live: false        // real-time glass switched on
    property bool paused: false      // e.g. the desktop is completely covered by windows
    property var clock: null         // { ok, pos (s), at (Date.now() of that reading) } from YukiBar (wallClock), or null
    property int startDelay: -1      // ms before a missing decoder is started again; -1 = a random moment within ~5 s (see below)
    signal newFrame()                // a new video frame arrived (WallSlice redraws on it instead of on every vsync)
    property bool showing: false     // the video is on screen (decoder up and its first frame arrived)
    readonly property bool available: live && video !== ""
    readonly property bool wanted: available && !paused
    // Creating or destroying a decoder runs on the main thread and costs ~120 ms with a hardware (NVDEC) one, and the shell has several of
    // them (bar, Dock, the desktop widgets). Doing that in the same instant froze the whole shell for up to 2 s, so everything it animates
    // (the Dock sliding away, the bar) started late.
    //   * pausing and resuming a decoder that exists is instant, so a short pause never touches the decoders;
    //   * a decoder is only torn down once the pause has LASTED (30-60 s, a different moment for each), and resuming earlier cancels the teardown;
    //   * a decoder that is gone is started again at a random moment within ~5 s of the resume (they would keep the main thread busy
    //     for good if they all started together), the still picture shows until then.
    //   * the very first video player in the shell costs ~1 s of main-thread time (Qt Multimedia setting itself up, measured with
    //     one player alone, hardware decoding on or off). At startup that froze the bar and the Dock just as they slid in, so the
    //     long-lived players (startDelay -1) wait until ~3 s after they were made; the still picture shows until then.
    property bool active: false
    readonly property real born: Date.now()
    function startSoon() {
        var d = startDelay >= 0 ? Math.max(1, startDelay) : Math.max(300 + Math.random() * 4700, born + 3000 - Date.now());
        startT.interval = d;
        startT.restart();
    }
    Component.onCompleted: if (wanted) startSoon()
    onWantedChanged: {
        if (wanted) {
            stopT.stop();
            if (!active) startSoon();
        } else if (active) {
            startT.stop();
            // switched off for good (no video, real-time glass off): gone at once. Only a covered desktop waits.
            if (!available) active = false;
            else { stopT.interval = 30000 + Math.random() * 30000; stopT.restart(); }
        }
    }
    Timer { id: stopT; onTriggered: lw.active = false }
    Timer { id: startT; onTriggered: lw.active = lw.wanted }

    Loader {
        anchors.fill: parent
        active: lw.active
        sourceComponent: Item {
            id: box
            // frozen on its last frame while paused, going again the moment it is resumed
            readonly property bool hold: lw.paused
            onHoldChanged: { if (hold) mp.pause(); else { mp.play(); syncT.restart(); } }
            MediaPlayer {
                id: mp
                source: "file://" + lw.video
                loops: MediaPlayer.Infinite
                videoOutput: vo
                Component.onCompleted: play()
                onMediaStatusChanged: { if (mediaStatus === MediaPlayer.BufferedMedia || mediaStatus === MediaPlayer.LoadedMedia) syncT.restart(); }
            }
            // --- following mpv's clock ---
            // A seek lands a little late (the decoder starts from the keyframe before the target), so the target is the clock's position
            // plus `lead`, and `lead` learns from how far off the previous seek ended up. A copy within 50 ms (3 frames at 60 fps) is left
            // alone: the reported position moves in whole frames, so smaller differences are mostly measurement noise, and a seek costs a
            // hiccup. Measured: the first check found the glass 3.9 s behind the desktop; after one seek it stayed within -4..+41 ms.
            property real lead: 40           // ms
            property real lastSeek: 0        // Date.now() of our last seek (its result is judged 1.5 s later)
            function clockMs() {
                var c = lw.clock;
                if (!c || !c.ok || Date.now() - c.at > 2500 || mp.duration <= 0) return -1;
                return ((c.pos * 1000 + (Date.now() - c.at)) % mp.duration + mp.duration) % mp.duration;
            }
            function resync() {
                if (lw.paused || mp.playbackState !== MediaPlayer.PlayingState || !mp.seekable) return;
                var want = clockMs();
                if (want < 0) return;
                var d = mp.position - want;                       // > 0: the copy is ahead of the desktop
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
                running: !!lw.clock && !lw.paused
                onTriggered: box.resync()
            }
            VideoOutput {
                id: vo
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectCrop
                // nothing is drawn until the first frame has arrived, so the still picture underneath never flashes
                visible: mp.playbackState !== MediaPlayer.StoppedState && mp.hasVideo
                onVisibleChanged: lw.showing = visible
                Component.onDestruction: lw.showing = false
            }
            Connections {
                target: vo.videoSink
                function onVideoFrameChanged() { lw.newFrame(); }
            }
        }
    }
}
