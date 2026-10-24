#!/usr/bin/env python3
"""Make the Dock's magnification follow the cursor on a critically damped spring (instead of a restarting 55 ms tween),
and ease the hover on/off with a spring too. Idempotent; backs up MacDock.qml once. Re-run after `macshell-update`."""
import pathlib, shutil
p = pathlib.Path.home() / ".config/quickshell/MacShell/MacDock.qml"
s = p.read_text()
bak = p.with_suffix(".qml.pre-rice")
if not bak.exists(): shutil.copy(p, bak)

edits = [
 ("""                property real mx: 0
                Behavior on mx { NumberAnimation { duration: 55; easing.type: Easing.OutQuad } }
""",
  """                property real mxT: 0                                   // where the cursor is
                readonly property real mx: mxSpring.value              // where the magnifier is: a spring chases the cursor
                Spring { id: mxSpring; target: ui.mxT; response: 0.13; damping: 0.92; epsilon: 0.05 }
"""),
 ("onPointChanged: if (hovered && !ui.dragging) ui.mx = point.position.x",
  "onPointChanged: if (hovered && !ui.dragging) { ui.mxT = point.position.x; if (ui.strength < 0.02) mxSpring.snap(); }"),
 ("""                property real strength: active ? 1 : 0
                Behavior on strength { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
""",
  """                readonly property real strength: Math.max(0, Math.min(1, strSpring.value))
                Spring { id: strSpring; target: ui.active ? 1 : 0; response: 0.2; damping: 1.0; epsilon: 0.002 }
"""),
]
n = 0
for a, b in edits:
    if b in s: continue
    if a not in s: print("skip (upstream changed):", a[:60].strip()); continue
    s = s.replace(a, b, 1); n += 1
p.write_text(s)
print(f"applied {n} edit(s)")
