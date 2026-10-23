pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs
import qs.bar.widgets
import qs.services
import qs.ui

Variants {
    model: Quickshell.screens

    Scope {
        id: scope

        required property var modelData

        // Rebuilt from scratch on a change of side instead of re-laid out: a GridLayout
        // whose flow/rows/columns change after creation keeps stale cells (collapsed
        // items left gaps on a side bar), and the layer surface gets fresh anchors too.
        LazyLoader {
            active: BarService.built

            PanelWindow {
                id: bar

                screen: scope.modelData

                // Stretches along the edge it sits on; the sides it isn't anchored to are free.
                anchors {
                    top: !BarService.bottom
                    bottom: !BarService.top
                    left: !BarService.right
                    right: !BarService.left
                }

                // Only the axis the anchors don't stretch takes effect.
                implicitWidth: BarService.thickness
                implicitHeight: BarService.thickness
                color: "transparent"

                property bool indicatorsRevealed: false
                // The media popup steals the bar's hover, which would collapse the
                // indicators and shift everything the popup is anchored to.
                readonly property bool showIndicators: ((indicatorsRevealed || BarService.pinned) && bar.roomToReveal)
                    || media.active

                // A side bar runs out of length long before a top/bottom one runs out of width,
                // so only reveal the collapsed indicators if everything fits at full size. Sums each
                // item's full extent, never its current one, or revealing would feed back into this.
                readonly property bool roomToReveal: {
                    if (!BarService.vertical) return true;
                    let needed = 0;
                    for (const child of items.children) {
                        if (!child.visible) continue;
                        needed += (child.fullExtent !== undefined ? child.fullExtent : child.implicitHeight) + 4;
                    }
                    return needed <= bar.height;
                }

                Timer {
                    id: revealHideTimer
                    // Just long enough that skimming the pointer across the bar doesn't flicker it.
                    interval: 260
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

                // Everything the bar draws sits in here so a change of position can fade and
                // slide it as one piece while the window itself re-anchors unseen.
                Item {
                    id: content

                    anchors.fill: parent
                    opacity: 1 - BarService.leaving

                    // Drifts toward the screen edge the bar sits on as it leaves, and comes in from
                    // the new edge after the switch (the sign flips while it is invisible).
                    transform: Translate {
                        readonly property real travel: 14 * BarService.leaving
                        x: BarService.left ? -travel : BarService.right ? travel : 0
                        y: BarService.top ? -travel : BarService.bottom ? travel : 0
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Theme.glass
                    }

                    GridLayout {
                        id: items

                        anchors.fill: parent
                        anchors.leftMargin: BarService.vertical ? 0 : 2
                        anchors.rightMargin: BarService.vertical ? 0 : 2
                        anchors.topMargin: BarService.vertical ? 2 : 0
                        anchors.bottomMargin: BarService.vertical ? 2 : 0
                        columnSpacing: 0
                        rowSpacing: 0
                        flow: BarService.vertical ? GridLayout.LeftToRight : GridLayout.TopToBottom
                        columns: BarService.vertical ? 1 : -1
                        rows: BarService.vertical ? -1 : 1

                        Logo {}

                        BarDivider {}

                        Workspaces { revealed: bar.showIndicators }

                        Item {
                            Layout.fillWidth: !BarService.vertical
                            Layout.fillHeight: BarService.vertical
                        }

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
                            order: 1
                        }
                        LaunchButton {
                            icon: Icons.eyedropper
                            command: ["hyprpicker", "-a"]
                            collapsible: true
                            revealed: bar.showIndicators
                            order: 2
                        }
                        DockToggle {
                            collapsible: true
                            revealed: bar.showIndicators
                            order: 3
                        }
                        Caffeine {
                            collapsible: true
                            revealed: bar.showIndicators
                            order: 4
                        }
                        NightLight {
                            collapsible: true
                            revealed: bar.showIndicators
                            order: 5
                        }
                        Updates {
                            collapsible: true
                            revealed: bar.showIndicators
                            order: 6
                        }
                        Network {}

                        Battery {}
                        NotificationCenter {}
                        ClaudeUsage {}
                        Clock {}

                        BarItem {
                            onClicked: SessionService.toggle()
                            active: SessionService.open

                            ShellText {
                                text: Icons.power
                                color: parent.hovered || SessionService.open ? Theme.fgAct : Theme.fg
                                font.pixelSize: Theme.iconSize
                            }
                        }
                    }
                }
            }
        }
    }
}
