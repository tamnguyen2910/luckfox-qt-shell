import QtQuick 2.12
import "Theme.js" as T
import "Utils.js" as Utils

// Status bar: status dot + message (left), elapsed/total time (right)
Item {
    id: root

    readonly property bool dk: appTheme.isDark
    readonly property var tD: T.dark
    readonly property var tL: T.light
    height: 28

    Rectangle {
        anchors.fill: parent
        color: root.dk ? root.tD.headerBg : root.tL.headerBg
        border.color: root.dk ? root.tD.panelBorder : root.tL.panelBorder
        border.width: 1

        Row {
            anchors { left: parent.left; leftMargin: 14; top: parent.top; bottom: parent.bottom }
            spacing: 8

            // Status dot
            Rectangle {
                width: 7
                height: 7
                radius: 3.5
                anchors.verticalCenter: parent.verticalCenter
                color: audioPlayer.isPlaying ? (root.dk ? root.tD.ok : root.tL.ok)
                     : audioPlayer.isPaused ? (root.dk ? root.tD.warn : root.tL.warn)
                     : (root.dk ? root.tD.idle : root.tL.idle)
                Behavior on color { ColorAnimation { duration: 180 } }
            }

            Text {
                text: audioPlayer.statusText
                font.family: T.font
                font.pixelSize: 10
                color: root.dk ? root.tD.textDim : root.tL.textDim
                anchors.verticalCenter: parent.verticalCenter
                width: 500
                elide: Text.ElideMiddle
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Right: position / duration
        Text {
            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
            text: audioPlayer.duration > 0
                  ? Utils.formatTime(audioPlayer.position) + " / " + Utils.formatTime(audioPlayer.duration)
                  : "--:-- / --:--"
            font.family: T.font
            font.pixelSize: 10
            font.bold: true
            color: root.dk ? root.tD.textFaint : root.tL.textFaint
        }
    }
}
