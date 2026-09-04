import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../.."
import "../../ui"

BarItem {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool present: battery && battery.isLaptopBattery && battery.isPresent
    // `visible` does not stop a binding from evaluating, so every read of the
    // device has to survive there being no battery at all - which is the
    // normal case on a desktop.
    readonly property real level: present ? battery.percentage : 1
    readonly property int percent: Math.round(level * 100)
    readonly property bool charging: present && battery.state === UPowerDeviceState.Charging
    readonly property bool full: present && battery.state === UPowerDeviceState.FullyCharged

    readonly property real drained: charging || full ? 0 : 1 - level
    readonly property bool alerting: present && Theme.isAlert(drained)

    visible: present
    Layout.leftMargin: 12

    ShellText {
        text: (root.charging ? Icons.charging : Icons.batteryIcon(root.level))
            + " " + root.percent + "%"
        color: Theme.alertColor(root.drained,
            root.hovered || root.charging ? Theme.fgAct : Theme.fg)
        font.weight: root.charging || root.alerting ? Font.DemiBold : Font.Normal

        SequentialAnimation on opacity {
            running: root.drained >= Theme.dangerAt
            loops: Animation.Infinite
            alwaysRunToEnd: true

            NumberAnimation { to: 0.45; duration: 900; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
        }
    }
}
