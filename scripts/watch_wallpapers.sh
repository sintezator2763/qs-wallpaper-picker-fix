#!/usr/bin/env bash
# watch_wallpapers.sh
#
# Runs sync_thumbnails.sh once immediately, then watches $WALLPAPER_DIR with
# inotifywait and re-runs the sync whenever wallpapers are added, removed, or
# renamed - so the thumbnail cache always matches the wallpaper folder,
# whether or not the picker window is currently open.
#
# Safe to launch multiple times (e.g. every time the picker starts): a lock
# file guarantees only one watcher instance is ever running.
#
# Usage: watch_wallpapers.sh [WALLPAPER_DIR] [THUMB_DIR]

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLPAPER_DIR="${1:-$HOME/Wallpapers}"
THUMB_DIR="${2:-$HOME/.cache/wallpaper_picker/thumbs}"
LOCK_FILE="/tmp/wallpaper-picker-watch.lock"
LOG="/tmp/wallpaper-picker-thumbgen.log"

log() { printf '%(%F %T)T %s\n' -1 "$*" >> "$LOG"; }

mkdir -p "$WALLPAPER_DIR" "$THUMB_DIR"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    # Another watcher is already running - just do a one-off sync in case
    # anything changed since it last ran, then exit.
    "$SCRIPT_DIR/sync_thumbnails.sh" "$WALLPAPER_DIR" "$THUMB_DIR"
    exit 0
fi

log "=== watcher starting: wallpapers=$WALLPAPER_DIR thumbs=$THUMB_DIR ==="

# Initial sync so thumbnails exist even for wallpapers that were added
# before the watcher/picker ever ran.
"$SCRIPT_DIR/sync_thumbnails.sh" "$WALLPAPER_DIR" "$THUMB_DIR"

if ! command -v inotifywait &>/dev/null; then
    log "inotifywait not found (install inotify-tools) - live watching disabled, initial sync only"
    exit 1
fi

# Coalesce bursts of events (e.g. copying 50 wallpapers at once) into a
# single sync run instead of one per file.
while true; do
    if read -r -t 3600 _; then
        while read -r -t 0.5 _; do :; done
        "$SCRIPT_DIR/sync_thumbnails.sh" "$WALLPAPER_DIR" "$THUMB_DIR"
    fi
done < <(inotifywait -m -q -e create -e delete -e moved_to -e moved_from --format '%f' "$WALLPAPER_DIR" 2>>"$LOG")
