import QtQuick 2.12

Item {
    id: root
    anchors.fill: parent

    property int edgeWidth: 40
    property real swipeThreshold: 100

    signal swipeBackDetected

    MouseArea {
        id: edgeArea
        width: edgeWidth
        height: parent.height
        anchors.left: parent.left
        anchors.top: parent.top
        preventStealing: false
        propagateComposedEvents: true

        property real startX: 0
        property real startY: 0

        onPressed: {
            startX = mouseX
            startY = mouseY
        }

        onReleased: {
            var swipeDist = mouseX - startX
            if (swipeDist > swipeThreshold && Math.abs(mouseY - startY) < 100) {
                swipeBackDetected()
                Qt.quit()
            }
        }
    }

    Rectangle {
        width: 4
        height: 60
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 2
        radius: 2
        color: "#3b82f6"
        opacity: 0.3
    }
}
