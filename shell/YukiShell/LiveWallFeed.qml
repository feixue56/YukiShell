import QtQuick
import QtMultimedia
import YukiVideo

// A window's LiveWall when the YukiVideo plugin is installed: no player of its own, it shows the frames of the shell's one
// WallPlayer. It tells WallFeed whether it wants the video playing (lw.wanted) or only shows it paused, and while paused it takes
// no new frames and keeps the last one.
Item {
    id: f
    required property Item lw
    readonly property string key: "lw" + Math.floor(Math.random() * 1e9) + "-" + Date.now()
    readonly property bool playing: lw.wanted
    property bool got: false                     // a frame has arrived: the video covers the still picture underneath

    Component.onCompleted: WallFeed.want(key, playing)
    Component.onDestruction: { WallFeed.release(key); if (f.lw) f.lw.showing = false; }

    VideoOutput {
        id: vo
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: f.got
        onVisibleChanged: if (f.lw) f.lw.showing = visible
    }
    WallFeedOutput {
        target: vo.videoSink
        enabled: f.playing || !f.got             // paused: keeps its last frame (after taking a first one)
    }
    Connections {
        target: vo.videoSink
        function onVideoFrameChanged() { f.got = true; f.lw.newFrame(); }
    }
}
