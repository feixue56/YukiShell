import QtQuick
import QtQuick.Shapes

// Draws the audio spectrum from AudioVis.qml: rising bars, bars growing both ways from the middle, or a smooth wave.
//
//   VisBars { src: hub.vis; active: playing && visualizerOn; style: "bars"; colorTop: ...; colorBottom: ... }
//
// While `active` it asks the source to listen (and tells it to stop again when hidden / destroyed). `demo` draws a slow made-up
// pattern instead of the real sound (the Settings preview, the widget gallery).
Item {
    id: vb

    property var src: null
    property bool active: false
    property bool demo: false
    property string style: "bars"             // bars | mirror | wave
    property color colorTop: "white"
    property color colorBottom: Qt.rgba(1, 1, 1, 0.15)
    property real gain: 1.0
    property int count: 32                    // how many bars (the wave always uses all 32 points)
    property real barFill: 0.62               // width of a bar as a share of its slot

    readonly property bool live: active && visible
    readonly property string key: "vb" + Math.random().toString(36).slice(2)
    property var fake: []
    readonly property var lv: demo ? fake : (src ? src.bars : [])
    opacity: active ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    function sync() { if (vb.src && !vb.demo) vb.src.want(vb.key, vb.live); }
    onLiveChanged: sync()
    onSrcChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: { if (vb.src) vb.src.want(vb.key, false); }

    // the made-up pattern: a few travelling sine humps
    property real phase: 0
    Timer {
        interval: 40; repeat: true; running: vb.demo && vb.live
        onTriggered: {
            vb.phase += 0.12;
            var a = [];
            for (var i = 0; i < 32; i++) a.push(Math.max(0.05, 0.5 + 0.28 * Math.sin(vb.phase + i * 0.45) + 0.2 * Math.sin(vb.phase * 1.7 + i * 0.9)) * (1 - i / 60));
            vb.fake = a;
        }
    }

    // value (0..1) of slot i out of `n`
    function level(i, n) {
        var d = vb.lv, m = d ? d.length : 0;
        if (m === 0) return 0;
        var v = d[Math.min(m - 1, Math.floor(i * m / n))] * vb.gain;
        return Math.min(1, Math.pow(Math.max(0, v), 0.85));
    }

    // --- bars / mirror ---
    Repeater {
        model: vb.style === "wave" ? 0 : vb.count
        delegate: Rectangle {
            required property int index
            readonly property real slot: vb.width / vb.count
            readonly property real bw: Math.max(2, slot * vb.barFill)
            readonly property real lvl: vb.level(index, vb.count)
            width: bw
            height: Math.max(bw, lvl * vb.height)
            x: index * slot + (slot - bw) / 2
            y: vb.style === "mirror" ? (vb.height - height) / 2 : vb.height - height
            radius: bw / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: vb.colorTop }
                GradientStop { position: 1.0; color: vb.style === "mirror" ? vb.colorTop : vb.colorBottom }
            }
        }
    }

    // --- wave: the 32 values joined by a smooth curve, filled below ---
    readonly property var wavePts: {
        if (vb.style !== "wave") return [];
        var n = 32, y = [], pts = [], i, k;
        for (i = 0; i < n; i++) y.push(vb.height - (0.06 + 0.9 * vb.level(i, n)) * vb.height);
        var steps = 4;
        for (i = 0; i < n - 1; i++) {
            var p0 = y[Math.max(0, i - 1)], p1 = y[i], p2 = y[i + 1], p3 = y[Math.min(n - 1, i + 2)];
            for (k = 0; k < steps; k++) {                               // Catmull-Rom between p1 and p2
                var t = k / steps, t2 = t * t, t3 = t2 * t;
                var yy = 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3);
                pts.push(Qt.point((i + t) / (n - 1) * vb.width, Math.max(0, Math.min(vb.height, yy))));
            }
        }
        pts.push(Qt.point(vb.width, y[n - 1]));
        return pts;
    }
    // the same points closed along the bottom edge (a PathPolyline starts at its own first point, so the closing corners are points too)
    readonly property var fillPts: wavePts.length > 0 ? [Qt.point(0, vb.height)].concat(wavePts, [Qt.point(vb.width, vb.height)]) : []
    Shape {
        visible: vb.style === "wave"
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {                                    // the fill under the line
            strokeWidth: -1
            fillGradient: LinearGradient {
                x1: 0; y1: 0; x2: 0; y2: vb.height
                GradientStop { position: 0.0; color: Qt.rgba(vb.colorTop.r, vb.colorTop.g, vb.colorTop.b, vb.colorTop.a * 0.55) }
                GradientStop { position: 1.0; color: vb.colorBottom }
            }
            startX: 0; startY: vb.height
            PathPolyline { path: vb.fillPts }
        }
        ShapePath {                                    // the line itself
            strokeWidth: 2.2
            strokeColor: vb.colorTop
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 0; startY: vb.wavePts.length > 0 ? vb.wavePts[0].y : vb.height
            PathPolyline { path: vb.wavePts }
        }
    }
}
