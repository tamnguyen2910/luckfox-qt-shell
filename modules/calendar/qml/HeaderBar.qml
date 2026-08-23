import QtQuick 2.12
import "Theme.js" as Theme

// HeaderBar v6 — reads colors from MainScreen properties directly.

Item {
    id: headerBar
    width: parent ? parent.width : Theme.Theme.layout.width
    height: Theme.Theme.layout.headerHeight

    property string monthTitle: ""
    property string lunarTitle: ""
    property int displayYear: 2026
    property bool isDark: false

    signal prevMonth()
    signal nextMonth()
    signal goToToday()
    signal toggleTheme()

    Rectangle {
        anchors.fill: parent
        color: mainScreen.surface
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: mainScreen.divider
    }

    Rectangle {
        id: prevBtn
        width: 44; height: 44
        radius: 22
        color: prevArea.containsPress ? mainScreen.accentSoft :
               prevArea.containsMouse ? mainScreen.surfaceHover : "transparent"
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.Theme.spacing.sm

        Text {
            text: "‹"
            font.pixelSize: Theme.Theme.font.arrow
            font.family: "DejaVu Sans"
            color: mainScreen.accent
            anchors.centerIn: parent
        }

        MouseArea {
            id: prevArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: headerBar.prevMonth()
        }
    }

    Rectangle {
        id: nextBtn
        width: 44; height: 44
        radius: 22
        color: nextArea.containsPress ? mainScreen.accentSoft :
               nextArea.containsMouse ? mainScreen.surfaceHover : "transparent"
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Theme.Theme.spacing.sm

        Text {
            text: "›"
            font.pixelSize: Theme.Theme.font.arrow
            font.family: "DejaVu Sans"
            color: mainScreen.accent
            anchors.centerIn: parent
        }

        MouseArea {
            id: nextArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: headerBar.nextMonth()
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 2

        Text {
            text: headerBar.monthTitle.toUpperCase()
            font.pixelSize: Theme.Theme.font.label
            font.family: "DejaVu Sans"
            font.weight: Font.Medium
            font.letterSpacing: 1.0
            color: mainScreen.textDim
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: headerBar.displayYear
            font.pixelSize: Theme.Theme.font.heroYear
            font.family: "DejaVu Sans"
            font.weight: Font.DemiBold
            color: mainScreen.text
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Rectangle {
        id: todayBtn
        width: todayLabel.implicitWidth + Theme.Theme.spacing.xl * 2
        height: 36
        radius: Theme.Theme.radius.round
        color: todayArea.containsPress ? mainScreen.accentDim :
               todayArea.containsMouse ? mainScreen.accentSoft : mainScreen.accent
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: nextBtn.left
        anchors.rightMargin: Theme.Theme.spacing.md

        Text {
            id: todayLabel
            text: "Hôm nay"
            font.pixelSize: Theme.Theme.font.button
            font.bold: true
            font.family: "DejaVu Sans"
            color: todayArea.containsMouse && !todayArea.containsPress ? mainScreen.accent : mainScreen.todayText
            anchors.centerIn: parent
        }

        MouseArea {
            id: todayArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: headerBar.goToToday()
        }
    }

    Rectangle {
        id: themeBtn
        width: 44; height: 44
        radius: 22
        color: themeArea.containsPress ? mainScreen.accentSoft :
               themeArea.containsMouse ? mainScreen.surfaceHover : "transparent"
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: prevBtn.right
        anchors.leftMargin: 4

        Text {
            text: headerBar.isDark ? "☀" : "☾"
            font.pixelSize: 20
            font.family: "DejaVu Sans"
            color: mainScreen.accent
            anchors.centerIn: parent
        }

        MouseArea {
            id: themeArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: headerBar.toggleTheme()
        }
    }
}
