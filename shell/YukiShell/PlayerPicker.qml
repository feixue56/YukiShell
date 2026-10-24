// Which MPRIS player the Now Playing widget and the Menu Bar show.
//
// The old rule was "the first one that is playing, else the first one", which went wrong in two ways:
//   * Browsers often register the same media twice (Chromium itself, with no artwork, no artist and a title like
//     "(3) Song - YouTube", plus plasma-browser-integration with the clean metadata); the first one won.
//   * When nothing played, the pick followed the list order, so the widget jumped around whenever a player came or went.
// Now every player gets a score: playing beats paused, richer metadata (artwork, artist, title, length) beats poorer, and
// the player that started playing most recently breaks ties, so a freshly started player takes over and an old one does not
// steal the widget back.
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Scope {
    id: pk

    property string lastPlayed: ""         // D-Bus name of the player that most recently started playing

    function score(p) {
        var s = 0;
        if (p.isPlaying) s += 100;
        if (p.trackArtUrl !== "") s += 8;
        if (p.trackArtist !== "") s += 4;
        if (p.trackTitle !== "") s += 2;
        if (p.lengthSupported && p.length > 0) s += 1;
        if (p.dbusName === lastPlayed) s += 6;
        return s;
    }

    readonly property var player: {
        var ps = Mpris.players.values, best = null, bs = -1;
        for (var i = 0; i < ps.length; i++) {
            var s = score(ps[i]);
            if (s > bs) { bs = s; best = ps[i]; }
        }
        return best;
    }

    // remember who started playing last (also covers a player that is already playing when the shell starts)
    Instantiator {
        model: Mpris.players
        delegate: QtObject {
            id: watch
            required property var modelData
            readonly property bool playing: modelData.isPlaying
            onPlayingChanged: if (playing) pk.lastPlayed = modelData.dbusName
            Component.onCompleted: if (playing && pk.lastPlayed === "") pk.lastPlayed = modelData.dbusName
        }
    }
}
