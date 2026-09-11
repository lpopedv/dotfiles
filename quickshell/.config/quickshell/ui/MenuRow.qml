import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property alias text: label.text
    property bool dim: false
    // Gutter reservation is `gutter`'s job, not this one's, so an unchecked
    // row's label doesn't slide sideways when toggled.
    property string mark: ""
    property bool gutter: false
    property string trailing: ""

    readonly property bool hovered: mouse.containsMouse

    signal triggered

    Layout.fillWidth: true
    implicitHeight: label.implicitHeight + 12
    opacity: root.enabled ? 1 : Theme.dimmedOpacity
    color: mouse.containsMouse ? Theme.hoverFill : "transparent"

    Behavior on color {
        ColorAnimation { duration: Theme.animMs }
    }

    ShellText {
        id: markLabel

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 10
        visible: root.gutter
        width: 16
        text: root.mark
        color: root.mark === Icons.radioOff ? Theme.subtle : Theme.fgAct
        font.pixelSize: Theme.fontSize - 1
    }

    ShellText {
        id: label

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: root.gutter ? markLabel.right : parent.left
        anchors.right: root.trailing ? trailingLabel.left : parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        color: mouse.containsMouse ? Theme.fgAct : root.dim ? Theme.subtle : Theme.fg
        elide: Text.ElideRight
    }

    ShellText {
        id: trailingLabel

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 8
        visible: root.trailing !== ""
        text: root.trailing
        color: mouse.containsMouse ? Theme.fgAct : Theme.subtle
        font.pixelSize: Theme.fontSize - 1
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
