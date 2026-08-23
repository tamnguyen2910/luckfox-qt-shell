import QtQuick 2.15
import "themes/Theme.js" as T

Item {
    id: root
    property string iconType: "photo"  // "photo" or "mic"
    property bool active: false

    readonly property bool dk: appTheme.isDark
    readonly property color activeColor: dk ? T.dark.accent : T.light.accent
    readonly property color idleColor: dk ? T.dark.textSecondary : T.light.textTertiary

    // Photo icon (mountain + sun)
    Canvas {
        id: photoCanvas
        anchors.fill: parent
        visible: iconType === "photo"
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.save();
            var color = root.active ? root.activeColor.toString() : root.idleColor.toString();
            ctx.strokeStyle = color;
            ctx.lineWidth = 3;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            var cx = width / 2;
            var cy = height / 2;
            var scale = Math.min(width, height) / 60;

            // Mountain
            ctx.beginPath();
            ctx.moveTo(cx - 20*scale, cy + 10*scale);
            ctx.lineTo(cx - 8*scale, cy - 10*scale);
            ctx.lineTo(cx + 2*scale, cy + 2*scale);
            ctx.lineTo(cx + 10*scale, cy - 14*scale);
            ctx.lineTo(cx + 20*scale, cy + 10*scale);
            ctx.stroke();

            // Sun
            ctx.beginPath();
            ctx.arc(cx + 18*scale, cy - 18*scale, 6*scale, 0, 2*Math.PI);
            ctx.stroke();

            // Sun rays
            for (var i = 0; i < 8; i++) {
                var angle = i * Math.PI / 4;
                ctx.beginPath();
                ctx.moveTo(cx + 18*scale + Math.cos(angle) * 8*scale, cy - 18*scale + Math.sin(angle) * 8*scale);
                ctx.lineTo(cx + 18*scale + Math.cos(angle) * 12*scale, cy - 18*scale + Math.sin(angle) * 12*scale);
                ctx.stroke();
            }

            ctx.restore();
        }
    }

    // Mic icon
    Canvas {
        id: micCanvas
        anchors.fill: parent
        visible: iconType === "mic"
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.save();
            var color = root.active ? root.activeColor.toString() : root.idleColor.toString();
            ctx.strokeStyle = color;
            ctx.lineWidth = 3;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            var cx = width / 2;
            var cy = height / 2;
            var scale = Math.min(width, height) / 60;

            // Mic body
            ctx.beginPath();
            ctx.moveTo(cx - 10*scale, cy - 12*scale);
            ctx.lineTo(cx - 10*scale, cy + 2*scale);
            ctx.arcTo(cx - 10*scale, cy + 8*scale, cx - 4*scale, cy + 8*scale, 6*scale);
            ctx.lineTo(cx + 4*scale, cy + 8*scale);
            ctx.arcTo(cx + 10*scale, cy + 8*scale, cx + 10*scale, cy + 2*scale, 6*scale);
            ctx.lineTo(cx + 10*scale, cy - 12*scale);
            ctx.stroke();

            // Mic stand
            ctx.beginPath();
            ctx.moveTo(cx - 14*scale, cy + 8*scale);
            ctx.lineTo(cx + 14*scale, cy + 8*scale);
            ctx.stroke();

            ctx.beginPath();
            ctx.moveTo(cx, cy + 8*scale);
            ctx.lineTo(cx, cy + 16*scale);
            ctx.stroke();

            ctx.restore();
        }
    }
}