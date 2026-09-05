import QtQuick
import QtQuick.Layouts
import ".."

// One row of a popup menu. Both menus the dock puts on screen are built from
// these, so their hit targets, gutters and hover feedback cannot drift apart.
//
// `mark` is drawn in a gutter that is reserved whether or not the row has one,
// which is what keeps the labels of a mixed menu on a single left edge.
Rectangle {
    id: root

    property alias text: label.text
    // For rows that name something rather than doing something, like the
    // window titles the dock's menu lists.
    property bool dim: false
    // A glyph from Icons, or empty. Reserving the gutter is `gutter`'s job,
    // not this one's: an unchecked switch has no mark but still needs the
    // room, or its label would slide sideways as it was toggled.
    property string mark: ""
    property bool gutter: false

    readonly property bool hovered: mouse.containsMouse

    signal triggered

    Layout.fillWidth: true
    implicitHeight: label.implicitHeight + 12
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
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        color: mouse.containsMouse ? Theme.fgAct : root.dim ? Theme.subtle : Theme.fg
        elide: Text.ElideRight
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
