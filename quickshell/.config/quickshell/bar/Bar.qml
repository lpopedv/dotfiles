import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import ".."
import "widgets"
import "../ui"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        required property var modelData
        screen: modelData

        anchors {
            top: BarService.top
            bottom: !BarService.top
            left: true
            right: true
        }

        implicitHeight: Theme.barHeight
        color: "transparent"

        property bool indicatorsRevealed: false
        // The media popup steals the bar's hover, which would collapse the
        // indicators and shift everything the popup is anchored to.
        readonly property bool showIndicators: indicatorsRevealed || media.active

        Timer {
            id: revealHideTimer
            interval: 200
            onTriggered: bar.indicatorsRevealed = false
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    revealHideTimer.stop();
                    bar.indicatorsRevealed = true;
                } else {
                    revealHideTimer.restart();
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.glass
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            spacing: 0

            Logo {}

            BarDivider {}

            Workspaces {}

            Item { Layout.fillWidth: true }

            Tray {}
            // Third-party tray icons on one side, the bar's own indicators on the other.
            BarDivider {
                visible: SystemTray.items.values.length > 0
            }

            Media { id: media }
            Audio {}
            LaunchButton {
                icon: Icons.memory
                command: ["ghostty", "--gtk-single-instance=false",
                          "--class=org.dotfiles.btop", "--title=btop", "-e", "btop"]
                collapsible: true
                revealed: bar.showIndicators
            }
            LaunchButton {
                icon: Icons.eyedropper
                command: ["hyprpicker", "-a"]
                collapsible: true
                revealed: bar.showIndicators
            }
            DockToggle {
                collapsible: true
                revealed: bar.showIndicators
            }
            Caffeine {
                collapsible: true
                revealed: bar.showIndicators
            }
            NightLight {
                collapsible: true
                revealed: bar.showIndicators
            }
            Updates {
                collapsible: true
                revealed: bar.showIndicators
            }
            Network {}

            Battery {}
            NotificationCenter {}
            ClaudeUsage {}
            Clock {}

            BarItem {
                onClicked: SessionState.toggle()
                active: SessionState.open

                ShellText {
                    text: Icons.power
                    color: parent.hovered || SessionState.open ? Theme.fgAct : Theme.fg
                    font.pixelSize: Theme.iconSize
                }
            }
        }
    }
}
