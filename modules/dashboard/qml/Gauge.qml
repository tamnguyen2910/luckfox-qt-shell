import QtQuick 2.15
import "qrc:/shell/components/themes/Theme.js" as T

Item {
    id: rootG

    // ─── API ───────────────────────────────
    property real value: 0
    property real minValue: 0
    property real maxValue: 100
    readonly property bool dk: appTheme.isDark
    readonly property var tD: T.dark
    readonly property var tL: T.light

    property color arcColor: dk ? tD.blue : tL.blue
    property color trackColor: dk ? tD.divider : tL.divider
    property string unit: ""
    property int decimals: 1
    property bool showZones: true
    property bool showTicks: true
    property int lineWidth: 10
    property int valueSize: 25
    property int unitSize: 16
    property var zoneBreaks: [0.60, 0.85]
    property var zoneColors: [dk ? tD.green : tL.green, dk ? tD.amber : tL.amber, dk ? tD.red : tL.red]

    function repaint() { gaugeCanvas.requestPaint() }

    // ─── Coordinate helpers ────────────────
    function tickReserve() { return rootG.showTicks ? Math.max(6, rootG.lineWidth) * 1.1 : 0 }
    function radius() { return Math.min(rootG.width, rootG.height) / 2 - Math.max(rootG.lineWidth, 6) - rootG.tickReserve() }
    function arcStart() { return Math.PI * 0.75 }
    function arcSpan() { return Math.PI * 1.5 }
    function progress() {
        if (rootG.maxValue <= rootG.minValue) return 0
        return Math.max(0, Math.min(1, (rootG.value - rootG.minValue) / (rootG.maxValue - rootG.minValue)))
    }

    function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    Canvas {
        id: gaugeCanvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            var w = width, h = height
            ctx.clearRect(0, 0, w, h)

            var cx = w / 2, cy = h / 2
            var r = rootG.radius()
            var sa = rootG.arcStart()
            var span = rootG.arcSpan()
            var prog = rootG.progress()
            var lw = Math.max(6, rootG.lineWidth)

            // ── Track ──
            ctx.lineCap = "round"
            ctx.beginPath()
            ctx.arc(cx, cy, r, sa, sa + span)
            ctx.strokeStyle = rootG.trackColor
            ctx.lineWidth = lw
            ctx.stroke()

            // ── Zone segments (thin, behind progress) ──
            if (rootG.showZones) {
                ctx.lineWidth = lw * 0.45
                var prev = 0
                for (var z = 0; z < rootG.zoneBreaks.length; z++) {
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, sa + prev * span + 0.02, sa + rootG.zoneBreaks[z] * span - 0.02)
                    ctx.strokeStyle = rootG.withAlpha(rootG.zoneColors[z], 0.85)
                    ctx.stroke()
                    prev = rootG.zoneBreaks[z]
                }
                ctx.beginPath()
                ctx.arc(cx, cy, r, sa + prev * span + 0.02, sa + span - 0.02)
                ctx.strokeStyle = rootG.withAlpha(rootG.zoneColors[rootG.zoneBreaks.length], 0.85)
                ctx.stroke()
            }

            // ── Progress arc (glow + main) ──
            if (prog > 0.004) {
                ctx.beginPath()
                ctx.arc(cx, cy, r, sa, sa + prog * span)
                ctx.strokeStyle = rootG.withAlpha(rootG.arcColor, 0.18)
                ctx.lineWidth = lw + 7
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(cx, cy, r, sa, sa + prog * span)
                ctx.strokeStyle = rootG.arcColor
                ctx.lineWidth = lw
                ctx.stroke()
            }

            // ── Tick marks (0 / 25 / 50 / 75 / 100) ──
            if (rootG.showTicks) {
                ctx.lineCap = "round"
                for (var t = 0; t <= 4; t++) {
                    var ang = sa + (t / 4) * span
                    var r1 = r + lw * 0.65
                    var r2 = r + lw * (t % 2 === 0 ? 1.75 : 1.15)
                    ctx.beginPath()
                    ctx.moveTo(cx + r1 * Math.cos(ang), cy + r1 * Math.sin(ang))
                    ctx.lineTo(cx + r2 * Math.cos(ang), cy + r2 * Math.sin(ang))
                    ctx.strokeStyle = (t === 4 && prog > 0.95) ? rootG.dk ? "#ef4444" : rootG.tL.red : rootG.dk ? "#2c3752" : rootG.tL.gaugeTick
                    ctx.lineWidth = t % 2 === 0 ? 2 : 1.5
                    ctx.stroke()
                }
            }

            // ── End-point marker ──
            if (prog > 0.004) {
                var ex = cx + r * Math.cos(sa + prog * span)
                var ey = cy + r * Math.sin(sa + prog * span)
                ctx.beginPath()
                ctx.arc(ex, ey, lw * 1.05, 0, 2 * Math.PI)
                ctx.fillStyle = rootG.withAlpha(rootG.arcColor, 0.25)
                ctx.fill()
                ctx.beginPath()
                ctx.arc(ex, ey, lw * 0.45, 0, 2 * Math.PI)
                ctx.fillStyle = rootG.arcColor
                ctx.fill()
            }
        }
    }

    // ── Center value + unit (crisp QML text) ──
    Column {
        anchors.centerIn: parent
        spacing: 1
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: rootG.value.toFixed(rootG.decimals)
            font.pixelSize: Math.max(11, rootG.valueSize)
            font.family: T.fontMono
            font.bold: true
            color: dk ? "#e4e8f0" : "#253240"
        }
        Text {
            visible: rootG.unit !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            text: rootG.unit
            font.pixelSize: Math.max(8, rootG.unitSize)
            font.family: T.fontMono
            color: dk ? "#8a90a2" : "#5a6579"
        }
    }

    // ── Min / max corner labels ──
    Text {
        id: tMin
        text: rootG.minValue.toFixed(0)
        font.pixelSize: Math.max(7, rootG.width * 0.075)
        font.family: T.fontMono
        color: rootG.dk ? "#8a90a2" : "#5a6579"
        x: rootG.width / 2 - rootG.radius() * 0.707 - tMin.contentWidth / 2 - 2
        y: rootG.height / 2 + rootG.radius() * 0.707 - tMin.contentHeight / 2 - 2
    }
    Text {
        id: tMax
        text: rootG.maxValue.toFixed(0)
        font.pixelSize: Math.max(7, rootG.width * 0.075)
        font.family: T.fontMono
        color: rootG.dk ? "#8a90a2" : "#5a6579"
        x: rootG.width / 2 + rootG.radius() * 0.707 - tMax.contentWidth / 2 + 2
        y: rootG.height / 2 + rootG.radius() * 0.707 - tMax.contentHeight / 2 - 2
    }
}