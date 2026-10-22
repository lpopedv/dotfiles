import QtQuick
import QtQuick.Layouts
import qs

// The heading over a group of controls in a panel: small, uppercase and tracked, like the
// calendar's weekday line.
ShellText {
    Layout.fillWidth: true
    Layout.leftMargin: 10
    Layout.topMargin: 6
    Layout.bottomMargin: 4
    color: Theme.subtle
    font.pixelSize: Theme.fontSize - 3
    font.weight: Theme.weightMedium
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 1.2
}
