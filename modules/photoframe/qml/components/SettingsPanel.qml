import QtQuick 2.12

// Full-screen settings overlay. Uses only shapes (no QtQuick.Controls)
// so it works on the minimal embedded Qt.
Item {
    id: root

    property bool open: false
    signal closeRequested()

    visible: open
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200 } }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.72)

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }

        Rectangle {
            id: panel
            anchors.centerIn: parent
            width: 640
            height: 432
            radius: 10
            color: "#111927"
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1
            scale: root.open ? 1 : 0.92
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent } // swallow clicks inside panel

            Text {
                id: title
                anchors.top: parent.top
                anchors.topMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#e4e8f0"
                font.pixelSize: 21
                font.weight: Font.DemiBold
                text: qsTr("Settings")
            }

            Column {
                anchors.top: title.bottom
                anchors.topMargin: 14
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 30
                anchors.rightMargin: 30
                spacing: 14

                // ---- Slideshow interval slider (full width) ----
                Item {
                    width: parent.width
                    height: 34
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        color: "#ccd6e0"
                        font.pixelSize: 15
                        text: qsTr("Slideshow interval")
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: slider.left
                        anchors.rightMargin: 10
                        color: "#10b981"
                        font.pixelSize: 15
                        width: 52
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(settings.slideshowIntervalMs / 1000) + " s"
                    }
                    Rectangle {
                        id: slider
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        width: 240
                        height: 6
                        radius: 3
                        color: "#2a3547"

                        property real dragPos: 0
                        readonly property real trackPos: sliderArea.pressed ? dragPos : root.sliderTrackPos

                        Rectangle {
                            width: slider.trackPos * parent.width
                            height: parent.height
                            radius: 3
                            color: "#10b981"
                        }
                        Rectangle {
                            x: slider.trackPos * (slider.width - width)
                            y: (slider.height - height) / 2
                            width: 22
                            height: 22
                            radius: 11
                            color: "#e4e8f0"
                        }
                        MouseArea {
                            id: sliderArea
                            anchors.fill: parent
                            onPressed: { slider.dragPos = Math.max(0, Math.min(1, mouse.x / slider.width)); root.applyInterval() }
                            onPositionChanged: {
                                if (pressed) {
                                    slider.dragPos = Math.max(0, Math.min(1, mouse.x / slider.width))
                                    root.applyInterval()
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 18

                    // ---- Left column ----
                    Column {
                        width: 280
                        spacing: 14

                        Item {
                            width: parent.width
                            height: 28
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                color: "#ccd6e0"
                                font.pixelSize: 15
                                text: qsTr("Shuffle images")
                            }
                            ToggleSwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                checked: settings.shuffleEnabled
                                onToggled: settings.shuffleEnabled = checked
                            }
                        }

                        Item {
                            width: parent.width
                            height: 28
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                color: "#ccd6e0"
                                font.pixelSize: 15
                                text: qsTr("Slideshow auto-start")
                            }
                            ToggleSwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                checked: settings.slideshowAutoStart
                                onToggled: settings.slideshowAutoStart = checked
                            }
                        }

                        Item {
                            width: parent.width
                            height: 28
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                color: "#ccd6e0"
                                font.pixelSize: 15
                                text: qsTr("Ken Burns effect")
                            }
                            ToggleSwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                checked: settings.kenBurnsEnabled
                                onToggled: settings.kenBurnsEnabled = checked
                            }
                        }

                        Item {
                            width: parent.width
                            height: 28
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                color: "#ccd6e0"
                                font.pixelSize: 15
                                text: qsTr("Photo info")
                            }
                            ToggleSwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                checked: settings.photoInfo
                                onToggled: settings.photoInfo = checked
                            }
                        }

                        Item {
                            width: parent.width
                            height: 20
                            Text {
                                anchors.left: parent.left
                                color: "#8899aa"
                                font.pixelSize: 13
                                elide: Text.ElideMiddle
                                width: parent.width
                                text: qsTr("Images: %1").arg(settings.imageDirectory)
                            }
                        }
                    }

                    // ---- Right column ----
                    Column {
                        width: 280
                        spacing: 14

                        Item {
                            width: parent.width
                            height: 28
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                color: "#ccd6e0"
                                font.pixelSize: 15
                                text: qsTr("Transition")
                            }
                            SegmentedControl {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                width: 200
                                model: ["Fade", "Slide", "Zoom", "Wipe", "Rand"]
                                value: settings.transitionMode
                                onChanged: settings.transitionMode = index
                            }
                        }

                        Item {
                            width: parent.width
                            height: 28
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                color: "#ccd6e0"
                                font.pixelSize: 15
                                text: qsTr("Image fit")
                            }
                            SegmentedControl {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                width: 200
                                model: ["Fit", "Fill", "Stretch"]
                                value: settings.fitMode
                                onChanged: settings.fitMode = index
                            }
                        }

                        Item {
                            width: parent.width
                            height: 28
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                color: "#ccd6e0"
                                font.pixelSize: 15
                                text: qsTr("Digital clock")
                            }
                            ToggleSwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                checked: settings.clockEnabled
                                onToggled: settings.clockEnabled = checked
                            }
                        }

                        Item {
                            width: parent.width
                            height: 28
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                color: "#ccd6e0"
                                font.pixelSize: 15
                                text: qsTr("Analog clock")
                            }
                            ToggleSwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                checked: settings.clockAnalog
                                onToggled: settings.clockAnalog = checked
                            }
                        }

                        Item {
                            width: parent.width
                            height: 28
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                color: "#ccd6e0"
                                font.pixelSize: 15
                                text: qsTr("24-hour format")
                            }
                            ToggleSwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                checked: settings.clock24h
                                onToggled: settings.clock24h = checked
                            }
                        }

                        Item {
                            width: parent.width
                            height: 28
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                color: "#ccd6e0"
                                font.pixelSize: 15
                                text: qsTr("Clock position")
                            }
                            // Settings: 0 = top-right (default), 1 = top-left.
                            // Segments ordered Left | Right → map index accordingly.
                            SegmentedControl {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                width: 200
                                model: ["Left", "Right"]
                                value: settings.clockPosition === 0 ? 1 : 0
                                onChanged: settings.clockPosition = index === 0 ? 1 : 0
                            }
                        }
                    }
                }
            }
        }
    }

    // Interval range: 3..60 seconds, normalized 0..1
    readonly property int minSeconds: 3
    readonly property int maxSeconds: 60
    readonly property real sliderTrackPos: {
        var secs = settings.slideshowIntervalMs / 1000
        return Math.max(0, Math.min(1, (secs - minSeconds) / (maxSeconds - minSeconds)))
    }

    function applyInterval() {
        var secs = Math.round(minSeconds + (maxSeconds - minSeconds) * slider.dragPos)
        settings.slideshowIntervalMs = secs * 1000
    }
}