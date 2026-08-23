import QtQuick 2.15
import QtQuick.Controls 2.15
import "qrc:/shell/components/themes/Theme.js" as T

// Record button — circular, dark glass + teal ring, center ripple
Button {
    id: recordBtn
    readonly property bool dk: appTheme.isDark
    readonly property var pal: dk ? T.recorder.dark : T.recorder.light
    property string customText: "Record"
    property string customColor: pal.accent

    width: 150
    height: 150
    flat: true

    contentItem: Item {
        id: c
        anchors.fill: parent

        // Base disc + accent ring
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: recordBtn.pressed ? recordBtn.pal.accentDiscHot : recordBtn.pal.accentDisc
            border.width: 2
            border.color: recordBtn.customColor
            Behavior on color { ColorAnimation { duration: 130 } }
        }

        // Inner fill (pressed feedback)
        Rectangle {
            anchors.fill: parent
            anchors.margins: 12
            radius: width / 2
            color: recordBtn.pressed ? recordBtn.pal.accentDiscHot : "transparent"
            Behavior on color { ColorAnimation { duration: 130 } }
        }

        // Microphone icon
        Canvas {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -16
            width: 42
            height: 40
            opacity: recordBtn.pressed ? 0.85 : 1.0

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = recordBtn.customColor;
                ctx.lineWidth = 2.5;
                ctx.lineCap = "round";

                // Mic capsule
                ctx.beginPath();
                ctx.moveTo(21, 4);
                ctx.lineTo(21, 21);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(21, 21, 9, Math.PI, 0);
                ctx.stroke();
                // Stand
                ctx.beginPath();
                ctx.moveTo(12.5, 28);
                ctx.lineTo(29.5, 28);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(21, 28);
                ctx.lineTo(21, 34);
                ctx.stroke();
            }
        }

        // Label
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 106
            text: recordBtn.customText
            font.pixelSize: 15
            font.bold: true
            font.family: "DejaVu Sans"
            color: recordBtn.customColor
        }

        // Ripple (center, no pointer in car touch)
        Rectangle {
            id: ripple
            anchors.centerIn: parent
            width: 60
            height: 60
            radius: 30
            color: recordBtn.customColor
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