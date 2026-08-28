import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "qrc:/shell/components/themes/Theme.js" as T

// Recorder (voicetest) — minimal UI: 1 Record + 1 Play, dark shell theme
Item {
    id: root
    anchors.fill: parent

    readonly property bool dk: appTheme.isDark
    readonly property var pal: dk ? T.recorder.dark : T.recorder.light

    Rectangle {
        anchors.fill: parent
        radius: 12
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.pal.cardTop }
            GradientStop { position: 1.0; color: root.pal.cardBottom }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // ---- Header: title + device info ----
        Row {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 12

            Text {
                text: "RECORDER"
                font.pixelSize: 20
                font.bold: true
                font.family: T.font
                font.letterSpacing: 2.0
                color: root.pal.accent
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: "Status: " + deviceManager.status
                font.pixelSize: 12
                font.family: T.font
                color: root.pal.textDim
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "Pin: " + (deviceManager.batteryLevel >= 0 ? deviceManager.batteryLevel + "%" : "N/A")
                font.pixelSize: 12
                font.family: T.font
                color: root.pal.textDim
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: deviceManager.storageInfo
                font.pixelSize: 12
                font.family: T.font
                color: root.pal.textMute
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ---- Two buttons: Record / Play ----
        Row {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 64

            RecordButton {
                id: recordBtn
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    if (audioRecorder.recording) {
                        audioRecorder.stopRecording()
                    } else {
                        audioRecorder.startRecording()
                    }
                }
            }

            PlaybackButton {
                id: playBtn
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    if (voicePlayer.playing) {
                        voicePlayer.stopPlayback()
                    } else {
                        var files = audioRecorder.getRecordings()
                        if (files.length > 0) {
                            voicePlayer.playFile(files[0])
                        } else {
                            statusText.text = "Chưa có bản ghi nào"
                            statusTimer.start()
                        }
                    }
                }
            }
        }

        // ---- Waveform ----
        WaveformDisplay {
            Layout.fillWidth: true
            Layout.preferredHeight: 110
            recording: audioRecorder.recording
            playing: voicePlayer.playing
            duration: audioRecorder.duration
        }

        // ---- Status line ----
        Text {
            id: statusText
            Layout.fillWidth: true
            text: "Sẵn sàng ghi âm"
            font.pixelSize: 13
            font.family: T.font
            color: root.pal.textDim
            horizontalAlignment: Text.AlignHCenter
        }

        Timer {
            id: statusTimer
            interval: 3000
            onTriggered: statusText.text = "Sẵn sàng ghi âm"
        }
    }

    // Handle audio recorder status changes
    Connections {
        target: audioRecorder
        function onRecordingChanged() {
            if (audioRecorder.recording) {
                recordBtn.customText = "Stop"
                recordBtn.customColor = root.pal.error
                statusText.text = "Đang ghi âm..."
            } else {
                recordBtn.customText = "Record"
                recordBtn.customColor = root.pal.accent
                if (!voicePlayer.playing)
                    statusText.text = "Sẵn sàng ghi âm"
            }
        }
    }

    // Handle player status changes
    Connections {
        target: voicePlayer
        function onPlayingChanged() {
            if (voicePlayer.playing) {
                playBtn.customText = "Stop"
                playBtn.customColor = root.pal.error
                statusText.text = "Đang phát..."
            } else {
                playBtn.customText = "Play"
                playBtn.customColor = root.pal.accent
                if (!audioRecorder.recording)
                    statusText.text = "Sẵn sàng ghi âm"
            }
        }
    }
}