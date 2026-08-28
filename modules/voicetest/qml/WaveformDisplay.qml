import QtQuick 2.15
import "qrc:/shell/components/themes/Theme.js" as T

// Waveform display — theme-aware, accent/error state colors
Item {
    id: waveform
    property bool recording: false
    property bool playing: false
    property int duration: 0

    readonly property bool dk: appTheme.isDark
    readonly property var pal: dk ? T.recorder.dark : T.recorder.light

    Rectangle {
        anchors.fill: parent
        color: waveform.pal.waveBg
        radius: 12
        border.color: waveform.pal.accentDiscHot
        border.width: 1

        Canvas {
            id: waveCanvas
            anchors.fill: parent
            anchors.margins: 16

            Timer {
                id: waveTimer
                interval: 100
                repeat: true
                running: waveform.recording || waveform.playing
                onTriggered: waveCanvas.updateWaveform()
            }

            property int waveIndex: 0

            function updateWaveform() {
                waveIndex++;
                if (waveIndex > 100) waveIndex = 0;
                requestPaint();
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                if (waveform.recording) {
                    ctx.strokeStyle = waveform.pal.error;
                } else if (waveform.playing) {
                    ctx.strokeStyle = waveform.pal.accent;
                } else {
                    ctx.strokeStyle = waveform.pal.waveIdle;
                }

                ctx.lineWidth = 2;

                for (var i = 0; i < 100; i++) {
                    var x = 10 + (i * (width - 20) / 100);

                    var amplitude;
                    if (waveform.recording || waveform.playing) {
                        amplitude = Math.sin((i + waveIndex) * 0.3) * 30 +
                                   Math.sin((i + waveIndex) * 0.1) * 20;
                    } else {
                        amplitude = 5;
                    }

                    var y = height / 2;
                    ctx.beginPath();
                    ctx.moveTo(x, y);
                    ctx.lineTo(x, y - amplitude);
                    ctx.stroke();
                }
            }
        }

        // ---- Title (QML Text, tránh lỗi Canvas font) ----
        Text {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 10
            anchors.topMargin: 4
            text: waveform.recording ? "Đang ghi âm..."
                 : waveform.playing ? "Đang phát..."
                 : "Waveform"
            font.pixelSize: 12
            font.bold: true
            font.family: T.font
            color: waveform.recording ? waveform.pal.error : waveform.playing ? waveform.pal.accent : waveform.pal.textDim
        }

        // ---- Duration (bottom-right) ----
        Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 10
            anchors.bottomMargin: 2
            visible: waveform.duration > 0 || waveform.recording || waveform.playing
            text: {
                var mins = Math.floor(waveform.duration / 60)
                var secs = waveform.duration % 60
                return mins + ":" + (secs < 10 ? "0" : "") + secs
            }
            font.pixelSize: 12
            font.family: T.font
            color: waveform.pal.duration
        }
    }
}