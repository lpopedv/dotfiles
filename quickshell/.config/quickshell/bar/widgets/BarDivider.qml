import QtQuick
import QtQuick.Layouts
import "../.."

// Short and faint: separates groups on the bar without boxing anything in.
Rectangle {
    readonly property bool vertical: BarService.vertical

    Layout.alignment: BarService.crossAlign
    Layout.leftMargin: vertical ? 0 : 8
    Layout.rightMargin: vertical ? 0 : 8
    Layout.topMargin: vertical ? 8 : 0
    Layout.bottomMargin: vertical ? 8 : 0
    implicitWidth: vertical ? 14 : 1
    implicitHeight: vertical ? 1 : 14
    color: Qt.rgba(1, 1, 1, 0.18)
}
