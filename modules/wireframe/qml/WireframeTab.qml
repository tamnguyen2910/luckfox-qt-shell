import QtQuick 2.15
import Wireframe 1.0
import "qrc:/shell/components/themes/Theme.js" as T

// ==================================================================
// Wireframe tab — 3D wireframe scene (pyramid + cylinder + cube)
// Integrated from 05_wireframe app. Background card is provided by
// shell.qml; this tab draws the wireframes (C++ QQuickPaintedItem)
// plus title/status text. Animation clock: 16ms Timer (~60 fps).
// ==================================================================
Item {
    id: rootWf

    readonly property bool dk: appTheme.isDark
    readonly property var pal: dk ? T.wireframe.dark : T.wireframe.light

    // Animation clock — drives the C++ renderer (same semantics as 04_demo tick()).
    property real t: 0.0

    // 3D wireframe scene (painted by C++ via QQuickPaintedItem)
    WireframeCanvas {
        id: canvas
        anchors.fill: parent
        time: rootWf.t
    }

    // Title
    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 16
        anchors.topMargin: 10
        text: "Luckfox 3D Wireframe"
        font.family: T.font
        font.pixelSize: 18
        font.bold: true
        color: rootWf.pal.title
    }

    // Status line
    Text {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
        anchors.bottomMargin: 8
        text: "Pyramid + Cylinder + Cube | t=%1s".arg(rootWf.t.toFixed(1))
        font.family: T.font
        font.pixelSize: 11
        color: rootWf.pal.status
    }

    // Animation timer (~60 fps)
    Timer {
        interval: 16
        repeat: true
        running: true
        onTriggered: rootWf.t += 0.02
    }
}