import QtQuick
import Quickshell
import Quickshell.Io

// Audio spectrum for the visualizers (the Now Playing widget and Control Center tile).
//
// One `cava` process for the whole shell listens to what the speakers play and prints a line of bar heights per frame; they become
// `bars` (count values, 0..1). It only runs while something that draws a visualizer has asked for it (VisBars.qml calls want()
// when it is shown, music is playing and the visualizer is switched on), so a silent desktop costs nothing.
// Without cava `available` is false and the visualizers simply stay out of the way.
Scope {
    id: av

    readonly property int count: 128               // the most columns a visualizer can show (Settings -> Columns)
    property var bars: av.zeros()                  // newest frame: `count` numbers 0..1
    property bool available: true
    readonly property bool wanted: nwant > 0

    function zeros() { var z = []; for (var i = 0; i < av.count; i++) z.push(0); return z; }

    // who is looking: want("some-key", true) while shown, want("some-key", false) when not
    property var wanters: ({})
    property int nwant: 0
    function want(key, on) {
        var had = av.wanters[key] === true;
        if (on === had) return;
        if (on) av.wanters[key] = true; else delete av.wanters[key];
        av.nwant = Object.keys(av.wanters).length;
    }

    property string lastLine: ""
    function feed(line) {
        if (line === av.lastLine) return;          // nothing moved (silence, a held note): don't redraw every visualizer for it
        av.lastLine = line;
        var p = line.split(";"), out = [], n = Math.min(av.count, p.length);
        for (var i = 0; i < av.count; i++) {
            var v = i < n ? parseInt(p[i]) : 0;
            out.push(isNaN(v) ? 0 : Math.max(0, Math.min(1, v / 100)));
        }
        av.fails = 0;
        av.bars = out;
    }

    // cava is looked for once; a missing binary switches the visualizers off for the session
    property int fails: 0
    Process {
        id: check
        running: true
        command: ["sh", "-c", "command -v cava >/dev/null 2>&1 && echo yes"]
        stdout: StdioCollector { onStreamFinished: av.available = text.indexOf("yes") >= 0 }
    }
    Timer { id: retry; interval: 4000 }
    OwnedProcess {
        id: cava
        running: av.wanted && av.available && !retry.running
        // the config is written next to the runtime files each time: mono, 128 bars, 60 frames/s, values 0..100 separated by ";".
        // 60 frames/s and light smoothing (noise_reduction 25; it was 30 frames/s and 60) so the bars jump with the beat instead of
        // gliding after it; much less smoothing makes them jittery
        cmd: ["sh", "-c",
            "cfg=\"${XDG_RUNTIME_DIR:-/tmp}/yukishell-cava.conf\"; "
            + "printf '%s\\n' '[general]' \"bars = $1\" 'framerate = 60' '[input]' 'method = pipewire' '[output]' 'method = raw' 'channels = mono' 'mono_option = average' "
            + "'raw_target = /dev/stdout' 'data_format = ascii' 'ascii_max_range = 100' 'bar_delimiter = 59' 'frame_delimiter = 10' '[smoothing]' 'noise_reduction = 25' > \"$cfg\"; "
            + "exec cava -p \"$cfg\"", "sh", String(av.count)]
        stdout: SplitParser { onRead: line => av.feed(line) }
        onExited: {
            av.bars = av.zeros();
            av.lastLine = "";
            if (!av.wanted) return;                      // stopped on purpose
            if (++av.fails >= 4) av.available = false;   // it keeps dying: give up for this session
            else retry.restart();
        }
    }
}
