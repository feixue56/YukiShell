// LiveWall — the animated wallpaper (video) for the Liquid Glass backdrops. The glass of the Dock, the menus, the widgets and the
// Settings window refracts a picture of the wallpaper; for an animated wallpaper this item plays a video (muted) on top of that
// picture, so the glass shows the wallpaper moving in real time.
// `video` is what the shell hands in as bar.glassVideo: "" while "Animated wallpaper in glass" is off (the default), otherwise a small
// 720 px / 30 fps copy of the wallpaper. With `video` empty, `live` false, or the wallpaper a still picture again, the Loader is inactive
// and no decoder exists at all. While `paused` (desktop covered by windows, Game Mode) the decoder is torn down as well, a while later: a paused
// QMediaPlayer still costs about as much as a playing one (measured: ~7% of a core and ~400 MB of GPU memory per shell), a missing one
// costs nothing, and the still picture underneath is what shows until the video is back.
import QtQuick
import QtMultimedia

Item {
    id: lw
    property string video: ""        // absolute path of the video wallpaper, "" = a still picture
    property bool live: false        // real-time glass switched on
    property bool paused: false      // e.g. the desktop is completely covered by windows
    readonly property bool available: live && video !== ""
    readonly property bool wanted: available && !paused
    // Creating or destroying a decoder runs on the main thread and costs ~120 ms with a hardware (NVDEC) one, and the shell has a dozen of
    // them (bar, Dock, every desktop widget). Doing that in the same instant froze the whole shell for 1-2 s each time a window covered the
    // desktop or uncovered it again, so everything it animates (the Dock sliding away, the bar) started late while you moved between workspaces.
    //   * a decoder is only torn down once the desktop has STAYED covered for a while (6-20 s, a different moment for each), so flipping
    //     between workspaces never touches them, and uncovering within that time cancels the teardown;
    //   * a decoder that is gone is started again at a random moment within ~5 s of the uncover (a dozen of them at ~120 ms each would keep
    //     the main thread busy for good if they all started together), the still picture shows until then.
    property bool active: wanted
    onWantedChanged: {
        if (wanted) {
            stopT.stop();
            if (!active) { startT.interval = 300 + Math.random() * 4700; startT.restart(); }
        } else if (active) {
            startT.stop();
            // switched off for good (no video, real-time glass off): gone at once. Only a covered desktop waits.
            if (!available) active = false;
            else { stopT.interval = 6000 + Math.random() * 14000; stopT.restart(); }
        }
    }
    Timer { id: stopT; onTriggered: lw.active = false }
    Timer { id: startT; onTriggered: lw.active = lw.wanted }

    Loader {
        anchors.fill: parent
        active: lw.active
        sourceComponent: Item {
            id: box
            MediaPlayer {
                id: mp
                source: "file://" + lw.video
                loops: MediaPlayer.Infinite
                videoOutput: vo
                Component.onCompleted: play()
            }
            VideoOutput {
                id: vo
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectCrop
                // nothing is drawn until the first frame has arrived, so the still picture underneath never flashes
                visible: mp.playbackState !== MediaPlayer.StoppedState && mp.hasVideo
            }
        }
    }
}
