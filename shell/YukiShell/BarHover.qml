import QtQuick

// The highlight under a menu-bar button: a pill that springs in under the pointer, deepens while pressed,
// and keeps an accent tint while the button's popover is open. A button's icon uses `scale: hl.lift` for the little pop.
Rectangle {
    id: hl

    property bool hot: false        // the pointer is over the button
    property bool pressed: false
    property bool open: false       // its popover (or, for a workspace, the workspace itself) is active
    property color accent: "#bf5af2"

    property real lift: pressed ? 0.92 : (hot ? 1.16 : 1)
    Behavior on lift { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 2.6 } }

    property real strength: pressed ? 0.36 : (open ? 0.30 : (hot ? 0.20 : 0))
    Behavior on strength { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    anchors.centerIn: parent
    width: parent.width - 2
    height: parent.height - 6
    radius: 6
    visible: strength > 0.005
    color: Qt.rgba(accent.r, accent.g, accent.b, strength)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, Math.min(1, strength * 2.2))

    scale: (hot || open) ? 1 : 0.86
    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2.2 } }
}
