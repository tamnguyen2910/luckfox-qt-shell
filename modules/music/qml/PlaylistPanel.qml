import QtQuick 2.12
import QtQuick.Controls 2.12
import "Theme.js" as T
import "Utils.js" as Utils

// Left playlist panel — modern list with active-track card, equalizer animation, folder path
Item {
    id: root

    readonly property bool dk: appTheme.isDark
    readonly property var tD: T.dark
    readonly property var tL: T.light

    property int currentIndex: audioPlayer.currentIndex
    property var playlist: audioPlayer.playlist
    signal trackSelected(int index)

    Column {
        anchors.fill: parent
        spacing: 0

        // ----- Panel header (count only, no label) -----
        Rectangle {
            width: parent.width
            height: 36
            color: "transparent"

            Text {
                anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                text: audioPlayer.playlist.length
                font.family: T.FONT
                font.pixelSize: 10
                font.bold: true
                color: root.dk ? root.tD.accent : root.tL.accent
            }
        }

        // Folder path label (icon + path) — Item trong Column (auto-position)
        Item {
            width: parent.width
            height: 24

            Row {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 16 }
                spacing: 6
                Image {
                    source: "qrc:/music/icons/folder_open.png"
                    width: 14
                    height: 14
                    sourceSize: Qt.size(14, 14)
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.85
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: audioPlayer.musicFolderPath
                    font.family: T.FONT
                    font.pixelSize: 10
                    font.bold: true
                    color: root.dk ? root.tD.textFaint : root.tL.textFaint
                    elide: Text.ElideRight
                    width: 400   // static, safe elide
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // ----- Track list -----
        ListView {
            id: listView
            width: parent.width
            height: parent.height - 40
            clip: true
            model: root.playlist
            delegate: trackDelegate
            spacing: 4
            cacheBuffer: 200

            ScrollBar.vertical: ScrollBar {
                width: 4
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { radius: 2; color: root.dk ? root.tD.bezel : root.tL.bezel }
                background: Item {}
            }

            // ----- Empty state -----
            Rectangle {
                anchors.centerIn: parent
                visible: root.playlist.length === 0
                color: "transparent"
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    Image {
                        source: "qrc:/music/icons/music_note.svg"
                        width: 34
                        height: 34
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0.35
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        text: "No tracks"
                        font.family: T.FONT
                        font.pixelSize: 12
                        color: root.dk ? root.tD.textFaint : root.tL.textFaint
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "Scan music folder to begin"
                        font.family: T.FONT
                        font.pixelSize: 9
                        color: root.dk ? root.tD.textFaint : root.tL.textFaint
                        opacity: 0.8
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    Component {
        id: trackDelegate
        Item {
            width: listView.width
            height: 50  // touch-friendly row height (was 46, >=48px touch target)

            // ----- Card background -----
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                radius: 10
                color: index === root.currentIndex ? (root.dk ? root.tD.activeRow : root.tL.activeRow)
                     : mouseArea.pressed ? (root.dk ? root.tD.rowPress : root.tL.rowPress) : "transparent"
                border.width: index === root.currentIndex ? 1 : 0
                border.color: root.dk ? root.tD.rowBorder : root.tL.rowBorder
                Behavior on color { ColorAnimation { duration: 140 } }
            }

            // Left accent bar on active track
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                anchors.leftMargin: 10
                width: 3
                radius: 1.5
                visible: index === root.currentIndex
                color: root.dk ? root.tD.accent : root.tL.accent
            }

            Row {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                anchors.leftMargin: 22
                anchors.rightMargin: 14
                spacing: 10

                // ----- Number / playing indicator -----
                Item {
                    width: 18
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: (index + 1)
                        font.family: T.FONT
                        font.pixelSize: 10
                        font.bold: true
                        visible: !(index === root.currentIndex && audioPlayer.isPlaying)
                        color: index === root.currentIndex ? (root.dk ? root.tD.accent : root.tL.accent) : (root.dk ? root.tD.textFaint : root.tL.textFaint)
                    }
                    // Equalizer bars for the playing track
                    Item {
                        width: 18
                        height: 18
                        anchors.centerIn: parent
                        visible: index === root.currentIndex && audioPlayer.isPlaying
                        Row {
                            anchors.centerIn: parent
                            spacing: 2
                            Repeater {
                                model: 3
                                Rectangle {
                                    width: 3
                                    height: 16
                                    color: "transparent"
                                    Rectangle {
                                        width: parent.width
                                        radius: 1.5
                                        color: root.dk ? root.tD.accent : root.tL.accent
                                        anchors.bottom: parent.bottom
                                        height: 4
                                        SequentialAnimation on height {
                                            running: audioPlayer.isPlaying
                                            loops: Animation.Infinite
                                            NumberAnimation { to: 16; duration: 240 + index * 90; easing.type: Easing.InOutQuad }
                                            NumberAnimation { to: 4; duration: 240 + index * 90; easing.type: Easing.InOutQuad }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ----- Title + status -----
                Column {
                    width: parent.width - 40
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        width: parent.width
                        text: Utils.trackTitle(modelData)
                        font.family: T.FONT
                        font.pixelSize: 13
                        font.bold: index === root.currentIndex
                        color: index === root.currentIndex ? (root.dk ? root.tD.text : root.tL.text) : (root.dk ? root.tD.textDim : root.tL.textDim)
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        visible: index === root.currentIndex
                        text: audioPlayer.isPlaying ? "Playing now"
                             : audioPlayer.isPaused ? "Paused" : ""
                        font.family: T.FONT
                        font.pixelSize: 9
                        color: audioPlayer.isPlaying ? (root.dk ? root.tD.accentSoft : root.tL.accentSoft) : (root.dk ? root.tD.warn : root.tL.warn)
                    }
                }

                // ----- Playing indicator dot (right) -----
                Rectangle {
                    width: 7
                    height: 7
                    radius: 3.5
                    anchors.verticalCenter: parent.verticalCenter
                    visible: index === root.currentIndex
                    color: root.dk ? root.tD.accent : root.tL.accent
                    opacity: 0.85
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                onClicked: root.trackSelected(index)
            }
        }
    }
}
