import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// The empty desktop takes the keyboard focus. Hyprland (0.57) has no option to unfocus a window when the pointer leaves it for
// the desktop: the window kept its active border and every key typed went into it. Hyprland does hand the keyboard to an
// "on demand" layer surface the pointer moves onto (with focus following the mouse), so an invisible full-screen surface on the
// background layer, under every window, takes it there, and the window gets it back the moment the pointer re-enters it. It
// never grabs the keyboard: new windows, Spotlight and keyboard shortcuts take focus as usual.
// Only while focus follows the mouse (Settings -> Cursor); with click-to-focus the desktop does not take focus on hover.
// The wallpaper programs (mpvpaper, awww) share the background layer, and a surface opened later sits on top: when one opens a
// surface (a wallpaper change restarts them) this one is made again, so it stays above them.
Scope {
    id: df
    property bool enabled: true
    property bool cycling: false
    // the desktop holds the keyboard right now. Hyprland still calls the window it left "active" (its border, activewindow), so
    // YukiBar draws that border in the inactive colour and the menu bar names the Desktop while this is true.
    property bool focused: false
    property bool hovered: false     // the pointer is on the empty desktop
    property bool grab: false        // taking the keyboard for a moment (see onRawEvent)
    property string lastActive: ""   // address of the focused window (Hyprland's events write it without "0x")

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "openlayer" && event.data.indexOf("yuki") !== 0 && event.data !== "quickshell") cycleT.restart();
            // a window closed: Hyprland gives focus to the window under the pointer (input:focus_on_close = 1), but with only the
            // desktop there it falls back to another window. Take the keyboard back to the desktop then, so focus stays where the
            // pointer is instead of jumping to a window the pointer is not on.
            // Only when the window that closed had focus: another window closing somewhere must not take the keyboard from yours.
            else if (event.name === "closewindow" && event.data === df.lastActive) closeT.restart();
            else if (event.name === "activewindowv2") df.lastActive = event.data;
        }
    }
    Timer { id: cycleT; interval: 400; onTriggered: { df.cycling = true; df.cycling = false; } }
    // after Hyprland has refocused and told the surfaces where the pointer now is
    Timer { id: closeT; interval: 90; onTriggered: if (df.enabled && df.hovered && !df.focused) { df.grab = true; grabT.restart(); } }
    // EXCLUSIVE only for an instant: long enough for Hyprland to move the keyboard here, then back to on-demand so any window,
    // Spotlight or shortcut can take it again
    Timer { id: grabT; interval: 120; onTriggered: df.grab = false }

    Variants {
        model: (df.enabled && !df.cycling) ? Quickshell.screens : []
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { left: true; right: true; top: true; bottom: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "yukidesktop"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.keyboardFocus: df.grab ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
            Item {
                anchors.fill: parent
                focus: true
                onActiveFocusChanged: df.focused = activeFocus
                HoverHandler { onHoveredChanged: df.hovered = hovered }
                Component.onDestruction: { df.focused = false; df.hovered = false; }
            }
        }
    }
}
