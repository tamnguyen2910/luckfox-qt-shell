import QtQuick 2.12
import "Theme.js" as T

// Rotating vinyl disc — clean record look, no sheen trapezoid overlay
Item {
    id: root

    readonly property bool dk: appTheme.isDark
    readonly property var tD: T.dark
    readonly property var tL: T.light

    property color accentStart: root.dk ? root.tD.accent : root.tL.accent
    property color accentEnd: root.dk ? root.tD.accent2 : root.tL.accent2

    Rectangle {
        id: disc
        width: parent.width
        height: parent.height
        radius: width / 2
        color: root.dk ? root.tD.disc : root.tL.disc
        clip: true

        // Groove rings
        Rectangle {
            width: parent.width - 24
            height: parent.height - 24
            radius: width / 2
            anchors.centerIn: parent
            color: "transparent"
            border.width: 1
            border.color: root.dk ? root.tD.groove : root.tL.groove
        }
        Rectangle {
            width: parent.width - 48
            height: parent.height - 48
            radius: width / 2
            anchors.centerIn: parent
            color: "transparent"
            border.width: 1
            border.color: root.dk ? root.tD.groove : root.tL.groove
        }
        Rectangle {
            width: parent.width - 72
            height: parent.height - 72
            radius: width / 2
            anchors.centerIn: parent
            color: "transparent"
            border.width: 1
            border.color: root.dk ? root.tD.groove : root.tL.groove
        }

        // Label / center sticker
        Rectangle {
            width: parent.width * 0.42
            height: parent.width * 0.42
            radius: width / 2
            anchors.centerIn: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: accentStart }
                GradientStop { position: 1.0; color: accentEnd }
            }
            border.color: root.dk ? root.tD.bezel : root.tL.bezel
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 2
                Image {
                    source: "qrc:/music/icons/music_note.svg"
                    width: parent.parent.width * 0.22
                    height: parent.parent.width * 0.22
                    anchors.horizontalCenter: parent.horizontalCenter
                    fillMode: Image.PreserveAspectFit
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "LUCKFOX"
                    font.family: T.FONT
                    font.pixelSize: 6
                    font.bold: true
                    font.letterSpacing: 1.5
                    color: root.dk ? root.tD.textOnAccent : root.tL.textOnAccent
                }
            }
        }

        // Pause ring overlay while paused/stopped
        Rectangle {
            anchors.fill: parent
            color: root.dk ? "#000000" : "#1A2332"
            radius: width / 2
            opacity: (audioPlayer.isPlaying) ? 0 : 0.28
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Text {
                anchors.centerIn: parent
                text: audioPlayer.isPaused ? "II" : ""
                font.pixelSize: 24
                font.bold: true
                color: root.dk ? "#E0E8FF" : "#F4F6FA"
            }
        }

        // Spinning — preserves current rotation angle on pause/resume
        RotationAnimation on rotation {
            running: audioPlayer.isPlaying
            from: rotation        // continue from current angle (no reset)
            to: rotation + 360    // re-evaluated each loop → endless spin
            duration: 6000
            loops: Animation.Infinite
        }
    }

    // Outer glow ring (accent when playing) — pulsing glow
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: audioPlayer.isPlaying ? accentStart : (root.dk ? root.tD.bezel : root.tL.bezel)
        opacity: audioPlayer.isPlaying ? 0.55 : 0.9
        Behavior on border.color { ColorAnimation { duration: 220 } }

        // Pulsing glow — breathing ring while playing
        SequentialAnimation on border.width {
            running: audioPlayer.isPlaying
            loops: Animation.Infinite
            NumberAnimation { to: 4; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 2; duration: 700; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on opacity {
            running: audioPlayer.isPlaying
            loops: Animation.Infinite
            NumberAnimation { to: 0.85; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.5; duration: 700; easing.type: Easing.InOutSine }
        }
    }
}
