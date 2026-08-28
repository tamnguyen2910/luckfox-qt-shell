import QtQuick 2.12
import QtQuick.Controls 2.12
import "Theme.js" as T

// Volume control: icon — slider(with %) — button (no outer card container)
Item {
    id: root

    readonly property bool dk: appTheme.isDark
    readonly property var tD: T.dark
    readonly property var tL: T.light
    height: 48

    Row {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        // Volume down — circle 44×44
        Rectangle {
            width: 44
            height: 44
            radius: 22
            color: mouseDown.pressed ? (root.dk ? root.tD.accent : root.tL.accent) : (root.dk ? root.tD.surfaceHi : root.tL.surfaceHi)
            border.color: mouseDown.pressed ? (root.dk ? root.tD.accent2 : root.tL.accent2) : (root.dk ? root.tD.bezel : root.tL.bezel)
            border.width: mouseDown.pressed ? 2 : 1
            Image {
                source: "qrc:/music/icons/volume_down.svg"
                width: 18
                height: 18
                anchors.centerIn: parent
                opacity: mouseDown.pressed ? 0.9 : 1
                fillMode: Image.PreserveAspectFit
            }
            MouseArea {
                id: mouseDown
                anchors.fill: parent
                onClicked: audioPlayer.volumeDown()
            }
        }

        // Continuous slider 0-100%
        Slider {
            id: volSlider
            width: parent.width - 144
            from: 0
            to: 100
            value: audioPlayer.volume
            anchors.verticalCenter: parent.verticalCenter
            onValueChanged: {
                if (Math.abs(value - audioPlayer.volume) > 1)
                    audioPlayer.setVolume(Math.round(value))
            }
            background: Rectangle {
                x: volSlider.leftPadding
                y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 5
                width: volSlider.availableWidth
                height: implicitHeight
                radius: 2.5
                color: root.dk ? root.tD.track : root.tL.track
                Rectangle {
                    width: volSlider.visualPosition * parent.width
                    height: parent.height
                    radius: 2.5
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.dk ? root.tD.accent : root.tL.accent }
                        GradientStop { position: 1.0; color: root.dk ? root.tD.accent2 : root.tL.accent2 }
                    }
                }
            }
            handle: Rectangle {
                x: volSlider.leftPadding + volSlider.visualPosition * (volSlider.availableWidth - width)
                y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                implicitWidth: 24
                implicitHeight: 24
                radius: 12
                color: root.dk ? "#FFFFFF" : "#1A2332"
                border.width: 2
                border.color: root.dk ? root.tD.accent : root.tL.accent
                scale: volSlider.pressed ? 1.15 : 1.0
                Behavior on scale { NumberAnimation { duration: 90 } }
            }
        }

        // Volume percentage label — 44wide, centered
        Text {
            text: Math.round(audioPlayer.volume) + "%"
            font.family: T.FONT
            font.pixelSize: 12
            font.bold: true
            color: root.dk ? root.tD.text : root.tL.text
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            horizontalAlignment: Text.AlignHCenter
        }

        // Volume up — circle 44×44
        Rectangle {
            width: 44
            height: 44
            radius: 22
            color: mouseUp.pressed ? (root.dk ? root.tD.accent : root.tL.accent) : (root.dk ? root.tD.surfaceHi : root.tL.surfaceHi)
            border.color: mouseUp.pressed ? (root.dk ? root.tD.accent2 : root.tL.accent2) : (root.dk ? root.tD.bezel : root.tL.bezel)
            border.width: mouseUp.pressed ? 2 : 1
            Image {
                source: "qrc:/music/icons/volume_up.svg"
                width: 18
                height: 18
                anchors.centerIn: parent
                opacity: mouseUp.pressed ? 0.9 : 1
                fillMode: Image.PreserveAspectFit
            }
            MouseArea {
                id: mouseUp
                anchors.fill: parent
                onClicked: audioPlayer.volumeUp()
            }
        }
    }
}
