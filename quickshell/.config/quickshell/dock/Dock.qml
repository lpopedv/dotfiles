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

        readonly property string side: DockService.position
        readonly property bool vertical: DockService.vertical

        // Depth from the screen edge to the plate's inner face; along is the plate's long axis.
        readonly property int cross: Theme.dockFloat + dock.plateHeight

        // Beside a vertical dock the label grows sideways, so it needs a full name's width.
        readonly property int labelRoom: dock.vertical ? 260 : 40

        anchors {
            top: dock.vertical
            bottom: true
            left: dock.side !== "right"
            right: dock.side !== "left"
        }

        // Always Normal so the dock sits above the bottom bar instead of over it.
        exclusionMode: ExclusionMode.Normal
        // Must be 0, not just Ignore: hyprland commits the zone at the first
        // layer-shell surface and only recomputes it when this value changes.
        exclusiveZone: DockService.mode === "pinned" ? dock.cross : 0

        color: "transparent"
        visible: dock.count > 0 && DockService.mode !== "hidden"

        // Only the axis not stretched by the anchors takes effect.
        implicitHeight: dock.cross + dock.labelRoom
        implicitWidth: dock.cross + dock.labelRoom

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

            width: dock.vertical ? dock.cross : dock.plateWidth
            height: dock.vertical ? dock.plateWidth : dock.cross

            // Hangs it off-screen past the edge; mask follows, so hidden gives clicks back too.
            property real sunk: dock.revealed ? 0 : dock.cross - Theme.dockStrip

            x: dock.side === "left" ? -body.sunk
                : dock.side === "right" ? parent.width - width + body.sunk
                : (parent.width - width) / 2
            y: dock.vertical ? (parent.height - height) / 2
                : parent.height - height + body.sunk

            Behavior on sunk {
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

                // The float gap sits on the screen-edge side.
                x: dock.side === "left" ? Theme.dockFloat : 0
                width: dock.vertical ? dock.plateHeight : parent.width
                height: dock.vertical ? parent.height : dock.plateHeight

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

                    // floorToBase (room for the window dots) faces the screen edge.
                    width: dock.vertical ? dock.icon : dock.restRow
                    height: dock.vertical ? dock.restRow : dock.icon
                    x: dock.side === "left" ? dock.floorToBase
                        : dock.side === "right" ? dock.padTop
                        : (parent.width - width) / 2
                    y: dock.vertical ? (parent.height - height) / 2 : dock.padTop

                    // Along the dock's long axis, in plate coordinates.
                    function centreOf(index) {
                        return (dock.vertical ? row.y : row.x) + (index + 0.5) * dock.slot;
                    }

                    // One box that slides between slots, never rebuilt or resized.
                    Rectangle {
                        id: highlight

                        width: dock.icon + 8
                        height: dock.icon + 8
                        readonly property real along: dock.restingIndex * dock.slot + (dock.slot - width) / 2
                        x: dock.vertical ? (parent.width - width) / 2 : along
                        y: dock.vertical ? along : (parent.height - height) / 2

                        color: Theme.hoverFill
                        opacity: dock.hoveredIndex >= 0 ? 1 : 0

                        Behavior on x {
                            NumberAnimation {
                                duration: Theme.animSlideMs
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on y {
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
                            x: dock.vertical ? 0 : entry.index * dock.slot
                            y: dock.vertical ? entry.index * dock.slot : 0

                            onHoveredChanged: {
                                if (entry.hovered) dock.hoveredIndex = entry.index;
                                else if (dock.hoveredIndex === entry.index) dock.hoveredIndex = -1;
                            }

                            onMenuRequested: {
                                menu.tile = entry.modelData;
                                menu.centre = row.centreOf(entry.index);
                                menu.visible = true;
                            }
                        }
                    }

                    // Lands in the gap between slots (tiles being slot-wide gives it room).
                    Rectangle {
                        readonly property int at: DockService.pinnedCount

                        visible: at > 0 && dock.count > at
                        readonly property real along: at * dock.slot - Theme.dockIconGap / 2
                        x: dock.vertical ? (parent.width - width) / 2 : along
                        y: dock.vertical ? along : (parent.height - height) / 2
                        width: dock.vertical ? 22 : 1
                        height: dock.vertical ? 1 : 22
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

                // Sits on the plate's inner side, centred on the tile along the dock.
                readonly property real along: dock.vertical
                    ? Math.round(Math.max(0, Math.min(body.height - height,
                        plate.y + row.centreOf(dock.restingIndex) - height / 2)))
                    : Math.round(Math.max(0, Math.min(body.width - width,
                        plate.x + row.centreOf(dock.restingIndex) - width / 2)))

                x: dock.side === "left" ? body.width + 6
                    : dock.side === "right" ? -width - 6
                    : label.along
                y: dock.vertical ? label.along : -height - 6

                Behavior on x {
                    enabled: !dock.vertical
                    NumberAnimation { duration: Theme.animSlideMs; easing.type: Easing.OutCubic }
                }
                Behavior on y {
                    enabled: dock.vertical
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

            width: dock.vertical ? Theme.dockStrip : dock.plateWidth
            height: dock.vertical ? dock.plateWidth : Theme.dockStrip
            x: dock.side === "left" ? 0
                : dock.side === "right" ? parent.width - width
                : (parent.width - width) / 2
            y: dock.vertical ? (parent.height - height) / 2 : parent.height - height

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
