import QtQuick

// The highlight under a menu-bar button: a Liquid Glass tile (GlassHover) sized to the button.
// A button's icon uses `scale: hl.lift` for the little pop.
GlassHover {
    anchors.centerIn: parent
    width: parent.width - 2
    height: parent.height - 6
    radius: 8
}
