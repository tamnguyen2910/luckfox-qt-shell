import QtQuick 2.12
import "Theme.js" as Theme

// DayDetailPanel v3 — KEPT only for resources.qrc validity (right-panel hero-only
// in v3, no detail card). Unused by MainScreen. Do not import elsewhere.
Rectangle {
    id: detailPanel
    width: Theme.Theme.layout.rightWidth
    height: parent ? parent.height : Theme.Theme.layout.height
    color: Theme.Theme.palette.surface

    property var selectedDay: null

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Theme.Theme.palette.border
    }

    Text {
        anchors.centerIn: parent
        text: "unused (v3)"
        font.pixelSize: Theme.Theme.font.small
        font.family: "DejaVu Sans"
        color: Theme.Theme.palette.textMuted
    }
}
