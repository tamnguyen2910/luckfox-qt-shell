import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: volumeSlider
    
    Rectangle {
        anchors.fill: parent
        color: "#34495e"
        radius: 10
        border.color: "#2c3e50"
        border.width: 2
        
        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 10
            text: "Volume Control"
            color: "#ecf0f1"
            font.pixelSize: 14
        }
        
        // Volume level indicator
        Rectangle {
            id: volumeTrack
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            height: 30
            color: "#2c3e50"
            radius: 15
            border.color: "#2c3e50"
            border.width: 2
            
            property real volume: 0.8
            
            // Filled portion
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * parent.parent.volume
                color: volumeSlider.volume > 0.7 ? "#2ecc71" : "#e74c3c"
                radius: 15
            }
            
            // Volume level text
            Text {
                anchors.centerIn: parent
                text: Math.round(volumeTrack.parent.volume * 100) + "%"
                color: "#ecf0f1"
                font.pixelSize: 12
                font.bold: true
            }
        }
        
        // Volume buttons
        Row {
            anchors.bottom: volumeTrack.top
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20
            
            Button {
                text: "-"
                width: 40
                height: 30
                onClicked: {
                    var vol = volumeTrack.volume;
                    vol = Math.max(0, vol - 0.1);
                    volumeTrack.volume = Math.round(vol * 10) / 10;
                }
            }
            
            Button {
                text: "+"
                width: 40
                height: 30
                onClicked: {
                    var vol = volumeTrack.volume;
                    vol = Math.min(1.0, vol + 0.1);
                    volumeTrack.volume = Math.round(vol * 10) / 10;
                }
            }
        }
    }
}