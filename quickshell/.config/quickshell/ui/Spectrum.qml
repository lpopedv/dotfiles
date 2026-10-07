import QtQuick
import ".."

// Mirrored bars driven by CavaService; grows from the centre line.
Item {
    id: root

    property color fill: Theme.fgAct
    property int count: CavaService.barCount
    property real spacing: 2

    Row {
        anchors.fill: parent
        spacing: root.spacing

        Repeater {
            model: root.count

            Item {
                required property int index
                readonly property real level:
                    CavaService.bars[Math.floor(index * CavaService.barCount / root.count)] || 0

                width: (root.width - root.spacing * (root.count - 1)) / root.count
                height: root.height

                Rectangle {
                    width: parent.width
                    height: Math.max(2, parent.level * parent.height)
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.fill
                    opacity: 0.35 + 0.65 * parent.level

                    Behavior on height {
                        NumberAnimation { duration: 60 }
                    }
                }
            }
        }
    }
}
