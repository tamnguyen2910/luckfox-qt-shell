import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "Theme.js" as T

// Header: logo + title + track count badge + error banner
Item {
    id: root
    height: 48

    readonly property bool dk: appTheme.isDark
    readonly property var tD: T.dark
    readonly property var tL: T.light

    Rectangle {
        anchors.fill: parent
        color: root.dk ? root.tD.headerBg : root.tL.headerBg
    }

    // Bottom hairline accent
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.dk ? "#001DB954" : "#00169C46" }
            GradientStop { position: 0.5; color: root.dk ? "#591DB954" : "#59169C46" }
            GradientStop { position: 1.0; color: root.dk ? "#001DB954" : "#00169C46" }
        }
    }

    Row {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        // ----- Logo -----
        Rectangle {
            width: 34
            height: 34
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.dk ? root.tD.accent : root.tL.accent }
                GradientStop { position: 1.0; color: root.dk ? root.tD.accent2 : root.tL.accent2 }
            }
            Image {
                source: "qrc:/music/icons/music_note.svg"
                width: 18
                height: 18
                anchors.centerIn: parent
                fillMode: Image.PreserveAspectFit
            }
        }

        // ----- Branding -----
        Column {
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: "Music Player"
                font.family: T.font
                font.pixelSize: 16
                font.bold: true
                color: root.dk ? root.tD.text : root.tL.text
            }
        }

        // ----- Spacer -----
        Item { Layout.fillWidth: true }

        // ----- Track count badge -----
        Rectangle {
            height: 30
            radius: 15
            anchors.verticalCenter: parent.verticalCenter
            color: root.dk ? "#16233A" : "#EEF2F8"
            border.color: root.dk ? root.tD.bezel : root.tL.bezel
            border.width: 1
            width: badgeText.paintedWidth + 40

            Row {
                id: badge
                anchors.centerIn: parent
                spacing: 8
                Rectangle {
                    id: statusDot
                    width: 8
                    height: 8
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: audioPlayer.isPlaying ? (root.dk ? root.tD.ok : root.tL.ok)
                          : audioPlayer.isPaused ? (root.dk ? root.tD.warn : root.tL.warn)
                          : (root.dk ? root.tD.idle : root.tL.idle)
                    Behavior on color { ColorAnimation { duration: 180 } }
                }
                Text {
                    id: badgeText
                    anchors.verticalCenter: parent.verticalCenter
                    text: audioPlayer.playlist.length + " tracks"
                    font.family: T.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.dk ? root.tD.text : root.tL.text
                }
            }
        }
    }

    // ----- Error banner (overlay top, auto-dismiss 5s) -----
    ErrorBanner {
        id: errorBanner
        anchors.fill: parent          // full header area
        anchors.margins: 2
        z: 100                        // overlay above other header items
    }

    Connections {
        target: audioPlayer
        function onError(errorString) { errorBanner.show(errorString); }
    }
}
