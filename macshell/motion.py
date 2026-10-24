#!/usr/bin/env python3
"""Retune MacShell's Spotlight motion (softer, springier pop). Idempotent; backs up MacBar.qml once.
Re-run after `macshell-update`, which overwrites the QML."""
import pathlib, shutil, sys
p = pathlib.Path.home() / ".config/quickshell/MacShell/MacBar.qml"
s = p.read_text()
bak = p.with_suffix(".qml.pre-rice")
if not bak.exists(): shutil.copy(p, bak)

edits = [
 ("scale: uiS * (ui.spCalm ? 0.98 : 0.97)",
  "scale: uiS * (ui.spCalm ? 0.98 : 0.93)"),
 ("""NumberAnimation { property: "vis"; duration: root.reduceMotion ? 0 : 220; easing.type: Easing.OutCubic }
                                NumberAnimation { property: "scale"; duration: root.reduceMotion ? 0 : 220; easing.type: Easing.OutCubic }""",
  """NumberAnimation { property: "vis"; duration: root.reduceMotion ? 0 : 260; easing.type: Easing.OutQuint }
                                NumberAnimation { property: "scale"; duration: root.reduceMotion ? 0 : 420; easing.type: Easing.OutBack; easing.overshoot: 1.05 }"""),
 ("""NumberAnimation { property: "vis"; duration: root.reduceMotion ? 0 : 160; easing.type: Easing.InCubic }
                                NumberAnimation { property: "scale"; to: spot.uiS * 0.98; duration: root.reduceMotion ? 0 : 160; easing.type: Easing.InCubic }""",
  """NumberAnimation { property: "vis"; duration: root.reduceMotion ? 0 : 180; easing.type: Easing.OutCubic }
                                NumberAnimation { property: "scale"; to: spot.uiS * 0.96; duration: root.reduceMotion ? 0 : 180; easing.type: Easing.OutCubic }"""),
 ("Behavior on y { enabled: spot.vis > 0.99; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }",
  "Behavior on y { enabled: spot.vis > 0.99; NumberAnimation { duration: 240; easing.type: Easing.OutQuint } }"),
]
n = 0
for a, b in edits:
    if b in s: continue
    if a not in s: print("skip (upstream changed):", a[:60]); continue
    s = s.replace(a, b, 1); n += 1
p.write_text(s)
print(f"applied {n} edit(s)")
