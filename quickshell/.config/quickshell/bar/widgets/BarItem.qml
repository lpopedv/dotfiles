import QtQuick
import QtQuick.Layouts
import "../.."

Rectangle {
    id: root

    property alias hovered: mouse.containsMouse
    property bool active: false
    property int horizontalPadding: 11
    default property alias content: layout.data

    property bool collapsible: false
    property bool revealed: true
    readonly property bool collapsed: collapsible && !active && !revealed

    signal clicked(int button)
    signal wheel(int delta)

    Layout.alignment: Qt.AlignVCenter
    Layout.topMargin: Theme.barItemInset
    Layout.bottomMargin: Theme.barItemInset
    Layout.leftMargin: collapsed ? 0 : 2
    Layout.rightMargin: collapsed ? 0 : 2

    clip: true
    implicitWidth: collapsed ? 0 : layout.implicitWidth + horizontalPadding * 2
    implicitHeight: Theme.barHeight - Theme.barItemInset * 2
    opacity: collapsed ? 0 : (collapsible && !active ? Theme.dimmedOpacity : 1)

    color: mouse.containsMouse ? Theme.hoverFill : "transparent"
    border.width: 1
    border.color: "transparent"

    Behavior on color {
        ColorAnimation { duration: Theme.animMs }
    }
    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.animSlideMs; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: Theme.animMs }
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
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => root.clicked(event.button)
        onWheel: event => root.wheel(event.angleDelta.y)
    }
}
