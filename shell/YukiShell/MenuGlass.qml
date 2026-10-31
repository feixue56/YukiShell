import QtQuick
import QtQuick.Effects

// The Liquid Glass behind a pop-up menu in Settings (SPopUp, ColorChoice): the same glass as the menu bar's menus, refracting the
// Settings page under the menu. The page is captured only while the menu is open. A pop-up lives in the window's overlay, so the
// page (the top item under the window's contentItem) never contains the menu itself.
// Without Liquid Glass (shader not ready, Game Mode) it is the plain menu card it used to be.
Item {
    id: mg
    required property var t             // the Settings palette (pal in YukiDock.qml): colours + the glass settings
    required property Item from         // the button that opened the menu (to find the window's page)
    property bool open: false
    property real cornerR: 12

    readonly property bool glassOn: t.glassReady === true && page !== null
    readonly property Item page: {
        var ci = from ? from.Window.contentItem : null;
        if (!ci) return null;
        var p = from;
        while (p && p.parent && p.parent !== ci) p = p.parent;
        return (p && p.parent === ci) ? p : null;
    }
    // where the menu sits on the page (refreshed while it opens: it scales in, and Qt may shift it to fit the window)
    property point org: Qt.point(0, 0)
    function remap() { if (page) org = mg.mapToItem(page, 0, 0); }
    property int ticks: 0
    Timer {
        id: follow
        interval: 30; repeat: true
        onTriggered: { mg.remap(); if (++mg.ticks > 14) stop(); }
    }
    onOpenChanged: if (open) { ticks = 0; remap(); follow.restart(); }
    onWidthChanged: if (open) remap()
    onHeightChanged: if (open) remap()

    ShaderEffectSource {
        id: pageSrc
        sourceItem: (mg.open && mg.glassOn) ? mg.page : null
        hideSource: false
        live: mg.open
        mipmap: true
        visible: false
    }
    GlassSlab {
        anchors.fill: parent
        visible: mg.glassOn
        src: pageSrc
        srcSize: mg.page ? Qt.size(mg.page.width, mg.page.height) : Qt.size(1, 1)
        origin: mg.org
        cornerR: mg.cornerR
        glass: mg.glassOn
        shaderUrl: mg.t.shaderUrl
        dark: mg.t.dark
        thickness: 22
        liquid: mg.t.gLiquid
        rim: mg.t.gRim
        grain: mg.t.gGrain
        tint: mg.t.gTint
        blurPx: Math.max(1.5, mg.t.gBlur)
        shadowAmt: 0
        flatInner: 1
    }
    // without glass: the solid menu card, with its soft shadow
    RectangularShadow { visible: !mg.glassOn; anchors.fill: parent; radius: mg.cornerR; blur: 24; offset.y: 8; color: Qt.rgba(0, 0, 0, 0.35) }
    Rectangle {
        anchors.fill: parent; radius: mg.cornerR
        color: mg.glassOn ? "transparent" : (mg.t.dark ? Qt.rgba(0.16, 0.16, 0.18, 0.985) : Qt.rgba(0.98, 0.98, 0.99, 0.99))
        border.width: 1; border.color: mg.t.dark ? Qt.rgba(1, 1, 1, 0.13) : Qt.rgba(0, 0, 0, 0.10)
    }
}
