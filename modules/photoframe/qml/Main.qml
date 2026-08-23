import QtQuick 2.12
import QtQuick.Window 2.12
import "components"

Item {
    id: root
    anchors.fill: parent
    // visible: true  // handled by Loader
    width: 800
    height: 480

    // Background color (was `color` on Window root)
    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    property bool uiVisible: true
    property int dragThreshold: 80
    property real dragStartX: 0
    property bool isDragging: false
    property real dragOffset: 0

    function showUi() { uiVisible = true; overlayTimer.restart() }
    function hideUi() { uiVisible = false }
    function toggleUi() { if (uiVisible) hideUi(); else showUi() }

    FocusScope {
        anchors.fill: parent
        focus: true

        CrossFadeImage {
            id: stage
            anchors.fill: parent
            x: dragOffset
            effect: settings.transitionMode
            Behavior on x {
                enabled: !isDragging
                NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
            }
        }

        // Loading / empty states (no images yet)
        Rectangle {
            anchors.fill: parent
            color: "black"
            visible: browser.count === 0
            Column {
                anchors.centerIn: parent
                spacing: 12
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#8899aa"
                    font.pixelSize: 22
                    text: scanner.scanning ? qsTr("Scanning...") : qsTr("No images found")
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !scanner.scanning
                    color: "#556677"
                    font.pixelSize: 14
                    text: qsTr("Put images in %1").arg(scanner.directory)
                }
            }
        }

        // Input layer: BELOW the overlay UI so buttons stay clickable
        // (later siblings are on top), above the image stage.
        MouseArea {
            anchors.fill: parent
            onPressed: { dragStartX = mouse.x; isDragging = true }
            onPositionChanged: { if (isDragging) dragOffset = mouse.x - dragStartX }
            onReleased: {
                isDragging = false
                var delta = mouse.x - dragStartX
                if (delta > dragThreshold)
                    browser.previous()
                else if (delta < -dragThreshold)
                    browser.next()
                else
                    root.toggleUi()
            }
            onCanceled: isDragging = false
        }

        AnalogClock {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 16
            visible: settings.clockAnalog
            scale: 0.85
            opacity: 0
            NumberAnimation on scale { to: 1; duration: 700; easing.type: Easing.OutBack }
            NumberAnimation on opacity { to: 1; duration: 700 }
        }

        Item {
            id: clockHost
            anchors.top: parent.top
            anchors.topMargin: 12
            width: 210
            height: 78
            x: settings.clockPosition === 1 ? 16 : root.width - width - 16
            visible: settings.clockEnabled
            y: -60
            opacity: 0
            ParallelAnimation {
                running: true
                NumberAnimation { target: clockHost; property: "y"; from: -60; to: 0; duration: 700; easing.type: Easing.OutCubic }
                NumberAnimation { target: clockHost; property: "opacity"; from: 0.0; to: 1.0; duration: 700 }
            }

            ClockWidget {
                anchors.fill: parent
                use24h: settings.clock24h
            }
        }

        Keys.onLeftPressed: browser.previous()
        Keys.onRightPressed: browser.next()
        Keys.onSpacePressed: browser.toggleSlideshow()
        Keys.onReturnPressed: browser.toggleSlideshow()
        Keys.onUpPressed: root.showUi()
        Keys.onDownPressed: root.hideUi()
        Keys.onPressed: {
            if (event.key === Qt.Key.S && !event.isAutoRepeat)
                settingsPanel.open = !settingsPanel.open
        }

        InfoBar {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            y: root.uiVisible && browser.count > 0 ? 0 : 52
            opacity: root.uiVisible && browser.count > 0 ? 1 : 0
            visible: opacity > 0
            Behavior on y { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 220 } }
            onSettingsClicked: {
                root.showUi()
                settingsPanel.open = true
            }
        }

        // One-time hint
        Text {
            id: hint
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 64
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#99aabb"
            font.pixelSize: 13
            text: qsTr("Swipe to browse  ·  Tap for controls  ·  Space to play slideshow")
            opacity: 0.8
        }

        Connections {
            target: browser
            function onCurrentIndexChanged() { root.showUi() }
        }

        // Keep the running slideshow in sync with persisted settings.
        Connections {
            target: settings
            function onSlideshowIntervalMsChanged() { browser.setSlideshowInterval(settings.slideshowIntervalMs) }
            function onShuffleEnabledChanged() { browser.setShuffle(settings.shuffleEnabled) }
        }
    }

    SettingsPanel {
        id: settingsPanel
        anchors.fill: parent
        onCloseRequested: settingsPanel.open = false
    }

    Timer {
        id: overlayTimer
        interval: 4000
        onTriggered: root.hideUi()
    }

    Timer {
        id: hintTimer
        interval: 6000
        running: true
        onTriggered: hint.visible = false
    }
}