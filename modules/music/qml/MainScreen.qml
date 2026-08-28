import QtQuick 2.12
import QtQuick.Controls 2.12
import "Theme.js" as T
import "Utils.js" as Utils

// Main composition: left playlist + right now-playing panel + status bar
Item {
    id: root
    width: 800
    height: 480

    // ---- Live theme selection ----
    readonly property bool dk: appTheme.isDark
    readonly property var tD: T.dark
    readonly property var tL: T.light

    // ---- Deep background gradient with soft radial glow ----
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.dk ? root.tD.bgTop : root.tL.bgTop }
            GradientStop { position: 1.0; color: root.dk ? root.tD.bgBottom : root.tL.bgBottom }
        }
    }

    // Subtle radial accent glow behind the player
    Rectangle {
        width: 360
        height: 360
        radius: 180
        anchors { right: parent.right; top: parent.top }
        anchors.margins: 40
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.dk ? root.tD.glowStrong : root.tL.glowStrong }
            GradientStop { position: 1.0; color: root.dk ? root.tD.glowWeak : root.tL.glowWeak }
        }
    }
    Rectangle {
        width: 300
        height: 300
        radius: 150
        anchors { left: parent.left; bottom: parent.bottom }
        anchors.margins: -60
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.dk ? root.tD.glowWeak : root.tL.glowWeak }
            GradientStop { position: 1.0; color: root.dk ? root.tD.glowWeak : root.tL.glowWeak }
        }
    }

    // ---- Vertical layout: header / body / status ----
    Column {
        anchors.fill: parent
        spacing: 0

        HeaderBar {
            width: parent.width
            height: 48
        }

        Item {
            width: parent.width
            height: 404
            Row {
                anchors.fill: parent
                spacing: 0

                // ---- Left: playlist (rounded right edge → blends with player zone) ----
                Rectangle {
                    width: 296
                    height: parent.height
                    radius: 14                                       // rounded playlist zone
                    clip: true
                    color: root.dk ? root.tD.panelBg : root.tL.panelBg
                    border.color: root.dk ? root.tD.panelBorder : root.tL.panelBorder
                    border.width: 1
                    PlaylistPanel {
                        anchors.fill: parent
                        onTrackSelected: audioPlayer.playAtIndex(index)
                    }
                }

                // ---- Right: now playing panel (rounded card) ----
                Item {
                    width: parent.width - 296
                    height: parent.height

                    Rectangle {
                        anchors.fill: parent
                        radius: 14                                   // rounded player zone
                        color: root.dk ? root.tD.surface : root.tL.surface
                        border.color: root.dk ? root.tD.panelBorder : root.tL.panelBorder
                        border.width: 1
                        clip: true

                        Column {
                            anchors { fill: parent; topMargin: 10 }
                            spacing: 9

                            // Album art
                            AlbumArt {
                                width: 150
                                height: 150
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            // Track title
                            Text {
                                text: audioPlayer.currentTitle
                                font.family: T.font
                                font.pixelSize: 17
                                font.bold: true
                                color: root.dk ? root.tD.text : root.tL.text
                                width: parent.width - 36
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideMiddle
                            }

                            // Spacer — push progress+volume down slightly
                            Item { width: 1; height: 14 }

                            // Progress + transport
                            PlayerControls {
                                width: parent.width - 34
                                height: 96
                                anchors.horizontalCenter: parent.horizontalCenter
                                onSeekRequested: audioPlayer.seek(position)
                            }

                            // Volume
                            VolumeBar {
                                width: parent.width - 66
                                height: 48
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }
        }

        StatusBar {
            width: parent.width
            height: 28
        }
    }

    Connections {
        target: audioPlayer
        function onError(errorString) {
            console.log("Audio error:", errorString)
        }
    }

    Component.onCompleted: {
        console.log("Music Player UI initialized (Pro Now Playing)")
        console.log("Tracks in playlist:", audioPlayer.playlist.length)
    }
}
