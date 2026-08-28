import QtQuick 2.15
import QtQuick.Controls 2.15
import "qrc:/shell/components/themes/Theme.js" as T

// Playback button — circular, dark glass + teal ring, center ripple
Button {
    id: playBtn
    readonly property bool dk: appTheme.isDark
    readonly property var pal: dk ? T.recorder.dark : T.recorder.light
    property string customText: "Play"
    property string customColor: pal.accent

    width: 150
    height: 150
    flat: true
    background: Item {}

    contentItem: Item {
        id: c
        anchors.fill: parent

        // Base disc + accent ring
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: playBtn.pressed ? playBtn.pal.accentDiscHot : playBtn.pal.accentDisc
            border.width: 2
            border.color: playBtn.customColor
            Behavior on color { ColorAnimation { duration: 130 } }
        }

        // Inner fill (pressed feedback)
        Rectangle {
            anchors.fill: parent
            anchors.margins: 12
            radius: width / 2
            color: playBtn.pressed ? playBtn.pal.accentDiscHot : "transparent"
            Behavior on color { ColorAnimation { duration: 130 } }
        }

        // Play triangle (drawn once; label signals Stop state)
        Canvas {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -16
            width: 40
            height: 40
            opacity: playBtn.pressed ? 0.85 : 1.0

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = playBtn.customColor;

                // Triangle pointing right
                ctx.beginPath();
                ctx.moveTo(13, 5);
                ctx.lineTo(30, 20);
                ctx.lineTo(13, 35);
                ctx.closePath();
                ctx.fill();
            }
        }

        // Label
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 106
            text: playBtn.customText
            font.pixelSize: 15
            font.bold: true
            font.family: T.font
            color: playBtn.customColor
        }

        // Ripple
        Rectangle {
            id: ripple
            anchors.centerIn: parent
            width: 60
            height: 60
            radius: 30
            color: playBtn.customColor
            opacity: 0
            scale: 0.4
            visible: false

            ParallelAnimation {
                id: rippleAnim
                NumberAnimation { target: ripple; property: "scale"; from: 0.4; to: 3.2; duration: 500; easing.type: Easing.OutCubic }
                NumberAnimation { target: ripple; property: "opacity"; from: 0.30; to: 0; duration: 500; easing.type: Easing.OutCubic }
            }
        }
    }

    onPressedChanged: {
        if (pressed) {
            ripple.visible = true
            ripple.scale = 0.4
            ripple.opacity = 0.30
            rippleAnim.restart()
        }
    }
}