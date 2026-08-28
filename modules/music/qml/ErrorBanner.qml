import QtQuick 2.12
import "Theme.js" as T

// Inline error banner — auto-dismiss 5s, warn color, 24px compact
Item {
    id: root

    readonly property bool dk: appTheme.isDark
    readonly property var tD: T.dark
    readonly property var tL: T.light
    visible: false                    // hidden by default — avoid covering header on startup
    height: visible ? 24 : 0
    opacity: visible ? 1 : 0
    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 120 } }
    clip: true

    function show(message) {
        msg.text = message;
        visible = true;
        timer.restart();
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: 3
        color: root.dk ? root.tD.bannerBg : root.tL.bannerBg
        border.color: root.dk ? root.tD.warn : root.tL.warn
        border.width: 1

        Text {
            id: msg
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            font.family: T.FONT
            font.pixelSize: 10
            font.bold: true
            color: root.dk ? root.tD.warn : root.tL.warn
            elide: Text.ElideRight
        }
    }
    Timer { id: timer; interval: 5000; onTriggered: root.visible = false }
}
