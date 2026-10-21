import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../ui"

BarItem {
    id: root

    property bool showDate: false

    padding: BarService.vertical ? 8 : 12
    active: panel.visible

    onClicked: button => {
        if (button === Qt.RightButton) root.showDate = !root.showDate;
        else panel.visible = !panel.visible;
    }

    SystemClock {
        // Minutes, not Seconds - display can't change that often; don't wake the binding chain for nothing.
        id: clock
        precision: SystemClock.Minutes
    }

    CalendarPanel {
        id: panel
        anchorItem: root
        today: clock.date
        visible: false
        grabFocus: true
    }

    readonly property color tone: root.hovered || panel.visible ? Theme.fgAct : Theme.fg

    // Top/bottom bars: one line.
    ShellText {
        visible: !root.vertical
        text: root.showDate
            ? Qt.formatDateTime(clock.date, "dddd, dd 'de' MMMM 'de' yyyy")
            : Icons.clock + "  " + Qt.formatDateTime(clock.date, "dd MMM  HH:mm")
        color: root.tone
        font.weight: Font.DemiBold
    }

    // Side bars: a line of text won't fit, so the time becomes a small lockup, the
    // hour (or day) as the headline and the minutes (or month) as its quieter caption,
    // each set in its own ring.
    readonly property int ringSize: 26
    readonly property color ringColor: root.hovered || panel.visible ? Theme.accentLine : Theme.border

    Rectangle {
        visible: root.vertical
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: root.ringSize
        implicitHeight: root.ringSize
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: root.ringColor

        ShellText {
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, root.showDate ? "dd" : "HH")
            color: root.hovered || panel.visible ? Theme.fgAct : Qt.lighter(Theme.fg, 1.35)
            font.pixelSize: Theme.fontSize + 1
            font.weight: Font.DemiBold
        }
    }

    Rectangle {
        visible: root.vertical
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: root.ringSize
        implicitHeight: root.ringSize
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: root.ringColor

        ShellText {
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, root.showDate ? "MMM" : "mm").replace(".", "")
            color: root.hovered || panel.visible ? Theme.fg : Theme.subtle
            font.pixelSize: Theme.fontSize - 1
        }
    }
}
