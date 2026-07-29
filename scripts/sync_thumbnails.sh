#!/usr/bin/env bash
# sync_thumbnails.sh
#
# One-shot sync between the wallpaper directory and the thumbnail cache
# used by qs-wallpaper-picker.
#
#   - Generates a thumbnail for every image/video in $WALLPAPER_DIR that
#     doesn't have one yet (or whose source file is newer than its thumb).
#   - Deletes any thumbnail whose source wallpaper no longer exists.
#
# Naming convention (must match WallpaperPicker.qml):
#   image "foo.png"      -> thumb "foo.png"
#   video "foo.mp4"       -> thumb "000_foo.mp4"   (content is a JPEG frame;
#                            the "000_" prefix + original extension is what
#                            the QML uses to detect + reconstruct the source
#                            video file name, Qt's image loader sniffs the
#                            real format from the file header so the mismatched
#                            extension is harmless)
#
# Usage: sync_thumbnails.sh [WALLPAPER_DIR] [THUMB_DIR]

set -u

WALLPAPER_DIR="${1:-$HOME/Wallpapers}"
THUMB_DIR="${2:-$HOME/.cache/wallpaper_picker/thumbs}"
LOG="/tmp/wallpaper-picker-thumbgen.log"

IMAGE_EXTS=(jpg jpeg png webp gif)
VIDEO_EXTS=(mp4 mkv mov webm)

log() { printf '%(%F %T)T %s\n' -1 "$*" >> "$LOG"; }

mkdir -p "$THUMB_DIR"

if command -v magick &>/dev/null; then
    MAGICK_CMD="magick"
elif command -v convert &>/dev/null; then
    MAGICK_CMD="convert"
else
    MAGICK_CMD=""
    log "WARNING: neither 'magick' nor 'convert' (ImageMagick) found, image thumbnails cannot be generated"
fi

HAVE_FFMPEG=0
command -v ffmpeg &>/dev/null && HAVE_FFMPEG=1
[ "$HAVE_FFMPEG" = "0" ] && log "WARNING: ffmpeg not found, video thumbnails cannot be generated"

shopt -s nullglob nocaseglob

# Track every thumbnail filename that SHOULD currently exist, so leftovers
# can be identified and removed afterwards.
declare -A wanted_thumbs

# --- Images -----------------------------------------------------------
if [ -n "$MAGICK_CMD" ]; then
    for ext in "${IMAGE_EXTS[@]}"; do
        for src in "$WALLPAPER_DIR"/*."$ext"; do
            [ -f "$src" ] || continue
            base="$(basename "$src")"
            thumb="$THUMB_DIR/$base"
            wanted_thumbs["$base"]=1

            if [ ! -f "$thumb" ] || [ "$src" -nt "$thumb" ]; then
                tmp="$thumb.tmp.$$"
                if "$MAGICK_CMD" "$src" -auto-orient -resize "x420" -quality 80 "$tmp" 2>>"$LOG"; then
                    mv -f "$tmp" "$thumb"
                    log "generated image thumb: $base"
                else
                    rm -f "$tmp"
                    log "FAILED image thumb: $src"
                fi
            fi
        done
    done
fi

# --- Videos -------------------------------------------------------------
if [ "$HAVE_FFMPEG" = "1" ]; then
    for ext in "${VIDEO_EXTS[@]}"; do
        for src in "$WALLPAPER_DIR"/*."$ext"; do
            [ -f "$src" ] || continue
            base="$(basename "$src")"
            thumbname="000_$base"
            thumb="$THUMB_DIR/$thumbname"
            wanted_thumbs["$thumbname"]=1

            if [ ! -f "$thumb" ] || [ "$src" -nt "$thumb" ]; then
                tmp="$thumb.tmp.$$.jpg"
                # Try grabbing a frame 1s in first (avoids black intro frames);
                # fall back to the very first frame for very short clips.
                if ! ffmpeg -y -ss 00:00:01 -i "$src" -frames:v 1 -vf "scale=-2:420" -q:v 3 "$tmp" >>"$LOG" 2>&1 || [ ! -s "$tmp" ]; then
                    ffmpeg -y -i "$src" -frames:v 1 -vf "scale=-2:420" -q:v 3 "$tmp" >>"$LOG" 2>&1
                fi

                if [ -s "$tmp" ]; then
                    mv -f "$tmp" "$thumb"
                    log "generated video thumb: $thumbname"
                else
                    rm -f "$tmp"
                    log "FAILED video thumb: $src"
                fi
            fi
        done
    done
fi

# --- Prune orphaned thumbnails (source deleted / renamed) --------------
for thumb in "$THUMB_DIR"/*; do
    [ -f "$thumb" ] || continue
    tname="$(basename "$thumb")"
    case "$tname" in
        *.tmp.*) continue ;;
    esac
    if [ -z "${wanted_thumbs[$tname]:-}" ]; then
        rm -f "$thumb"
        log "removed orphan thumb: $tname"
    fi
done
