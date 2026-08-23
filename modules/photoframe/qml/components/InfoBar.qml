import QtQuick 2.12

// Bottom overlay: settings button, file info, play/pause, index/total,
// plus a thin slideshow progress bar along its top edge.
Rectangle {
    id: root

    property string currentFile: browser.currentFile
    property int index: browser.currentIndex + 1
    property int total: browser.count
    property bool photoInfo: settings.photoInfo

    signal settingsClicked()

    height: photoInfo ? 66 : 52
    color: Qt.rgba(0, 0, 0, 0.55)

    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // ---- Slideshow progress bar ----
    Rectangle {
        id: progressBar
        anchors.top: parent.top
        anchors.left: parent.left
        width: parent.width * root.progress
        height: 3
        color: "#10b981"
        visible: browser.playing
    }

    function baseName(path) {
        var parts = path.split("/")
        return parts[parts.length - 1]
    }

    // Settings (gear) button, drawn with shapes
    Item {
        id: gearButton
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 36

        property bool pressed: false

        Canvas {
            anchors.fill: parent
            scale: gearButton.pressed ? 0.78 : 1.0
            Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
            onPaint: {
                var ctx = getContext("2d")
                var c = width / 2
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = "#ccd6e0"
                var i
                for (i = 0; i < 8; i++) {
                    ctx.save()
                    ctx.translate(c, c)
                    ctx.rotate(i * Math.PI / 4)
                    ctx.fillRect(c - 3, -12, 6, 5)
                    ctx.restore()
                }
                ctx.beginPath()
                ctx.arc(c, c, 9, 0, Math.PI * 2)
                ctx.fill()
                ctx.fillStyle = "#111927"
                ctx.beginPath()
                ctx.arc(c, c, 3.5, 0, Math.PI * 2)
                ctx.fill()
            }
        }
        MouseArea {
            anchors.fill: parent
            onPressed: gearButton.pressed = true
            onReleased: gearButton.pressed = false
            onCanceled: gearButton.pressed = false
            onClicked: root.settingsClicked()
        }
    }

    Text {
        id: nameText
        anchors.left: gearButton.right
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.photoInfo ? -9 : 0
        color: "white"
        font.pixelSize: 15
        elide: Text.ElideMiddle
        width: parent.width * 0.40
        text: currentFile ? root.baseName(currentFile) : ""
    }

    // Second line: resolution + file size
    Text {
        id: infoText
        anchors.left: nameText.left
        anchors.top: nameText.bottom
        anchors.topMargin: 3
        color: "#9fb0c3"
        font.pixelSize: 12
        visible: root.photoInfo && currentFile
        text: (browser.imageWidth > 0 ? browser.imageWidth + " x " + browser.imageHeight + "  ·  " : "")
              + (browser.fileSize > 0 ? browser.fileSize + " KB" : "")
    }

    PlayPauseButton {
        anchors.centerIn: parent
    }

    Text {
        id: counterText
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        color: "#ccd6e0"
        font.pixelSize: 15
        text: root.index + " / " + root.total
    }

    // ---- Progress tracking ----
    property double progressStart: 0
    property real progress: 0

    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: root.tickProgress()
    }

    Connections {
        target: browser
        function onCurrentIndexChanged() { root.progressStart = new Date().getTime() }
        function onPlayingChanged() { root.progressStart = new Date().getTime() }
    }

    function tickProgress() {
        if (!browser.playing) {
            root.progress = 0
            return
        }
        var el = new Date().getTime() - root.progressStart
        root.progress = Math.max(0, Math.min(1, el / browser.interval))
    }
}