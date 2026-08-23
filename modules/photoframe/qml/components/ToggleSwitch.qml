import QtQuick 2.12

// Simple on/off switch, drawn with shapes.
Item {
    id: root

    width: 52
    height: 28

    property bool checked: false
    signal toggled(bool on)

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: root.checked ? "#10b981" : "#2a3547"
        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            width: 24
            height: 24
            radius: 12
            color: "white"
            x: root.checked ? parent.width - width - 2 : 2
            y: (parent.height - height) / 2
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }
}
