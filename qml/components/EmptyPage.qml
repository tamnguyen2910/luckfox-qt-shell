import QtQuick 2.15
import "themes/Theme.js" as T

// Page trống dùng trong StackLayout - chỉ hiển thị gradient nền + tiêu đề.
Item {
    id: root

    readonly property bool dk: appTheme.isDark
    readonly property var tD: T.dark
    readonly property var tL: T.light

    property string title: ""

    Column {
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.title
            color: root.dk ? root.tD.textPrimary : root.tL.textPrimary
            font.pixelSize: 24
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Tab chưa được cài đặt"
            color: root.dk ? root.tD.textTertiary : root.tL.textTertiary
            font.pixelSize: 12
        }
    }
}
