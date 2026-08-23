import QtQuick 2.15
import QtGraphicalEffects 1.15

// Lớp kính mờ - chỉ được tải khi có GPU (xem shell.qml: useBlur).
// Nếu module QtGraphicalEffects không có trên thiết bị, Loader sẽ báo
// Error và shell.qml tự tắt blur, chuyển sang nền màu đặc #0c0c12.
Item {
    id: root

    property Item sourceItem: null

    FastBlur {
        anchors.fill: parent
        source: root.sourceItem
        radius: 24
        cached: true
    }
}
