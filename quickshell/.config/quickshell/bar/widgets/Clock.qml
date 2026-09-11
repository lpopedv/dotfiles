import QtQuick
import Quickshell
import "../.."
import "../../ui"

BarItem {
    id: root

    property bool showDate: false

    horizontalPadding: 12
    onClicked: root.showDate = !root.showDate

    SystemClock {
        // Minutes, not Seconds - display can't change that often; don't wake the binding chain for nothing.
        id: clock
        precision: SystemClock.Minutes
    }

    ShellText {
        text: root.showDate
            ? Qt.formatDateTime(clock.date, "dddd, dd 'de' MMMM 'de' yyyy")
            : Icons.clock + "  " + Qt.formatDateTime(clock.date, "HH:mm")
        color: root.hovered ? Theme.fgAct : Theme.fg
        font.weight: Font.DemiBold
    }
}
