import QtQuick 2.15
import "qrc:/shell/components/themes/Theme.js" as T

Column {
    id: stat

    // ─── API ───────────────────────────────
    readonly property bool dk: appTheme.isDark
    readonly property var tD: T.dark
    readonly property var tL: T.light

    property string label: ""
    property string value: ""
    property color valueColor: dk ? tD.textPrimary : tL.textPrimary
    property color labelColor: dk ? tD.textSecondary : tL.textSecondary
    property int valueSize: 15

    spacing: 2

    Text {
        text: stat.label
        font.pixelSize: T.sizes.tertiary
        font.family: T.fontMono
        font.bold: true
        color: stat.labelColor
    }
    Text {
        text: stat.value
        font.pixelSize: stat.valueSize
        font.family: T.fontMono
        font.bold: true
        color: stat.valueColor
    }
}