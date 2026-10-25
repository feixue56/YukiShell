// LiveWall — the animated wallpaper (video) for the Liquid Glass backdrops. The glass of the Dock, the menus, the widgets and the
// Settings window refracts a picture of the wallpaper; for an animated wallpaper this item plays a video (muted) on top of that
// picture, so the glass shows the wallpaper moving in real time.
// `video` is what the shell hands in as bar.glassVideo: "" while "Animated wallpaper in glass" is off (the default), otherwise a small
// 720 px / 30 fps copy of the wallpaper. With `video` empty, `live` false, or the wallpaper a still picture again, the Loader is inactive
// and no decoder exists at all. While `paused` (Game Mode, the menu bar button, "Pause behind windows") the video freezes on its last frame
// at once (a paused decoder costs ~1% of a core, a playing one ~3%), and the decoder is torn down a good while later: a missing one costs
// nothing and frees its GPU memory (~100 MB each), and the still picture underneath is what shows until the video is back.
import QtQuick
import QtMultimedia

Item {
    id: lw
    property string video: ""        // absolute path of the video wallpaper, "" = a still picture
    property bool live: false        // real-time glass switched on
    property bool paused: false      // e.g. the desktop is completely covered by windows
    readonly property bool available: live && video !== ""
    readonly property bool wanted: available && !paused
    // Creating or destroying a decoder runs on the main thread and costs ~120 ms with a hardware (NVDEC) one, and the shell has several of
    // them (bar, Dock, the desktop widgets). Doing that in the same instant froze the whole shell for up to 2 s, so everything it animates
    // (the Dock sliding away, the bar) started late.
    //   * pausing and resuming a decoder that exists is instant, so a short pause never touches the decoders;
    //   * a decoder is only torn down once the pause has LASTED (30-60 s, a different moment for each), and resuming earlier cancels the teardown;
    //   * a decoder that is gone is started again at a random moment within ~5 s of the resume (they would keep the main thread busy
    //     for good if they all started together), the still picture shows until then.
    property bool active: wanted
    onWantedChanged: {
        if (wanted) {
            stopT.stop();
            if (!active) { startT.interval = 300 + Math.random() * 4700; startT.restart(); }
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
            onHoldChanged: { if (hold) mp.pause(); else mp.play(); }
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
