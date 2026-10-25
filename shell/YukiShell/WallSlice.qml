// WallSlice — a piece of a shared LiveWall (see LiveWall.qml), for glass that sits in the same window as that LiveWall. It draws the
// part of `wall` at `sx, sy` (in the wall's own coordinates) at its own size, without a decoder of its own: the desktop widgets used to run
// one video player each, twice over (the widgets and their copies in the bar's backdrop): with the bar, Dock and popups that was
// 15 players for one wallpaper.
import QtQuick

ShaderEffectSource {
    id: ws
    property Item wall: null
    property real sx: 0
    property real sy: 0
    sourceItem: wall
    sourceRect: Qt.rect(sx, sy, width, height)
    // redrawn once per new video frame (and when it moves), not on every change of the scene
    live: false
    Connections {
        target: ws.wall
        function onNewFrame() { ws.scheduleUpdate(); }
    }
    onWallChanged: scheduleUpdate()
    onSxChanged: scheduleUpdate()
    onSyChanged: scheduleUpdate()
    onWidthChanged: scheduleUpdate()
    onHeightChanged: scheduleUpdate()
    hideSource: false
    // a texture for an effect (MultiEffect source), never drawn itself
    visible: false
    readonly property bool ready: wall !== null && wall.showing
}
