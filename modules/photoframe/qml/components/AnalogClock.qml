import QtQuick 2.12

// Elegant analog wall-clock: radial-gradient face, minute ticks, poised
// hands with counterweights, smooth-sweep second hand (sub-second angles).
Item {
    id: root

    width: 140
    height: 140

    property color handColor: "white"
    property color secondColor: "#ef4444"

    Timer {
        interval: 120
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: canvas.requestPaint()
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            var c = width / 2
            var r = width / 2 - 4
            var i, a
            ctx.clearRect(0, 0, width, height)

            // Radial-gradient face
            var g = ctx.createRadialGradient(c, c - 6, r * 0.15, c, c, r)
            g.addColorStop(0, "#26334a")
            g.addColorStop(0.55, "#182233")
            g.addColorStop(1, "#0e141f")
            ctx.beginPath()
            ctx.arc(c, c, r, 0, Math.PI * 2)
            ctx.fillStyle = g
            ctx.fill()

            // Rim rings
            ctx.lineWidth = 2
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.10)
            ctx.beginPath()
            ctx.arc(c, c, r - 1, 0, Math.PI * 2)
            ctx.stroke()
            ctx.lineWidth = 3
            ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.45)
            ctx.beginPath()
            ctx.arc(c, c, r - 3, 0, Math.PI * 2)
            ctx.stroke()

            // Minute ticks (60) + hour ticks (12, tapered)
            for (i = 0; i < 60; i++) {
                a = i * Math.PI / 30
                var major = i % 5 === 0
                if (major) {
                    // Tapered hour marker
                    var outer = r - 7
                    var inner = r - 16
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.85)
                    ctx.lineWidth = 2.4
                    ctx.lineCap = "round"
                    ctx.beginPath()
                    ctx.moveTo(c + Math.cos(a) * inner, c + Math.sin(a) * inner)
                    ctx.lineTo(c + Math.cos(a) * outer, c + Math.sin(a) * outer)
                    ctx.stroke()
                } else {
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.25)
                    ctx.lineWidth = 1
                    ctx.lineCap = "round"
                    ctx.beginPath()
                    ctx.moveTo(c + Math.cos(a) * (r - 10), c + Math.sin(a) * (r - 10))
                    ctx.lineTo(c + Math.cos(a) * (r - 14), c + Math.sin(a) * (r - 14))
                    ctx.stroke()
                }
            }

            // Continuous time (sub-second) for a smooth sweep
            var now = new Date().getTime()
            var secs = (now / 1000) % 60
            var mins = (now / 60000) % 60
            var hours = (now / 3600000) % 12

            var sh = (hours + mins / 60) / 12 * 2 * Math.PI
            var sm = (mins + secs / 60) / 60 * 2 * Math.PI
            var ss = secs / 60 * 2 * Math.PI

            // Hour hand
            root.drawHand(ctx, c, c, sh, r * 0.48, r * 0.14, 6, root.handColor)
            // Minute hand
            root.drawHand(ctx, c, c, sm, r * 0.70, r * 0.18, 4, root.handColor)
            // Second hand (red, longer)
            root.drawHand(ctx, c, c, ss, r * 0.82, r * 0.22, 1.5, root.secondColor)

            // Center cap: outer white ring, red core
            ctx.beginPath()
            ctx.arc(c, c, 5, 0, Math.PI * 2)
            ctx.fillStyle = "#0e141f"
            ctx.fill()
            ctx.beginPath()
            ctx.arc(c, c, 3.4, 0, Math.PI * 2)
            ctx.fillStyle = root.secondColor
            ctx.fill()
        }
    }

    // Balanced hand with a counterweight tail; dark under-drawing adds depth.
    function drawHand(ctx, cx, cy, angle, len, tail, width, color) {
        var a = angle - Math.PI / 2
        var hx = Math.cos(a)
        var hy = Math.sin(a)
        ctx.lineCap = "round"

        // Depth pass (offset shadow)
        ctx.strokeStyle = "rgba(0,0,0,0.40)"
        ctx.lineWidth = width + 1.5
        ctx.beginPath()
        ctx.moveTo(cx + hx * tail * -1 + 1, cy + hy * tail * -1 + 1)
        ctx.lineTo(cx + hx * len + 1, cy + hy * len + 1)
        ctx.stroke()

        // Main hand
        ctx.strokeStyle = color
        ctx.lineWidth = width
        ctx.beginPath()
        ctx.moveTo(cx + hx * tail * -1, cy + hy * tail * -1)
        ctx.lineTo(cx + hx * len, cy + hy * len)
        ctx.stroke()
    }
}