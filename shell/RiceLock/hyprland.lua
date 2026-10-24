-- Paste this into your existing Lua-driven Hyprland config.
-- The wrapper starts MacLock in IPC daemon mode if needed, waits for its endpoint,
-- and then locks. Update the path if you installed MacLock elsewhere.
hl.bind("SUPER + L", hl.dsp.exec_cmd("sh ~/.config/quickshell/RiceLock/lock-via-ipc.sh"))
