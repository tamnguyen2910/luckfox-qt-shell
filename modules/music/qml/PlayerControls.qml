import QtQuick 2.12
import QtQuick.Controls 2.12
import "Theme.js" as T
import "Utils.js" as Utils

// Seekable progress bar + prev/play/next transport controls
Item {
    id: root

    readonly property bool dk: appTheme.isDark
    readonly property var tD: T.dark
    readonly property var tL: T.light

    signal seekRequested(int position)

    function playPause() {
        if (audioPlayer.isPlaying) {
            audioPlayer.pause()
        } else if (audioPlayer.isPaused) {
            audioPlayer.resume()
        } else {
            audioPlayer.play()
        }
    }

    Column {
        anchors.fill: parent
        spacing: 6

        // ----- Progress: time — slider — time -----
        Item {
            width: parent.width
            height: 26
            Row {
                anchors.fill: parent
                spacing: 8
                Text {
                    text: Utils.formatTime(audioPlayer.position)
                    font.family: T.FONT
                    font.pixelSize: 11
                    font.bold: true
                    color: root.dk ? root.tD.accentSoft : root.tL.accentSoft
                    width: 42
                    anchors.verticalCenter: parent.verticalCenter
                }
                Slider {
                    id: progressSlider
                    width: parent.width - 100
                    from: 0
                    to: audioPlayer.duration > 0 ? audioPlayer.duration : 100
                    value: audioPlayer.position
                    anchors.verticalCenter: parent.verticalCenter
                    onPressedChanged: {
                        if (!pressed) root.seekRequested(value)
                    }
                    background: Rectangle {
                        x: progressSlider.leftPadding
                        y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 5
                        width: progressSlider.availableWidth
                        height: implicitHeight
                        radius: 2.5
                        color: root.dk ? root.tD.track : root.tL.track
                        Rectangle {
                            width: progressSlider.visualPosition * parent.width
                            height: parent.height
                            radius: 2.5
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: root.dk ? root.tD.accent : root.tL.accent }
                                GradientStop { position: 1.0; color: root.dk ? root.tD.accent2 : root.tL.accent2 }
                            }
                        }
                    }
                    handle: Rectangle {
                        x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                        y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                        implicitWidth: 22
                        implicitHeight: 22
                        radius: 11
                        color: root.dk ? "#FFFFFF" : "#1A2332"
                        border.width: 3
                        border.color: root.dk ? root.tD.accent : root.tL.accent
                        opacity: progressSlider.pressed ? 1 : 0.92
                    }
                }
                Text {
                    text: Utils.formatTime(audioPlayer.duration)
                    font.family: T.FONT
                    font.pixelSize: 11
                    font.bold: true
                    color: root.dk ? root.tD.textDim : root.tL.textDim
                    width: 42
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // ----- Transport controls -----
        Item {
            width: parent.width
            height: 58
            Row {
                anchors.centerIn: parent
                spacing: 26

                // Previous
                Rectangle {
                    width: 52
                    height: 52
                    radius: 26
                    color: mousePrev.pressed ? (root.dk ? root.tD.surfaceHi : root.tL.surfaceHi) : (root.dk ? root.tD.surface : root.tL.surface)
                    border.color: root.dk ? root.tD.bezel : root.tL.bezel
                    border.width: 1
                    Image {
                        source: "qrc:/music/icons/previous.svg"
                        width: 20
                        height: 20
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                    }
                    MouseArea {
                        id: mousePrev
                        anchors.fill: parent
                        onClicked: audioPlayer.previous()
                    }
                }

                // Play / Pause (primary)
                Rectangle {
                    width: 62
                    height: 62
                    radius: 31
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.dk ? root.tD.accent : root.tL.accent }
                        GradientStop { position: 1.0; color: root.dk ? root.tD.accent2 : root.tL.accent2 }
                    }
                    border.width: 0
                    scale: mousePlay.pressed ? 0.9 : 1.0
                    Behavior on scale { NumberAnimation { duration: 90 } }
                    Image {
                        source: audioPlayer.isPlaying ? "qrc:/music/icons/pause.svg" : "qrc:/music/icons/play.svg"
                        width: 26
                        height: 26
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                    }
                    MouseArea {
                        id: mousePlay
                        anchors.fill: parent
                        onClicked: root.playPause()
                    }
                }

                // Next
                Rectangle {
                    width: 52
                    height: 52
                    radius: 26
                    color: mouseNext.pressed ? (root.dk ? root.tD.surfaceHi : root.tL.surfaceHi) : (root.dk ? root.tD.surface : root.tL.surface)
                    border.color: root.dk ? root.tD.bezel : root.tL.bezel
                    border.width: 1
                    Image {
                        source: "qrc:/music/icons/next.svg"
                        width: 20
                        height: 20
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                    }
                    MouseArea {
                        id: mouseNext
                        anchors.fill: parent
                        onClicked: audioPlayer.next()
                    }
                }
            }
        }
    }
}
