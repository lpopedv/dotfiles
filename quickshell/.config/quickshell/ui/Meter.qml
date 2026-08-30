import QtQuick
import ".."

Item {
    id: root

    property real fraction: 0
    property color fill: Theme.fg

    implicitHeight: 6

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, 0.07)
    }

    Rectangle {
        width: parent.width * Math.max(0, Math.min(1, root.fraction))
        height: parent.height
        color: root.fill

        Behavior on width {
            NumberAnimation { duration: Theme.animMs }
        }
    }
}
