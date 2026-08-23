import QtQuick 2.15
import QtQuick.Layouts 1.15
import "qrc:/shell/components/themes/Theme.js" as T

// ==================================================================
// Dashboard tab - integrated from luckfox_dashboard app
// Adapted to fit the Luckfox Shell content area (688x440)
// All data flows through the shared "sysInfo" context property
// ==================================================================
Item {
    id: rootD

    // ─── THEME (live light/dark) ──────────────
    readonly property bool dk: appTheme.isDark
    readonly property var tD:  T.dark
    readonly property var tL:  T.light
    readonly property var dT:  dk ? T.dashboard.dark  : T.dashboard.light

    readonly property color cardC:      dk ? tD.bgCard    : tL.bgCard
    readonly property color cardBorder: dk ? tD.border    : tL.border
    readonly property color barC:       dT.barColor
    readonly property color textPri:    dk ? tD.textPrimary : tL.textPrimary
    readonly property color textSec:    dk ? tD.textSecondary : tL.textSecondary
    readonly property color blueC:      dk ? tD.blue  : tL.blue
    readonly property color amberC:     dk ? tD.amber : tL.amber
    readonly property color greenC:     dk ? tD.green : tL.green
    readonly property color redC:       dk ? tD.red   : tL.red
    readonly property color cyanC:      dk ? tD.cyan  : tL.cyan
    readonly property color accent:     dk ? tD.accent : tL.accent

    // ─── STATE ───────────────────────────
    property int dashTab: 0
    property var cpuHist: []
    property var ramHist: []
    property var tmpHist: []
    property var humHist: []
    property var tmpStats: ({ min: 0, avg: 0, max: 0 })
    property var humStats: ({ min: 0, avg: 0, max: 0 })
    property var allCanvases: []

    function computeStats(arr) {
        if (!arr || arr.length === 0) return { min: 0, avg: 0, max: 0 }
        var mn = arr[0], mx = arr[0], sum = 0
        for (var i = 0; i < arr.length; i++) {
            var v = arr[i]
            if (v < mn) mn = v
            if (v > mx) mx = v
            sum += v
        }
        return { min: mn, avg: sum / arr.length, max: mx }
    }

    function repaintAll() {
        for (var i = 0; i < allCanvases.length; i++)
            if (allCanvases[i]) allCanvases[i].repaint()
    }

    // ─── HEADER ──────────────────────────
    Item {
        id: dHdr
        width: parent.width; height: 38
        Column { anchors.left: parent.left; anchors.leftMargin: 4
                 anchors.verticalCenter: parent.verticalCenter; spacing: 0
            Text { text: sysInfo ? sysInfo.currentTime : "00:00:00"
                font.pixelSize: T.sizes.dataPrimary; font.family: T.fontMono; font.bold: true; color: greenC }
            Text { text: "UTC+7"; font.pixelSize: T.sizes.tertiary; font.family: T.fontMono; color: textSec }
        }
        Text { anchors.centerIn: parent; text: "SYSTEM MONITOR"
            font.pixelSize: T.sizes.tabLabel; font.family: T.fontMono; font.bold: true
            color: textPri; font.letterSpacing: 2 }
        Column { anchors.right: parent.right; anchors.rightMargin: 4
                 anchors.verticalCenter: parent.verticalCenter; spacing: 0
            Text { text: sysInfo ? sysInfo.ipAddress : "0.0.0.0"
                font.pixelSize: T.sizes.dataPrimary; font.family: T.fontMono; font.bold: true; color: blueC }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1
            color: dk ? "#1a2234" : dT.hairline }
    }

    // ─── INTERNAL TAB STRIP ──────────────
    Rectangle {
        id: dTabs
        y: 38; width: parent.width; height: 32
        color: barC
        border { width: 1; color: cardBorder }
        Row {
            anchors.fill: parent
            Repeater {
                model: ["Overview", "Sensors", "CPU", "Network"]
                Item {
                    width: parent.width / 4; height: 32
                    Text {
                        anchors.centerIn: parent; text: modelData
                        font.pixelSize: T.sizes.tertiary; font.family: T.font; font.bold: true
                        color: rootD.dashTab === index ? textPri : textSec
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: rootD.dashTab === index ? 40 : 0; height: 2; radius: 1; color: accent
                        Behavior on width { NumberAnimation { duration: 200 } }
                    }
                    MouseArea { anchors.fill: parent; onClicked: rootD.dashTab = index }
                }
            }
        }
    }

    // ─── CONTENT ─────────────────────────
    StackLayout {
        y: 70; width: parent.width; height: parent.height - 70
        currentIndex: rootD.dashTab

        // ═══════ OVERVIEW ═══════
        Item {
            Grid {
                columns: 2; spacing: 6
                anchors.fill: parent; anchors.margins: 6

                // RAM
                Rectangle {
                    width: 335; height: 176; radius: 8; color: cardC
                    border { width: 1; color: cardBorder }
                    Rectangle { width: 3; height: 176; radius: 2; color: blueC }
                    Row { x: 10; y: 6; spacing: 5
                        Rectangle { width: 6; height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter; color: blueC }
                        Text { text: "RAM"; font.pixelSize: T.sizes.tertiary; font.family: T.font; font.bold: true; color: textPri }
                    }
                    Gauge {
                        id: gaugeRam
                        x: 10; y: 24; width: 130; height: 130
                        value: sysInfo ? sysInfo.ramPercent : 0
                        maxValue: 100; unit: "%"; arcColor: blueC; lineWidth: 8
                    }
                    Column { x: 152; y: 28; spacing: 5
                        StatItem { label: "USED"; value: (sysInfo ? sysInfo.ramUsed.toFixed(0) : "0") + " MB"; valueSize: 13 }
                        StatItem { label: "TOTAL"; value: (sysInfo ? sysInfo.ramTotal.toFixed(0) : "0") + " MB"; valueColor: blueC; valueSize: 13 }
                        StatItem { label: "FREE"; value: (sysInfo ? (sysInfo.ramTotal - sysInfo.ramUsed).toFixed(0) : "0") + " MB"; valueColor: blueC; valueSize: 13 }
                    }
                }

                // STORAGE
                Rectangle {
                    width: 335; height: 176; radius: 8; color: cardC
                    border { width: 1; color: cardBorder }
                    Rectangle { width: 3; height: 176; radius: 2; color: amberC }
                    Row { x: 10; y: 6; spacing: 5
                        Rectangle { width: 6; height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter; color: amberC }
                        Text { text: "STORAGE"; font.pixelSize: 10; font.family: "DejaVu Sans"; font.bold: true; color: textPri }
                    }
                    Gauge {
                        id: gaugeStor
                        x: 10; y: 24; width: 130; height: 130
                        value: sysInfo ? sysInfo.storagePercent : 0
                        maxValue: 100; unit: "%"; arcColor: amberC; lineWidth: 8
                    }
                    Column { x: 152; y: 28; spacing: 5
                        StatItem { label: "USED"; value: (sysInfo ? sysInfo.storageUsed.toFixed(0) : "0") + " MB"; valueSize: 13 }
                        StatItem { label: "TOTAL"; value: (sysInfo ? sysInfo.storageTotal.toFixed(0) : "0") + " MB"; valueColor: amberC; valueSize: 13 }
                        StatItem { label: "FREE"; value: (sysInfo ? (sysInfo.storageTotal - sysInfo.storageUsed).toFixed(0) : "0") + " MB"; valueColor: amberC; valueSize: 13 }
                    }
                }

                // CPU
                Rectangle {
                    width: 335; height: 176; radius: 8; color: cardC
                    border { width: 1; color: cardBorder }
                    Rectangle { width: 3; height: 176; radius: 2; color: greenC }
                    Row { x: 10; y: 6; spacing: 5
                        Rectangle { width: 6; height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter; color: greenC }
                        Text { text: "CPU"; font.pixelSize: 10; font.family: "DejaVu Sans"; font.bold: true; color: textPri }
                    }
                    Gauge {
                        id: gaugeCpu
                        x: 10; y: 24; width: 130; height: 130
                        value: sysInfo ? sysInfo.cpuUsage : 0
                        maxValue: 100; unit: "%"; arcColor: greenC; lineWidth: 8
                    }
                    Column { x: 152; y: 28; spacing: 5
                        StatItem { label: "FREQUENCY"; value: (sysInfo ? sysInfo.cpuFreq.toFixed(0) : "0") + " MHz"; valueSize: 13 }
                        StatItem { label: "LOAD"; value: (sysInfo ? sysInfo.cpuUsage.toFixed(1) : "0") + " %"; valueColor: greenC; valueSize: 13 }
                        StatItem { label: "BOARD TEMP"
                            value: sysInfo && sysInfo.sensorAvailable
                                   ? sysInfo.temperature.toFixed(1) + " °C" : "--"
                            valueColor: redC; valueSize: 13 }
                    }
                    MouseArea { anchors.fill: parent; onClicked: rootD.dashTab = 2 }
                }

                // AHT30 SENSOR
                Rectangle {
                    width: 335; height: 176; radius: 8; color: cardC
                    border { width: 1; color: cardBorder }
                    Rectangle { width: 3; height: 176; radius: 2
                        color: sysInfo && sysInfo.sensorAvailable ? redC : dT.offline }
                    Row { x: 10; y: 6; spacing: 5
                        Rectangle { width: 6; height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter
                            color: sysInfo && sysInfo.sensorAvailable ? greenC : redC }
                        Text { text: "AHT30 SENSOR"; font.pixelSize: 10; font.family: "DejaVu Sans"; font.bold: true; color: textPri }
                    }
                    Text { anchors.right: parent.right; anchors.rightMargin: 10; y: 6
                        text: sysInfo && sysInfo.sensorAvailable ? "ONLINE" : "OFFLINE"
                        font.pixelSize: 8; font.family: "DejaVu Sans Mono"; font.bold: true
                        color: sysInfo && sysInfo.sensorAvailable ? greenC : redC }
                    Gauge {
                        id: gTmpMini
                        x: 8; y: 22; width: 130; height: 130
                        value: sysInfo && sysInfo.sensorAvailable ? sysInfo.temperature : 0
                        maxValue: 60; unit: "°C"; arcColor: redC; lineWidth: 8; showTicks: false
                        opacity: sysInfo && sysInfo.sensorAvailable ? 1 : 0.35
                    }
                    Gauge {
                        id: gHumMini
                        x: 148; y: 22; width: 130; height: 130
                        value: sysInfo && sysInfo.sensorAvailable ? sysInfo.humidity : 0
                        maxValue: 100; unit: "%"; arcColor: cyanC; lineWidth: 8; showTicks: false
                        opacity: sysInfo && sysInfo.sensorAvailable ? 1 : 0.35
                    }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; y: 156
                        text: sysInfo && sysInfo.sensorAvailable
                              ? sysInfo.temperature.toFixed(1) + "°C   ·   " + sysInfo.humidity.toFixed(1) + "%"
                              : "SENSOR NOT DETECTED"
                        font.pixelSize: 9; font.family: "DejaVu Sans Mono"; font.bold: true
                        color: sysInfo && sysInfo.sensorAvailable ? textPri : redC }
                    MouseArea { anchors.fill: parent; onClicked: rootD.dashTab = 1 }
                }
            }
        }

        // ═══════ SENSORS ═══════
        Item {
            Row {
                anchors.centerIn: parent; spacing: 10

                // TEMPERATURE
                Rectangle {
                    width: 334; height: 358; radius: 10; color: cardC
                    border { width: 1; color: cardBorder }
                    Row { x: 12; y: 8; spacing: 5
                        Rectangle { width: 7; height: 7; radius: 3.5; anchors.verticalCenter: parent.verticalCenter; color: redC }
                        Text { text: "TEMPERATURE"; font.pixelSize: 11; font.family: "DejaVu Sans"; font.bold: true; color: redC }
                    }
                    Gauge {
                        id: gaugeTemp
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 18; width: 142; height: 142
                        value: sysInfo && sysInfo.sensorAvailable ? sysInfo.temperature : 0
                        maxValue: 60; unit: "°C"; arcColor: redC; lineWidth: 9
                        opacity: sysInfo && sysInfo.sensorAvailable ? 1 : 0.35
                    }
                    Row { anchors.horizontalCenter: parent.horizontalCenter; y: 166; spacing: 24
                        StatItem { label: "MIN"; value: rootD.tmpStats.min.toFixed(1) + "°"; valueColor: textPri; valueSize: 12 }
                        StatItem { label: "AVG"; value: rootD.tmpStats.avg.toFixed(1) + "°"; valueColor: amberC; valueSize: 12 }
                        StatItem { label: "MAX"; value: rootD.tmpStats.max.toFixed(1) + "°"; valueColor: redC; valueSize: 12 }
                    }
                    AreaChart {
                        id: chartTemp
                        x: 10; y: 200; width: 314; height: 148
                        values: rootD.tmpHist; lineColor: redC; lineFill: dk ? "#22ef4444" : "#22dc2626"
                        minValue: 0; maxValue: 60; unit: "°C"
                    }
                }

                // HUMIDITY
                Rectangle {
                    width: 334; height: 358; radius: 10; color: cardC
                    border { width: 1; color: cardBorder }
                    Row { x: 12; y: 8; spacing: 5
                        Rectangle { width: 7; height: 7; radius: 3.5; anchors.verticalCenter: parent.verticalCenter; color: cyanC }
                        Text { text: "HUMIDITY"; font.pixelSize: 11; font.family: "DejaVu Sans"; font.bold: true; color: cyanC }
                    }
                    Gauge {
                        id: gaugeHum
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 18; width: 142; height: 142
                        value: sysInfo && sysInfo.sensorAvailable ? sysInfo.humidity : 0
                        maxValue: 100; unit: "%"; arcColor: cyanC; lineWidth: 9
                        opacity: sysInfo && sysInfo.sensorAvailable ? 1 : 0.35
                    }
                    Row { anchors.horizontalCenter: parent.horizontalCenter; y: 166; spacing: 24
                        StatItem { label: "MIN"; value: rootD.humStats.min.toFixed(1) + "%"; valueColor: textPri; valueSize: 12 }
                        StatItem { label: "AVG"; value: rootD.humStats.avg.toFixed(1) + "%"; valueColor: amberC; valueSize: 12 }
                        StatItem { label: "MAX"; value: rootD.humStats.max.toFixed(1) + "%"; valueColor: cyanC; valueSize: 12 }
                    }
                    AreaChart {
                        id: chartHum
                        x: 10; y: 200; width: 314; height: 148
                        values: rootD.humHist; lineColor: cyanC; lineFill: dk ? "#2206b6d4" : "#220891b2"
                        minValue: 0; maxValue: 100; unit: "%"
                    }
                }
            }
        }

        // ═══════ CPU DETAIL ═══════
        Item {
            Column {
                anchors.centerIn: parent; spacing: 10

                Rectangle {
                    width: 676; height: 276; radius: 8; color: cardC
                    border { width: 1; color: cardBorder }
                    Row { x: 12; y: 8; spacing: 5
                        Rectangle { width: 7; height: 7; radius: 3.5; anchors.verticalCenter: parent.verticalCenter; color: greenC }
                        Text { text: "CPU USAGE — 60 SECOND HISTORY"
                            font.pixelSize: 11; font.family: "DejaVu Sans Mono"; font.bold: true; color: greenC }
                    }
                    AreaChart {
                        id: cpuChart
                        x: 12; y: 30; width: 652; height: 234
                        values: rootD.cpuHist; lineColor: greenC; lineFill: dk ? "#1a10b981" : "#1a16a34a"
                        minValue: 0; maxValue: 100; unit: "%"
                    }
                }

                Row { spacing: 10
                    Repeater {
                        model: [
                            { label: "FREQUENCY", val: sysInfo ? sysInfo.cpuFreq.toFixed(0) : "0", unit: "MHz", col: textPri },
                            { label: "CPU LOAD", val: sysInfo ? sysInfo.cpuUsage.toFixed(1) : "0", unit: "%", col: greenC },
                            { label: "STATUS", val: (sysInfo && sysInfo.cpuUsage > 80) ? "HIGH" : (sysInfo && sysInfo.cpuUsage > 50) ? "MEDIUM" : "IDLE",
                              unit: "", col: (sysInfo && sysInfo.cpuUsage > 80) ? redC : (sysInfo && sysInfo.cpuUsage > 50) ? amberC : greenC },
                            { label: "BOARD TEMP", val: sysInfo && sysInfo.sensorAvailable ? sysInfo.temperature.toFixed(1) : "--", unit: "°C", col: redC }
                        ]
                        Rectangle {
                            width: 164; height: 60; radius: 6; color: cardC
                            border { width: 1; color: cardBorder }
                            Text { x: 10; y: 6; text: modelData.label; font.pixelSize: 9; font.family: "DejaVu Sans Mono"; font.bold: true; color: textSec }
                            Text { x: 10; y: 26; text: modelData.val; font.pixelSize: 17; font.family: "DejaVu Sans Mono"; font.bold: true; color: modelData.col }
                            Text { x: 96; y: 32; text: modelData.unit; font.pixelSize: 9; font.family: "DejaVu Sans"; color: textSec }
                        }
                    }
                }
            }
        }

        // ═══════ NETWORK ═══════
        Item {
            Grid {
                columns: 3; spacing: 6
                anchors.fill: parent; anchors.margins: 6

                Rectangle {
                    width: 221; height: 130; radius: 8; color: cardC
                    border { width: 1; color: cardBorder }
                    Rectangle { width: 3; height: 130; radius: 2; color: blueC }
                    Text { x: 14; y: 10; text: "INTERFACE"; font.pixelSize: 9; font.family: "DejaVu Sans Mono"; font.bold: true; color: textSec }
                    Text { x: 14; y: 42; text: sysInfo ? sysInfo.ifaceName : "wlan0"
                        font.pixelSize: 22; font.family: "DejaVu Sans Mono"; font.bold: true; color: textPri }
                }
                Rectangle {
                    width: 221; height: 130; radius: 8; color: cardC
                    border { width: 1; color: cardBorder }
                    Rectangle { width: 3; height: 130; radius: 2; color: blueC }
                    Text { x: 14; y: 10; text: "IP ADDRESS"; font.pixelSize: 9; font.family: "DejaVu Sans Mono"; font.bold: true; color: textSec }
                    Text { x: 14; y: 44; text: sysInfo ? sysInfo.ipAddress : "0.0.0.0"
                        font.pixelSize: 20; font.family: "DejaVu Sans Mono"; font.bold: true; color: textPri }
                }
                Rectangle {
                    width: 221; height: 130; radius: 8; color: cardC
                    border { width: 1; color: cardBorder }
                    Rectangle { width: 3; height: 130; radius: 2
                        color: sysInfo && sysInfo.wifiSSID !== "Not connected" ? greenC : redC }
                    Text { x: 14; y: 10; text: "WIFI STATUS"; font.pixelSize: 9; font.family: "DejaVu Sans Mono"; font.bold: true; color: textSec }
                    Row { x: 14; y: 38; spacing: 7
                        Rectangle { width: 9; height: 9; radius: 4.5; anchors.verticalCenter: parent.verticalCenter
                            color: sysInfo && sysInfo.wifiSSID !== "Not connected" ? greenC : redC }
                        Text { text: sysInfo && sysInfo.wifiSSID !== "Not connected" ? "CONNECTED" : "OFFLINE"
                            font.pixelSize: 14; font.family: "DejaVu Sans Mono"; font.bold: true
                            color: sysInfo && sysInfo.wifiSSID !== "Not connected" ? greenC : redC }
                    }
                    Text { x: 14; y: 66; text: sysInfo ? sysInfo.wifiSSID : "Not connected"
                        font.pixelSize: 12; font.family: "DejaVu Sans Mono"; font.bold: true; color: textPri }
                    Text { x: 14; y: 88; text: sysInfo && sysInfo.linkSpeed > 0 ? sysInfo.linkSpeed + " Mb/s" : "—"
                        font.pixelSize: 10; font.family: "DejaVu Sans Mono"; color: textSec }
                }

                Rectangle {
                    width: 221; height: 92; radius: 8; color: cardC
                    border { width: 1; color: cardBorder }
                    Rectangle { width: 3; height: 92; radius: 2; color: accent }
                    Text { x: 14; y: 10; text: "TIME (UTC+7)"; font.pixelSize: 9; font.family: "DejaVu Sans Mono"; font.bold: true; color: textSec }
                    Text { x: 14; y: 40; text: sysInfo ? sysInfo.currentTime : "00:00:00"
                        font.pixelSize: 21; font.family: "DejaVu Sans Mono"; font.bold: true; color: greenC }
                }
                Rectangle {
                    width: 449; height: 92; radius: 8; color: cardC
                    border { width: 1; color: cardBorder }
                    Rectangle { width: 3; height: 92; radius: 2; color: accent }
                    Text { x: 14; y: 10; text: "DEVICE"; font.pixelSize: 9; font.family: "DejaVu Sans Mono"; font.bold: true; color: textSec }
                    Row { x: 14; y: 42; spacing: 32
                        Text { text: "Luckfox Pico Ultra W"; font.pixelSize: 13; font.family: "DejaVu Sans Mono"; font.bold: true; color: textPri }
                        Text { text: "RV1106 SoC"; font.pixelSize: 13; font.family: "DejaVu Sans Mono"; font.bold: true; color: textPri }
                        Text { text: "Linux 6.1"; font.pixelSize: 13; font.family: "DejaVu Sans Mono"; font.bold: true; color: textPri }
                    }
                }
            }
        }
    } // StackLayout

    // ─── REFRESH DRIVER ───────────────────
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            sysInfo.updateAll()
            var c = rootD.cpuHist; c.push(sysInfo.cpuUsage); if (c.length > 60) c.shift(); rootD.cpuHist = c
            var r = rootD.ramHist; r.push(sysInfo.ramPercent); if (r.length > 60) r.shift(); rootD.ramHist = r
            var t = rootD.tmpHist; t.push(sysInfo.temperature); if (t.length > 60) t.shift(); rootD.tmpHist = t
            var h = rootD.humHist; h.push(sysInfo.humidity); if (h.length > 60) h.shift(); rootD.humHist = h
            rootD.tmpStats = rootD.computeStats(rootD.tmpHist)
            rootD.humStats = rootD.computeStats(rootD.humHist)
            rootD.repaintAll()
        }
    }

    Component.onCompleted: {
        sysInfo.updateAll()
        allCanvases = [gaugeRam, gaugeStor, gaugeCpu, gTmpMini, gHumMini,
                       gaugeTemp, gaugeHum, chartTemp, chartHum, cpuChart]
    }
}
