import QtQuick 2.12

// Play / pause toggle button for the slideshow, drawn with shapes only
// (no icon font required on the embedded target).
Item {
    id: root

    width: 56
    height: 56

    property bool pressed: false

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 28
        color: Qt.rgba(0, 0, 0, 0.55)
        border.color: Qt.rgba(1, 1, 1, 0.25)
        border.width: 1
        scale: root.pressed ? 0.85 : 1.0
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
    }

    // Play triangle
    Canvas {
        anchors.centerIn: parent
        width: 20
        height: 24
        visible: !browser.playing
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = "white"
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(width, height / 2)
            ctx.lineTo(0, height)
            ctx.closePath()
            ctx.fill()
        }
    }

    // Pause bars
    Row {
        anchors.centerIn: parent
        spacing: 6
        visible: browser.playing
        Rectangle { width: 6; height: 22; color: "white" }
        Rectangle { width: 6; height: 22; color: "white" }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: root.pressed = true
        onReleased: root.pressed = false
        onCanceled: root.pressed = false
        onClicked: browser.toggleSlideshow()
    }
}
