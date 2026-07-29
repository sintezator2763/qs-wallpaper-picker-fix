import QtQuick
import QtQuick.Controls
import Quickshell
import "."
import "WindowRegistry.js" as LayoutMath

FloatingWindow {
    id: root
    visible: true
    title: "wallpaper-picker"
    color: "transparent"

    onVisibleChanged: {
        if (!visible) {
            Qt.quit()
        }
    }

    // Always spans the full monitor width. Height uses the same
    // width-based scale formula the internal UI (Scaler.qml) uses for its
    // own element sizing, so the window's outer size always matches what
    // the layout inside actually needs - it never gets squished by an
    // outer size that doesn't match the content's natural size.
    implicitWidth: Screen.width
    implicitHeight: Math.round(LayoutMath.s(650, LayoutMath.getScale(Screen.width)))

    Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
    }

    WallpaperPicker {
        anchors.fill: parent
        focus: true
    }
}
