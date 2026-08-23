import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import "components"
import "components/themes/Theme.js" as T

// ------------------------------------------------------------------
// Luckfox Shell - 800x480 automotive infotainment launcher
//
//   * TabBar: ShellTabBar.qml — 72px vertical rail, dark glass,
//     teal accent (#00e5c3), ripple touch feedback, left accent bar,
//     right edge light (xem chi tiết trong file tabbar).
//   * Apps: Dashboard, Music, Calendar, WiFi, Recorder, Wireframe.
//     Các trang chưa có app thật đang dùng EmptyPage — gắn Loader +
//     source qrc:/... vào từng trang (đánh dấu "APP PATH").
//   * Footer Settings -> trang Settings (index 6), Power -> signal
//     powerRequested (tích hợp hành vi tắt máy sau).
//   * Content: StackLayout - trang mới trượi ngang phải->trái
//     (translateX 60 -> 0, OutBack), không fade/scale.
// ------------------------------------------------------------------

Window {
    id: root
    visible: true
    width: T.layout.screenW
    height: T.layout.screenH
    title: "Luckfox Shell"

    // ---- Live theme selection (whole app) ----
    readonly property bool dk: appTheme.isDark
    readonly property var tD:  T.dark
    readonly property var tL:  T.light
    readonly property color bgColor: dk ? tD.bgBottom : tL.bgBottom
    readonly property color pageTop:  dk ? tD.pageTop  : tL.pageTop
    readonly property color pageBot:  dk ? tD.pageBottom : tL.pageBottom
    readonly property color pageBorder: dk ? tD.border : tL.border

    color: bgColor

    property int currentTab: 0
    property int tabCount: 6  // 6 apps; settings page removed

    // ---- Background ----
    Rectangle {
        id: background
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.pageTop }
            GradientStop { position: 1.0; color: root.pageBot }
        }
    }

    // ==================================================================
    //  VERTICAL TAB BAR
    // ==================================================================
    ShellTabBar {
        id: tabBar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        currentIndex: root.currentTab
        onTabChanged: {
            root.currentTab = index
            // Single PCM (hw:0,0) on RV1106 — only one app can hold the device:
            // entering Recorder stops music (mpg123), entering Music stops the
            // recorder playback, otherwise snd_pcm_open fails "Device busy".
            if (index === 4) audioPlayer.stop()
            if (index === 1) voicePlayer.stopPlayback()
            tabBar.forceActiveFocus()
        }
        onPowerRequested: {
            // TODO: tích hợp hành vi tắt máy (shutdown / standby)
        }
    }

    // ==================================================================
    //  CONTENT - StackLayout, trang mới trượt ngang phải -> trái
    // ==================================================================
    StackLayout {
        id: pages
        anchors.left: tabBar.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: T.spacing.md
        anchors.rightMargin: T.spacing.md
        anchors.topMargin: T.spacing.md
        anchors.bottomMargin: T.spacing.md
        currentIndex: currentTab

        // ---- Page 0: Dashboard ----
        Item {
            transform: Translate {
                x: pages.currentIndex === 0 ? 0 : 60
                Behavior on x {
                    NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: T.radius.lg
                clip: true
                color: root.pageTop
                border.width: 1; border.color: root.pageBorder
                Loader {
                    anchors.fill: parent
                    anchors.margins: T.spacing.sm
                    source: "qrc:/dashboard/qml/DashboardTab.qml"
                }
            }
        }

        // ---- Page 1: Music ----
        Item {
            transform: Translate {
                x: pages.currentIndex === 1 ? 0 : 60
                Behavior on x {
                    NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: T.radius.lg
                clip: true
                color: root.pageTop
                border.width: 1; border.color: root.pageBorder
                Loader {
                    anchors.fill: parent
                    anchors.margins: T.spacing.sm
                    source: "qrc:/music/qml/MainScreen.qml"
                }
            }
        }

        // ---- Page 2: Calendar ----
        Item {
            transform: Translate {
                x: pages.currentIndex === 2 ? 0 : 60
                Behavior on x {
                    NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: T.radius.lg
                clip: true
                color: root.pageTop
                border.width: 1; border.color: root.pageBorder
                Loader {
                    anchors.fill: parent
                    anchors.margins: T.spacing.sm
                    source: "qrc:/calendar/qml/CalendarTab.qml"
                }
            }
        }

        // ---- Page 3: WiFi ----
        Item {
            transform: Translate {
                x: pages.currentIndex === 3 ? 0 : 60
                Behavior on x {
                    NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: T.radius.lg
                clip: true
                color: root.pageTop
                border.width: 1; border.color: root.pageBorder
                Loader {
                    anchors.fill: parent
                    anchors.margins: T.spacing.sm
                    source: "qrc:/wifi/qml/WifiTab.qml"
                }
            }
        }

        // ---- Page 4: Recorder ----
        Item {
            transform: Translate {
                x: pages.currentIndex === 4 ? 0 : 60
                Behavior on x {
                    NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: T.radius.lg
                clip: true
                color: root.pageTop
                border.width: 1; border.color: root.pageBorder
                Loader {
                    anchors.fill: parent
                    anchors.margins: T.spacing.sm
                    source: "qrc:/voicetest/qml/main.qml"
                }
            }
        }

        // ---- Page 5: Wireframe ----
        Item {
            transform: Translate {
                x: pages.currentIndex === 5 ? 0 : 60
                Behavior on x {
                    NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: T.radius.lg
                clip: true
                color: root.pageTop
                border.width: 1; border.color: root.pageBorder
                Loader {
                    anchors.fill: parent
                    anchors.margins: T.spacing.sm
                    source: "qrc:/wireframe/qml/WireframeTab.qml"
                }
            }
        }

        // ---- Page 6: Settings — removed (light mode retired, no settings UI)
    }
}
