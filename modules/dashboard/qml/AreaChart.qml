import QtQuick 2.15
import "qrc:/shell/components/themes/Theme.js" as T

Canvas {
    id: chartRoot

    // ─── THEME ─────────────────────────────
    readonly property bool dk: appTheme.isDark
    readonly property var tD: T.dark
    readonly property var tL: T.light
    readonly property color gridCol:   dk ? "#1e293b" : "#d5dbe6"
    readonly property color labelCol:  dk ? "#5a6577" : "#5a6579"
    readonly property color badgeBg:   dk ? "#1a2234" : "#eef2f8"

    // ─── API ───────────────────────────────
    property var values: []
    property color lineColor: dk ? tD.green : tL.green
    property color lineFill: dk ? "#1a10b981" : "#1a16a34a"
    property real minValue: 0
    property real maxValue: 100
    property string unit: "%"
    property int maxPoints: 60
    property bool showAxis: true
    property bool showBadge: true
    property color textColor: dk ? tD.textPrimary : tL.textPrimary
    readonly property string fontFamily: "DejaVu Sans Mono"

    function repaint() { requestPaint() }
    function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    // Padding for axes
    function padL() { return chartRoot.showAxis ? 28 : 4 }
    function padR() { return 10 }
    function padT() { return 10 }
    function padB() { return chartRoot.showAxis ? 16 : 4 }
    function px(i) { return chartRoot.padL() + (i / Math.max(1, chartRoot.maxPoints - 1)) * (width - chartRoot.padL() - chartRoot.padR()) }
    function py(v) {
        var ch = height - chartRoot.padT() - chartRoot.padB()
        return chartRoot.padT() + ch - ((v - chartRoot.minValue) / Math.max(0.001, chartRoot.maxValue - chartRoot.minValue)) * ch
    }

    onPaint: {
        var ctx = getContext("2d")
        var w = width, h = height
        ctx.clearRect(0, 0, w, h)
        var cw = w - padL() - padR()
        var ch = h - padT() - padB()

        // ── Grid + y-axis labels ──
        if (showAxis) {
            ctx.strokeStyle = chartRoot.gridCol
            ctx.lineWidth = 1
            ctx.fillStyle = chartRoot.labelCol
            ctx.font = "9px 'DejaVu Sans Mono'"
            // Use monospace from theme system (T.fontMono = "DejaVu Sans Mono")
            ctx.textAlign = "right"
            for (var g = 0; g <= 4; g++) {
                var gy = padT() + (g / 4) * ch
                ctx.beginPath()
                ctx.moveTo(padL(), gy)
                ctx.lineTo(w - padR(), gy)
                ctx.stroke()
                var gv = maxValue - (g / 4) * (maxValue - minValue)
                var lbl = (Math.round(gv * 10) / 10).toFixed(Math.abs(gv) >= 100 || Math.abs(gv) >= 20 || gv % 1 === 0 ? 0 : 1)
                ctx.fillText(lbl, padL() - 5, gy + 3)
            }

            // x-axis labels
            ctx.textAlign = "left"
            ctx.fillText("-" + ((maxPoints - 1) / 60).toFixed(0) + "0s", padL(), h - 3)
            ctx.textAlign = "center"
            ctx.fillText("-30s", padL() + cw * 0.5, h - 3)
            ctx.textAlign = "right"
            ctx.fillText("now", w - padR(), h - 3)
        }

        var n = values.length
        if (n < 2) return

        // ── Smoothed polyline (Catmull-Rom → Bezier) ──
        var pts = []
        for (var i = 0; i < n; i++)
            pts.push({ x: px(i), y: py(values[i]) })

        ctx.beginPath()
        ctx.moveTo(pts[0].x, padT() + ch)
        ctx.lineTo(pts[0].x, pts[0].y)
        for (var s = 0; s < pts.length - 1; s++) {
            var p0 = pts[Math.max(0, s - 1)], p1 = pts[s], p2 = pts[s + 1], p3 = pts[Math.min(pts.length - 1, s + 2)]
            ctx.bezierCurveTo(
                p1.x + (p2.x - p0.x) / 6, p1.y + (p2.y - p0.y) / 6,
                p2.x - (p3.x - p1.x) / 6, p2.y - (p3.y - p1.y) / 6,
                p2.x, p2.y)
        }
        ctx.lineTo(pts[n - 1].x, padT() + ch)
        ctx.closePath()
        var grad = ctx.createLinearGradient(0, padT(), 0, padT() + ch)
        grad.addColorStop(0, lineFill)
        grad.addColorStop(1, withAlpha(lineColor, 0.02))
        ctx.fillStyle = grad
        ctx.fill()

        // ── Line stroke ──
        ctx.beginPath()
        ctx.moveTo(pts[0].x, pts[0].y)
        for (var s2 = 0; s2 < pts.length - 1; s2++) {
            var q0 = pts[Math.max(0, s2 - 1)], q1 = pts[s2], q2 = pts[s2 + 1], q3 = pts[Math.min(pts.length - 1, s2 + 2)]
            ctx.bezierCurveTo(
                q1.x + (q2.x - q0.x) / 6, q1.y + (q2.y - q0.y) / 6,
                q2.x - (q3.x - q1.x) / 6, q2.y - (q3.y - q1.y) / 6,
                q2.x, q2.y)
        }
        ctx.strokeStyle = lineColor
        ctx.lineWidth = 2.2
        ctx.lineJoin = "round"
        ctx.lineCap = "round"
        ctx.stroke()

        // ── Latest-sample marker + value badge ──
        var last = values[n - 1]
        var lx = px(n - 1)
        var ly = py(last)

        ctx.beginPath()
        ctx.arc(lx, ly, 7, 0, 2 * Math.PI)
        ctx.fillStyle = withAlpha(lineColor, 0.28)
        ctx.fill()
        ctx.beginPath()
        ctx.arc(lx, ly, 3.6, 0, 2 * Math.PI)
        ctx.fillStyle = lineColor
        ctx.fill()

        if (showBadge) {
            var badge = last.toFixed(1) + unit
            ctx.font = "bold 10px '" + chartRoot.fontFamily + "'"
            var tw = ctx.measureText(badge).width
            var bx = Math.max(padL(), Math.min(lx + 12, w - tw - 10))
            var by = Math.max(padT() + 6, ly - 26)
            ctx.fillStyle = chartRoot.badgeBg
            ctx.beginPath()
            ctx.moveTo(bx, by)
            ctx.lineTo(bx + tw + 10, by)
            ctx.lineTo(bx + tw + 10, by + 14)
            ctx.lineTo(bx + tw + 4, by + 14)
            ctx.lineTo(bx + tw, by + 19)
            ctx.lineTo(bx + tw - 4, by + 14)
            ctx.lineTo(bx, by + 14)
            ctx.closePath()
            ctx.fill()
            ctx.strokeStyle = withAlpha(lineColor, 0.6)
            ctx.lineWidth = 1
            ctx.stroke()
            ctx.fillStyle = textColor
            ctx.textAlign = "left"
            ctx.fillText(badge, bx + 5, by + 11)
        }
    }
}