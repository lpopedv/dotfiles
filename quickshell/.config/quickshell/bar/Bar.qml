import QtQuick
import QtQuick.Layouts
import Quickshell
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
            top: true
            left: true
            right: true
        }

        implicitHeight: Theme.barHeight
        color: "transparent"

        property bool indicatorsRevealed: false

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
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Theme.barOpacity)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            spacing: 0

            Workspaces {}

            Item { Layout.fillWidth: true }

            Tray {}

            Audio {}
            LaunchButton {
                icon: Icons.memory
                command: ["ghostty", "--gtk-single-instance=false",
                          "--class=org.dotfiles.btop", "--title=btop", "-e", "btop"]
                collapsible: true
                revealed: bar.indicatorsRevealed
            }
            LaunchButton {
                icon: Icons.eyedropper
                command: ["hyprpicker", "-a"]
                collapsible: true
                revealed: bar.indicatorsRevealed
            }
            Caffeine {
                collapsible: true
                revealed: bar.indicatorsRevealed
            }
            NightLight {
                collapsible: true
                revealed: bar.indicatorsRevealed
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
