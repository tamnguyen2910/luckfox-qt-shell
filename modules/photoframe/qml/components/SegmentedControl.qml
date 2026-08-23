import QtQuick 2.12

// Shape-based segmented selector (no QtQuick.Controls on the target).
// model: array of labels; value: current index; signal changed(int index).
Item {
    id: root

    property var model: []
    property int value: 0
    signal changed(int index)

    implicitWidth: row.width
    implicitHeight: 30

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "#1b2434"
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
    }

    Row {
        id: row
        anchors.fill: parent
        Repeater {
            model: root.model
            delegate: Item {
                id: seg
                property bool active: index === root.value
                width: row.width / root.model.length
                height: row.height

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: (parent.height - 6) / 2
                    color: seg.active ? "#10b981" : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                Text {
                    anchors.centerIn: parent
                    color: seg.active ? "#06281d" : "#ccd6e0"
                    font.pixelSize: 12
                    font.weight: seg.active ? Font.DemiBold : Font.Normal
                    text: modelData
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.value !== index) {
                            root.value = index
                            root.changed(index)
                        }
                    }
                }
            }
        }
    }
}
