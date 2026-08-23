import QtQuick 2.12
import "Theme.js" as Theme

// MonthGrid v6 — reads colors from MainScreen properties directly.

Item {
    id: monthGrid

    property var monthDays: []
    property string monthTitle: ""
    property string lunarTitle: ""
    property bool isDark: false

    signal dayClicked(int solarDay)
    signal nextMonth()
    signal prevMonth()

    property var dayNames: ["T2","T3","T4","T5","T6","T7","CN"]

    Grid {
        id: grid
        anchors.fill: parent
        anchors.margins: Theme.Theme.spacing.sm
        columns: 7

        property real cellW: width / 7
        property real cellH: height / 7

        Repeater {
            model: 7
            delegate: Item {
                width: grid.cellW
                height: grid.cellH

                Text {
                    text: dayNames[index]
                    font.pixelSize: Theme.Theme.font.weekday
                    font.family: "DejaVu Sans"
                    font.weight: Font.Medium
                    font.letterSpacing: 0.3
                    color: index === 6 ? mainScreen.holiday :
                           index === 5 ? mainScreen.accentDim :
                           mainScreen.textDim
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    anchors.centerIn: parent
                }
            }
        }

        Repeater {
            model: monthDays
            delegate: Rectangle {
                id: cell

                width: grid.cellW - 4
                height: grid.cellH - 4
                radius: Theme.Theme.radius.md

                property bool isEmpty:   !modelData || modelData.solarDay <= 0
                property bool isToday:   modelData && modelData.isToday
                property bool isHoliday: modelData && modelData.isHoliday
                property bool isNeighbor: modelData && (modelData.isNext || modelData.isPrev)

                opacity: cell.isNeighbor ? 0.4 : 1.0

                color: cell.isToday ? mainScreen.todayFill :
                       cell.isPressed ? mainScreen.accentSoft :
                       cell.isHovered ? mainScreen.surfaceHover :
                       "transparent"

                border.width: 1
                border.color: cell.isToday ? "transparent" : mainScreen.border

                Rectangle {
                    visible: cell.isToday
                    anchors.centerIn: parent
                    width: 42; height: 42
                    radius: 21
                    color: "transparent"
                    border.width: 1.5
                    border.color: mainScreen.todayFill
                    opacity: 0.3
                }

                Text {
                    text: (!cell.isEmpty && modelData.solarDay > 0) ? modelData.solarDay : ""
                    font.pixelSize: Theme.Theme.font.dayNumber
                    font.family: "DejaVu Sans"
                    font.bold: cell.isToday
                    color: cell.isToday ? mainScreen.todayText :
                           cell.isNeighbor ? mainScreen.textMuted :
                           mainScreen.text
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: Math.max(2, (grid.cellH - 50) / 2)
                }

                Text {
                    text: (!cell.isEmpty && modelData.lunarDay > 0) ? modelData.lunarDay : ""
                    font.pixelSize: Theme.Theme.font.lunar
                    font.family: "DejaVu Sans"
                    color: cell.isToday ? mainScreen.todayText :
                           cell.isHoliday ? mainScreen.holiday :
                           cell.isNeighbor ? mainScreen.textMuted :
                           mainScreen.textDim
                    opacity: cell.isToday ? 0.9 : 1.0
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: Math.max(2, (grid.cellH - 50) / 2) + 26
                }

                Row {
                    visible: cell.isHoliday && modelData && modelData.holidayName && modelData.holidayName.length > 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: Math.max(2, (grid.cellH - 50) / 2) + 40
                    spacing: 3

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 4; height: 4; radius: 2
                        color: mainScreen.holiday
                    }
                    Text {
                        text: modelData.holidayName
                        font.pixelSize: Theme.Theme.font.tiny
                        font.family: "DejaVu Sans"
                        color: mainScreen.holiday
                        width: grid.cellW - 20
                        elide: Text.ElideRight
                    }
                }

                property bool isHovered: false
                property bool isPressed: false

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: cell.isHovered = true
                    onExited: { cell.isHovered = false; cell.isPressed = false }
                    onPressed: cell.isPressed = true
                    onReleased: cell.isPressed = false
                    onClicked: {
                        if (!cell.isEmpty) monthGrid.dayClicked(modelData.solarDay)
                    }
                }

                scale: cell.isPressed ? 0.96 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: Theme.Theme.transition.fast; easing.type: Easing.OutQuad }
                }
            }
        }
    }
}
