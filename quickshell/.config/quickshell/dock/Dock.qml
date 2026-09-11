import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: dock

        required property var modelData
        screen: dock.modelData

        readonly property var tiles: DockService.items
        readonly property int count: dock.tiles.length

        readonly property int icon: DockService.iconSize
        // Slot = icon + gap. Tiles are slot-wide, not icon-wide, so the
        // highlight never drops through a gap and every hit target matches.
        readonly property int slot: dock.icon + Theme.dockIconGap

        readonly property int restRow: dock.count * dock.slot
        readonly property int plateWidth: dock.restRow + Theme.dockPad * 2

        readonly property int padTop: 9
        readonly property int floorToBase: 14
        readonly property int plateHeight: dock.padTop + dock.icon + dock.floorToBase

        readonly property int labelRoom: 40

        anchors {
            bottom: true
            left: true
            right: true
        }

        exclusionMode: DockService.mode === "pinned"
            ? ExclusionMode.Normal
            : ExclusionMode.Ignore
        // Must be 0, not just Ignore: hyprland commits the zone at the first
        // layer-shell surface and only recomputes it when this value changes.
        exclusiveZone: DockService.mode === "pinned"
            ? Theme.dockFloat + dock.plateHeight
            : 0

        color: "transparent"
        visible: dock.count > 0 && DockService.mode !== "hidden"

        implicitHeight: Theme.dockFloat + dock.plateHeight + dock.labelRoom

        // Without this, the full-width window would swallow clicks over its empty space.
        mask: Region {
            Region { item: body }
            Region { item: strip }
        }

        readonly property var active: ToplevelManager.activeToplevel

        readonly property bool desktopBare: !dock.active || !dock.active.activated
        readonly property bool covered: dock.active && dock.active.activated
            && dock.active.fullscreen

        readonly property bool pointerOn: bodyHover.hovered || stripHover.hovered

        property bool held: false

        readonly property bool revealed: {
            // Fullscreen outranks even "always show pinned".
            if (dock.covered) return false;
            if (DockService.mode === "pinned") return true;
            return dock.held || menu.visible
                || (DockService.showOnDesktop && dock.desktopBare);
        }

        // Unequal on purpose: show delay avoids flashing on a passing
        // pointer, longer hide delay tolerates briefly leaving for the menu.
        Timer {
            id: showDelay
            interval: 110
            onTriggered: dock.held = true
        }

        Timer {
            id: hideDelay
            interval: 280
            onTriggered: dock.held = false
        }

        onPointerOnChanged: {
            if (dock.pointerOn) {
                hideDelay.stop();
                showDelay.restart();
            } else {
                showDelay.stop();
                hideDelay.restart();
            }
        }

        property int hoveredIndex: -1

        // Holds the last tile hovered instead of following hoveredIndex back
        // to -1, so leaving fades things out in place rather than sliding home.
        property int restingIndex: 0
        onHoveredIndexChanged: if (dock.hoveredIndex >= 0) dock.restingIndex = dock.hoveredIndex;

        Item {
            id: body

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: dock.plateWidth
            height: Theme.dockFloat + dock.plateHeight

            // Negative margin hangs it off-screen; mask follows, so hidden gives clicks back too.
            anchors.bottomMargin: dock.revealed ? 0 : -(height - Theme.dockStrip)

            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: dock.revealed ? Theme.dockRevealMs : Theme.dockHideMs
                    easing.type: dock.revealed ? Easing.OutCubic : Easing.InCubic
                }
            }

            // HoverHandler, not MouseArea: tiles have their own MouseAreas,
            // which would compete for the hover; a handler sees it regardless.
            HoverHandler {
                id: bodyHover
            }

            Rectangle {
                id: plate

                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.dockFloat
                width: parent.width
                height: dock.plateHeight

                color: Theme.glass
                border.width: 1
                border.color: Theme.border

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 1
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.07)
                }

                Item {
                    id: row

                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: dock.floorToBase
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: dock.restRow
                    height: dock.icon

                    function centreOf(index) {
                        return row.x + (index + 0.5) * dock.slot;
                    }

                    // One box that slides between slots, never rebuilt or resized.
                    Rectangle {
                        id: highlight

                        width: dock.icon + 8
                        height: dock.icon + 8
                        x: dock.restingIndex * dock.slot + (dock.slot - width) / 2
                        y: (parent.height - height) / 2

                        color: Theme.hoverFill
                        opacity: dock.hoveredIndex >= 0 ? 1 : 0

                        Behavior on x {
                            NumberAnimation {
                                duration: Theme.animSlideMs
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: Theme.animMs }
                        }
                    }

                    Repeater {
                        model: dock.tiles

                        DockItem {
                            id: entry

                            required property int index
                            required property var modelData

                            tile: entry.modelData
                            x: entry.index * dock.slot

                            onHoveredChanged: {
                                if (entry.hovered) dock.hoveredIndex = entry.index;
                                else if (dock.hoveredIndex === entry.index) dock.hoveredIndex = -1;
                            }

                            onMenuRequested: {
                                menu.tile = entry.modelData;
                                menu.centreX = row.centreOf(entry.index);
                                menu.visible = true;
                            }
                        }
                    }

                    // Lands in the gap between slots (tiles being slot-wide gives it room).
                    Rectangle {
                        readonly property int at: DockService.pinnedCount

                        visible: at > 0 && dock.count > at
                        x: at * dock.slot - Theme.dockIconGap / 2
                        y: (parent.height - height) / 2
                        width: 1
                        height: 22
                        color: Theme.divider
                    }
                }
            }

            // Outside the mask (drawn above body), so its empty space never eats a click.
            Rectangle {
                id: label

                // Named off restingIndex so it keeps the last tile's name while fading out.
                readonly property var tile: dock.tiles[dock.restingIndex] ?? null

                visible: opacity > 0
                opacity: dock.hoveredIndex >= 0 && label.tile && dock.revealed ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animMs }
                }

                x: Math.round(Math.max(0, Math.min(body.width - width,
                    plate.x + row.centreOf(dock.restingIndex) - width / 2)))
                y: -height - 6

                Behavior on x {
                    NumberAnimation { duration: Theme.animSlideMs; easing.type: Easing.OutCubic }
                }

                implicitWidth: labelText.implicitWidth + 20
                implicitHeight: labelText.implicitHeight + 10

                color: Theme.glass
                border.width: 1
                border.color: Theme.border

                ShellText {
                    id: labelText
                    anchors.centerIn: parent
                    text: label.tile ? label.tile.name : ""
                    color: Theme.fgAct
                }
            }
        }

        // Stays in the mask regardless of reveal state, or a hidden dock couldn't be found.
        Item {
            id: strip

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: dock.plateWidth
            height: Theme.dockStrip

            HoverHandler {
                id: stripHover
            }
        }

        DockMenu {
            id: menu
            anchorItem: plate
            visible: false
            grabFocus: true
        }
    }
}
