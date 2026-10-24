#!/usr/bin/env python3
"""Remove the 'Help' entry from MacShell's menu bar. Idempotent; re-run after `macshell-update`."""
import pathlib, shutil
p = pathlib.Path.home() / ".config/quickshell/MacShell/MacBar.qml"
s = p.read_text()
bak = p.with_suffix(".qml.pre-rice")
if not bak.exists(): shutil.copy(p, bak)
a = '''        { id: "window", label: I18n.tr("Window") },
        { id: "help", label: I18n.tr("Help") }
'''
b = '''        { id: "window", label: I18n.tr("Window") }
'''
if a in s: p.write_text(s.replace(a, b, 1)); print("removed Help")
else: print("nothing to do")
