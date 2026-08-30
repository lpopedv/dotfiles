import QtQuick
import QtQuick.Layouts
import "../.."

Rectangle {
    id: root

    property alias hovered: mouse.containsMouse
    property bool active: false
    property int horizontalPadding: 11
    default property alias content: layout.data

    signal clicked(int button)
    signal wheel(int delta)

    Layout.alignment: Qt.AlignVCenter
    Layout.topMargin: 5
    Layout.bottomMargin: 5
    Layout.leftMargin: 2
    Layout.rightMargin: 2

    implicitWidth: layout.implicitWidth + horizontalPadding * 2
    implicitHeight: Theme.barHeight - 10

    color: root.active ? Theme.activeFill : mouse.containsMouse ? Theme.hoverFill : "transparent"
    border.width: 1
    border.color: root.active ? Theme.accentLine : "transparent"

    Behavior on color {
        ColorAnimation { duration: Theme.animMs }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 6
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => root.clicked(event.button)
        onWheel: event => root.wheel(event.angleDelta.y)
    }
}
