import QtQuick 2.15
import QtQuick.Controls 2.15
import "themes/Theme.js" as T

// ==================================================================
// ShellTabBar — vertical auto tab bar for 800x480 automotive shell.
//
// Design (per spec):
//   * 72px wide, full height; dark translucent glass bg rgba(14,14,22,0.94).
//   * Top: logo 22x22 + faint divider.
//   * Center: 6 tabs (touch target 56px each), icon wrapper 36x36 r10,
//     stroke icon 20x20 (1.5px), label 9px shown only when active.
//   * Bottom: Settings + Power 32x32 buttons + divider.
//   * Active: teal wrapper rgba(0,229,195,0.08) + breathing glow,
//     icon scale 1.05, left accent bar 3x22 pulsing, label visible.
//   * Right edge: 1px line + teal gradient spot (12% height) gliding
//     to the active tab (500ms).
//   * Ripple feedback on touch (scale 0->3 / opacity 1->0, 500ms).
//   * Keyboard: Up/Down + Enter/Space.
//
// NOTE: QtGraphicalEffects is NOT shipped on the Luckfox firmware, so
// DropShadow/glow are faked with layered translucent rectangles
// (breathing opacity). clip is false everywhere so nothing is cut.
// ==================================================================

Item {
    id: bar

    width: 72
    implicitHeight: 480
    implicitWidth: 72

    // ---- Public API ----
    property int currentIndex: 0
    property var appNames: ["Dashboard", "Music", "Calendar", "WiFi", "Recorder", "Wireframe"]
    signal tabChanged(int index, string appName)
    signal settingsRequested()
    signal powerRequested()

    readonly property int itemCount: appNames.length
    readonly property int itemHeight: 56

    // ---- Palette (live light/dark via appTheme) ----
    readonly property bool dk: appTheme.isDark
    readonly property var tD: T.dark
    readonly property var tL: T.light

    property color accent: dk ? tD.accent : tL.accent
    readonly property color barBg: dk ? Qt.rgba(14/255, 14/255, 22/255, 0.94)
                                      : Qt.rgba(252/255, 253/255, 255/255, 0.94)
    readonly property color borderColor: dk ? Qt.rgba(1, 1, 1, 0.04)
                                            : Qt.rgba(26/255, 35/255, 50/255, 0.08)
    readonly property color iconColor: dk ? tD.textTertiary : tL.textTertiary
    readonly property color hoverBg: dk ? Qt.rgba(1, 1, 1, 0.03)
                                        : Qt.rgba(26/255, 35/255, 50/255, 0.05)
    readonly property color activeWrap: dk ? tD.accentSoft : tL.accentSoft
    readonly property color rippleColor: dk ? Qt.rgba(0, 229/255, 195/255, 0.25)
                                            : Qt.rgba(0, 184/255, 160/255, 0.28)
    readonly property color faintLine: dk ? Qt.rgba(1, 1, 1, 0.06)
                                          : Qt.rgba(26/255, 35/255, 50/255, 0.07)
    readonly property color footerHoverBg: dk ? Qt.rgba(1, 1, 1, 0.06)
                                              : Qt.rgba(26/255, 35/255, 50/255, 0.06)

    // ---- Background ----
    Rectangle {
        anchors.fill: parent
        color: bar.barBg

        // subtle glass sheen (no GPU blur available on target)
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: Qt.rgba(1, 1, 1, 0.05)
        }
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: Qt.rgba(0, 0, 0, 0.25)
        }
    }

    // ---- Right edge border ----
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: bar.borderColor
    }

    // ---- Logo (top) ----
    Image {
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: 22
        height: 22
        source: bar.svg("logo", bar.iconColor)
    }
    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 40
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 1
        color: bar.faintLine
    }

    // ---- Tab list (center) ----
    Column {
        id: listCol
        anchors.top: parent.top
        anchors.topMargin: 50
        width: parent.width
        spacing: 0

        Repeater {
            model: bar.appNames
            delegate: Loader {
                width: bar.width
                height: bar.itemHeight
                sourceComponent: tabItemComp
                onLoaded: {
                    item.idx = index
                    item.labelText = modelData
                }
            }
        }
    }

    // ---- Footer divider ----
    Rectangle {
        anchors.bottom: footer.top
        anchors.bottomMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 1
        color: bar.faintLine
    }

    // ---- Footer (Settings / Power) ----
    Row {
        id: footer
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        // Power
        Item {
            width: 32
            height: 32
            Rectangle {
                anchors.fill: parent
                radius: 9
                color: powMouse.containsMouse ? bar.footerHoverBg : "transparent"
            }
            Image {
                anchors.centerIn: parent
                width: 18
                height: 18
                source: bar.svg("power", "#e05555")
            }
            MouseArea {
                id: powMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: bar.powerRequested()
            }
        }
    }

    // ==============================================================
    //  RIGHT EDGE LIGHT — teal spot gliding to the active tab
    // ==============================================================
    Item {
        id: edgeOverlay
        anchors.right: parent.right
        anchors.top: listCol.top
        width: 2
        height: listCol.height
        clip: false
        z: 5

        Rectangle {
            id: edgeBlob
            width: 2
            height: Math.max(24, bar.height * 0.12)
            radius: 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: bar.accent }
                GradientStop { position: 1.0; color: "transparent" }
            }
            y: bar.currentIndex * bar.itemHeight + bar.itemHeight / 2 - edgeBlob.height / 2
            Behavior on y {
                NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
            }
        }
    }

    // ==============================================================
    //  TAB ITEM — states: default / hover / active
    // ==============================================================
    Component {
        id: tabItemComp
        Item {
            id: item
            width: bar.width
            height: bar.itemHeight

            property int idx: -1
            property string labelText: ""
            property bool itemActive: idx === bar.currentIndex
            property bool hovered: mouse.containsMouse

            // ---- state-driven properties ----
            property real iconOpacity: 0.35
            property real iconScale: 1.0
            property real labelOpacity: 0.0
            property color itemBgColor: "transparent"
            property color wrapColor: "transparent"
            property string iconColorStr: bar.dk ? "#5a5a6e" : "#8a93a6"

            states: [
                State {
                    name: "active"; when: item.itemActive
                    PropertyChanges { target: item; itemBgColor: "transparent"; iconOpacity: 1.0; iconScale: 1.05; labelOpacity: 1.0 }
                    PropertyChanges { target: item; wrapColor: bar.activeWrap; iconColorStr: bar.accent }
                },
                State {
                    name: "hover"; when: item.hovered && !item.itemActive
                    PropertyChanges { target: item; itemBgColor: bar.hoverBg; iconOpacity: 0.6 }
                }
            ]

            transitions: [
                Transition {
                    ColorAnimation { duration: 200 }
                    NumberAnimation { duration: 160; properties: "iconOpacity,labelOpacity" }
                    NumberAnimation { duration: 220; easing.type: Easing.OutBack; properties: "iconScale" }
                }
            ]

            // ---- item background ----
            Rectangle {
                anchors.fill: parent
                color: item.itemBgColor
            }

            // ---- left accent bar (active only, pulsing) ----
            Rectangle {
                id: accentBar
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: 22
                radius: 2
                color: bar.accent
                visible: item.itemActive

                // glow halo
                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: -2
                    radius: 4
                    color: bar.accent
                    opacity: 0.30
                }
            }
            SequentialAnimation {
                id: accentPulse
                running: item.itemActive && bar.visible
                loops: Animation.Infinite
                NumberAnimation { target: accentBar; property: "height"; to: 16; duration: 1250; easing.type: Easing.InOutSine }
                NumberAnimation { target: accentBar; property: "height"; to: 22; duration: 1250; easing.type: Easing.InOutSine }
            }

            // ---- icon wrapper + breathing glow ----
            Rectangle {
                id: glow
                anchors.centerIn: wrap
                width: 46
                height: 46
                radius: 14
                color: bar.accent
                opacity: 0
                visible: item.itemActive
            }
            SequentialAnimation {
                id: glowPulse
                running: item.itemActive && bar.visible
                loops: Animation.Infinite
                NumberAnimation { target: glow; property: "opacity"; to: 0.22; duration: 1500; easing.type: Easing.InOutSine }
                NumberAnimation { target: glow; property: "opacity"; to: 0.44; duration: 1500; easing.type: Easing.InOutSine }
            }

            Rectangle {
                id: wrap
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 4
                width: 36
                height: 36
                radius: 10
                color: item.wrapColor
                Behavior on color { ColorAnimation { duration: 200 } }

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: bar.svg(bar.appNames[item.idx], item.iconColorStr)
                    opacity: item.iconOpacity
                    scale: item.iconScale
                    antialiasing: true
                }
            }

            // ---- label (active only) ----
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: wrap.bottom
                anchors.topMargin: -1
                text: item.labelText
                font.pixelSize: T.sizes.tabLabel
                font.family: T.font
                font.weight: Font.Medium
                color: bar.accent
                opacity: item.labelOpacity
                horizontalAlignment: Text.AlignHCenter
                width: 64
                elide: Text.ElideRight
            }

            // ---- ripple (touch feedback) ----
            Rectangle {
                id: ripple
                anchors.fill: parent
                color: "transparent"
                clip: false
                Rectangle {
                    id: rippleDot
                    anchors.centerIn: parent
                    width: 36
                    height: 36
                    radius: 18
                    color: bar.rippleColor
                    visible: false
                    scale: 0
                    opacity: 1
                }
                ParallelAnimation {
                    id: rippleAnim
                    NumberAnimation { target: rippleDot; property: "scale"; from: 0; to: 3; duration: 500; easing.type: Easing.OutCubic }
                    NumberAnimation { target: rippleDot; property: "opacity"; from: 1; to: 0; duration: 500; easing.type: Easing.OutCubic }
                }
            }

            // ---- interaction ----
            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    bar.currentIndex = item.idx
                    bar.tabChanged(item.idx, bar.appNames[item.idx])
                }
                onPressed: {
                    rippleDot.visible = true
                    rippleDot.scale = 0
                    rippleDot.opacity = 1
                    rippleAnim.restart()
                    if (!rippleAnim.running)
                        rippleDot.visible = false
                }
            }
        }
    }

    // ---- Keyboard support (steering-wheel buttons / rotary) ----
    Keys.onUpPressed: {
        currentIndex = (currentIndex - 1 + itemCount) % itemCount
        tabChanged(currentIndex, appNames[currentIndex])
    }
    Keys.onDownPressed: {
        currentIndex = (currentIndex + 1) % itemCount
        tabChanged(currentIndex, appNames[currentIndex])
    }
    Keys.onReturnPressed: tabChanged(currentIndex, appNames[currentIndex])
    Keys.onSpacePressed: tabChanged(currentIndex, appNames[currentIndex])

    // ==============================================================
    //  SVG ICON FACTORY (stroke 1.5px, 24x24 viewBox)
    // ==============================================================
    function svg(type, color) {
        var paths = ""
        if (type === "logo") {
            paths = '<rect x="3" y="3" width="18" height="18" rx="5"/>' +
                    '<path d="M13.2 5.6 L8.4 13 h3.4 l-0.9 5.4 L15.6 11 h-3.4 l1-5.4z"/>'
        } else if (type === "Dashboard") {
            paths = '<circle cx="12" cy="13" r="8"/>' +
                    '<path d="M12 4.5 v2.5"/>' +
                    '<path d="M6.3 7.9 l1.8 1.8"/>' +
                    '<path d="M17.7 7.9 l-1.8 1.8"/>' +
                    '<path d="M12 13 L15.4 8.7"/>' +
                    '<circle cx="12" cy="13" r="1.4"/>'
        } else if (type === "Music") {
            paths = '<circle cx="9" cy="18.5" r="2.3"/>' +
                    '<circle cx="15" cy="18.5" r="2.3"/>' +
                    '<path d="M10.5 16.5 V6.7"/>' +
                    '<path d="M16.5 16.5 V6.7"/>' +
                    '<path d="M9.8 7.2 l8 -1.6"/>'
        } else if (type === "Calendar") {
            paths = '<rect x="4" y="6.5" width="16" height="13.5" rx="2"/>' +
                    '<path d="M4 10.5 h16"/>' +
                    '<path d="M8.5 4 v3.5"/>' +
                    '<path d="M15.5 4 v3.5"/>' +
                    '<path d="M8 15 h8"/>' +
                    '<path d="M8 17.8 h5"/>'
        } else if (type === "WiFi") {
            paths = '<path d="M3.5 10.5 C8.1 5.9 15.9 5.9 20.5 10.5"/>' +
                    '<path d="M6 13.6 C9.4 10.7 14.6 10.7 18 13.6"/>' +
                    '<path d="M8.6 16.6 C10.6 14.9 13.4 14.9 15.4 16.6"/>' +
                    '<circle cx="12" cy="19.4" r="1.4"/>'
        } else if (type === "Recorder") {
            paths = '<rect x="2.5" y="7" width="13.5" height="11" rx="2.5"/>' +
                    '<path d="M16 11.2 L21 9 v7 l-5 -2.2"/>' +
                    '<circle cx="9.2" cy="12.5" r="2.5"/>'
        } else if (type === "Wireframe") {
            paths = '<path d="M12 3.5 L20.5 8.5 V15.5 L12 20.5 L3.5 15.5 V8.5 Z"/>' +
                    '<path d="M3.5 8.5 L12 13.5 L20.5 8.5"/>' +
                    '<path d="M12 13.5 V20.5"/>'
        } else if (type === "Settings") {
            paths = '<path d="M16.4 12 L18.6 12 M15.11 15.11 L16.67 16.67 M12 16.4 L12 18.6 M8.89 15.11 L7.33 16.67 M7.6 12 L5.4 12 M8.89 8.89 L7.33 7.33 M12 7.6 L12 5.4 M15.11 8.89 L16.67 7.33"/>' +
                    '<circle cx="12" cy="12" r="4.8"/>' +
                    '<circle cx="12" cy="12" r="1.5"/>'
        } else if (type === "power") {
            paths = '<path d="M12 3.8 v7"/>' +
                    '<path d="M6.9 6.7 a7 7 0 1 0 10.2 0"/>'
        }
        var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" ' +
                  'fill="none" stroke="' + color + '" stroke-width="1.5" stroke-linecap="round" ' +
                  'stroke-linejoin="round">' + paths + '</svg>'
        return "data:image/svg+xml;utf8," + encodeURIComponent(svg)
    }
}