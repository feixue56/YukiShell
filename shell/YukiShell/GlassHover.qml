import QtQuick

// A small Liquid Glass tile that springs in under the pointer: a frosted white body that is brighter at the top, a soft
// specular band along the upper half, a hairline edge, and a crisp rim light that follows the cursor (contourglow.frag).
// It is used for the menu-bar buttons (BarHover) and for the hovered dock icon. Size, position and radius come from the user;
// give `area` the MouseArea the pointer is over so the rim light can follow it.
Rectangle {
    id: g

    property bool hot: false        // the pointer is over it
    property bool pressed: false
    property bool open: false       // it is the active one (its popover is open, or it is the current workspace)
    property bool dark: true
    property Item area: null

    // the icon on top uses `scale: g.lift` for a small overshoot pop
    property real lift: pressed ? 0.92 : (hot ? 1.16 : 1)
    Behavior on lift { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 2.6 } }

    property real amt: pressed ? 1.0 : (open ? 0.85 : (hot ? 0.7 : 0))
    Behavior on amt { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    visible: amt > 0.005
    scale: (hot || open) ? 1 : 0.86
    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2.2 } }

    gradient: Gradient {
        GradientStop { position: 0.0; color: g.dark ? Qt.rgba(1, 1, 1, 0.30 * g.amt) : Qt.rgba(1, 1, 1, 0.80 * g.amt) }
        GradientStop { position: 1.0; color: g.dark ? Qt.rgba(1, 1, 1, 0.09 * g.amt) : Qt.rgba(1, 1, 1, 0.40 * g.amt) }
    }
    border.width: 1
    border.color: g.dark ? Qt.rgba(1, 1, 1, 0.20 * g.amt) : Qt.rgba(0, 0, 0, 0.12 * g.amt)

    // specular band
    Rectangle {
        x: 1; y: 1
        width: parent.width - 2
        height: parent.height * 0.52
        radius: Math.max(0, g.radius - 1)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, (g.dark ? 0.30 : 0.55) * g.amt) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
        }
    }

    // rim light along the outline, brightest next to the cursor
    ShaderEffect {
        readonly property real pad: 14
        anchors.fill: parent
        anchors.margins: -pad
        visible: amount > 0.005
        fragmentShader: Qt.resolvedUrl("contourglow.frag.qsb")
        property vector2d itemSize: Qt.vector2d(width, height)
        property vector2d mouse: g.area ? Qt.vector2d(g.area.mouseX - g.x, g.area.mouseY - g.y) : Qt.vector2d(g.width / 2, g.height / 2)
        property real cornerR: g.radius
        property real amount: (g.hot || g.pressed) ? 1 : (g.open ? 0.45 : 0)
        Behavior on amount { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        property real spread: Math.max(14, Math.min(g.width, g.height) * 0.9)
        property vector4d tint: Qt.vector4d(1, 1, 1, 1)
    }
}
