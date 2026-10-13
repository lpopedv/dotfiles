import QtQuick
import Quickshell
import "../.."
import "../../ui"

BarItem {
    id: root

    property bool showDate: false

    horizontalPadding: 12
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

    ShellText {
        text: root.showDate
            ? Qt.formatDateTime(clock.date, "dddd, dd 'de' MMMM 'de' yyyy")
            : Icons.clock + "  " + Qt.formatDateTime(clock.date, "HH:mm")
        color: root.hovered || panel.visible ? Theme.fgAct : Theme.fg
        font.weight: Font.DemiBold
    }
}
