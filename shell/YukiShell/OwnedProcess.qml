import QtQuick
import Quickshell.Io

// A Process for helpers that run for as long as the shell wants them (Keep Awake, Night Shift, the audio visualizer, the
// wallpaper-folder and clipboard watchers). A plain Process outlives the shell: when YukiShell exits, restarts or crashes, its
// children are re-parented to init and keep running, so every restart left one more Keep Awake inhibitor (blocking sleep even
// after Keep Awake was switched off) and one more folder watcher behind. Here:
//  - the command runs under `setpriv --pdeathsig TERM`: the kernel sends it SIGTERM the moment the shell process goes away;
//  - destroying the object (a hot reload, a Loader switching it off) sends it SIGTERM too.
// Set `cmd` instead of `command`. YukiBar.qml also sweeps up helpers orphaned by older versions once at start-up (reapOrphans).
Process {
    id: op
    property var cmd: []
    command: (op.cmd && op.cmd.length) ? ["setpriv", "--pdeathsig", "TERM", "--"].concat(op.cmd) : []
    Component.onDestruction: if (op.running) op.signal(15)
}
