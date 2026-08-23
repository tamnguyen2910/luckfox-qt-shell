import QtQuick 2.12

// Digital clock + date in a modern translucent card, top corner.
// VN time (UTC+7) is derived from the UTC epoch, independent of system/QML TZ.
Item {
    id: root

    property int utcOffsetMs: 7 * 3600 * 1000 // Vietnam (UTC+7)
    property bool use24h: true

    width: 210
    height: 78

    // Soft drop shadow (drawn, no Qt5GraphicalEffects on the target)
    Rectangle {
        anchors.fill: parent
        radius: 16
        color: "#000"
        opacity: 0.35
        transform: Translate { x: 0; y: 3 }
        z: -1
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 16
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1a2434" }
            GradientStop { position: 0.55; color: "#131b28" }
            GradientStop { position: 1.0; color: "#0b111b" }
        }
        opacity: 0.72
        border.color: Qt.rgba(1, 1, 1, 0.14)
        border.width: 1
    }

    Text {
        id: timeText
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        color: "white"
        font.pixelSize: 32
        font.weight: Font.Light
        font.letterSpacing: 1
        style: Text.Outline
        styleColor: "#59000000"
    }

    Row {
        anchors.top: timeText.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        Rectangle {
            id: liveDot
            anchors.verticalCenter: parent.verticalCenter
            width: 5
            height: 5
            radius: 2.5
            color: "#10b981"
            opacity: 0.9
        }

        Text {
            id: dateText
            anchors.verticalCenter: parent.verticalCenter
            color: "#b9c6d6"
            font.pixelSize: 13
            font.letterSpacing: 1.5
            style: Text.Outline
            styleColor: "#59000000"
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            timeText.text = root.formatTime()
            dateText.text = root.formatDate()
        }
    }

    function pad(n) { return n < 10 ? "0" + n : "" + n }

    // VN wall-clock derived from the UTC epoch; independent of system/QML TZ.
    function vnDate() { return new Date(new Date().getTime() + root.utcOffsetMs) }

    function formatTime() {
        var d = root.vnDate()
        var h = d.getUTCHours()
        var suffix = ""
        if (!root.use24h) {
            suffix = h < 12 ? " AM" : " PM"
            h = h % 12
            if (h === 0) h = 12
        }
        return pad(h) + ":" + pad(d.getUTCMinutes()) + ":" + pad(d.getUTCSeconds()) + suffix
    }

    function formatDate() {
        var weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        var d = root.vnDate()
        return weekdays[d.getUTCDay()] + "  " + pad(d.getUTCDate()) + "/" + pad(d.getUTCMonth() + 1) + "/" + d.getUTCFullYear()
    }
}