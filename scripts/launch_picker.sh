#!/usr/bin/env bash
# launch_picker.sh
#
# Single-instance launcher for the wallpaper picker. Launch the picker
# through this script (from a keybind, Rofi, a Waybar button, wherever)
# instead of calling `quickshell -p Main.qml` directly:
#
#   - Not running yet -> launches it.
#   - Already running  -> closes the existing window instead of opening a
#     second copy, so the same trigger acts as an open/close toggle.
#
# This uses a real flock() held on a file descriptor for the entire
# lifetime of the quickshell process (kept open across `exec`), which is
# atomic - unlike checking window lists (e.g. `hyprctl clients` / Lua
# `hl.get_windows`), where two near-simultaneous launches can both observe
# "not running yet" and both proceed. That race is exactly what this
# script closes, on top of whatever toggle logic you may already have at
# the compositor/keybind level.
#
# Usage: launch_picker.sh [path/to/Main.qml]

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QML_ENTRY="${1:-$SCRIPT_DIR/../Main.qml}"
LOCK_FILE="/tmp/wallpaper-picker.lock"
WINDOW_TITLE="wallpaper-picker"

exec 8>"$LOCK_FILE"
if ! flock -n 8; then
    # Another instance already holds the lock - close it instead of
    # spawning a second one.
    if command -v hyprctl &>/dev/null; then
        hyprctl dispatch closewindow "title:^${WINDOW_TITLE}$" >/dev/null 2>&1
    fi
    exit 0
fi

exec quickshell -p "$QML_ENTRY"
