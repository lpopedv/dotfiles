import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// The dock: pinned apps and running windows on one plate along the bottom
// edge, out of the way until it is wanted.
//
// Icons never change size. The pointer is followed by a single highlight that
// slides along the row from one slot to the next, which is the only thing on
// the dock that moves - so a sweep across it reads as one continuous gesture
// rather than as ten separate icons reacting.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: dock

        required property var modelData
        screen: dock.modelData

        readonly property var tiles: DockService.items
        readonly property int count: dock.tiles.length

        // ------------------------------------------------------------ metrics

        readonly property int icon: DockService.iconSize
        // A slot is the icon plus the gap after it. Tiles are a whole slot
        // wide rather than icon-wide, so sweeping the row never drops through
        // a gap between two of them and leaves the highlight with nowhere to
        // be. It is also what makes every icon's hit target the same size.
        readonly property int slot: dock.icon + Theme.dockIconGap

        readonly property int restRow: dock.count * dock.slot
        readonly property int plateWidth: dock.restRow + Theme.dockPad * 2

        readonly property int padTop: 9
        // Icon floor down to plate floor: the window dots, and padding.
        readonly property int floorToBase: 14
        readonly property int plateHeight: dock.padTop + dock.icon + dock.floorToBase

        // Room above the plate for the label to hang in.
        readonly property int labelRoom: 40

        // ------------------------------------------------------------- window

        anchors {
            bottom: true
            left: true
            right: true
        }

        // A dock that is always up reserves its space, so maximised windows
        // stop above it rather than sliding underneath - that is what asking
        // for it to always show means. A dock that hides itself must not, or
        // it would cost the height on every workspace anyway and there would
        // be no point to the hiding.
        exclusionMode: DockService.mode === "pinned"
            ? ExclusionMode.Normal
            : ExclusionMode.Ignore
        exclusiveZone: Theme.dockFloat + dock.plateHeight

        color: "transparent"
        visible: dock.count > 0 && DockService.mode !== "hidden"

        implicitHeight: Theme.dockFloat + dock.plateHeight + dock.labelRoom

        // The dock only takes input where it actually is. Without this the
        // window's full width along the bottom edge would swallow clicks meant
        // for whatever is behind it, everywhere it draws nothing - including
        // the empty band the label hangs in.
        mask: Region {
            Region { item: body }
            Region { item: strip }
        }

        // ------------------------------------------------------------- reveal

        readonly property var active: ToplevelManager.activeToplevel

        // Nothing focused means an empty workspace, and an empty workspace is
        // exactly when a dock is worth having on screen without being asked
        // for. A fullscreen window is the opposite case.
        readonly property bool desktopBare: !dock.active || !dock.active.activated
        readonly property bool covered: dock.active && dock.active.activated
            && dock.active.fullscreen

        readonly property bool pointerOn: bodyHover.hovered || stripHover.hovered

        property bool held: false

        readonly property bool revealed: {
            // A fullscreen window outranks everything, including a dock that
            // was asked to always show: whatever is playing wants the screen.
            if (dock.covered) return false;
            if (DockService.mode === "pinned") return true;
            return dock.held || menu.visible
                || (DockService.showOnDesktop && dock.desktopBare);
        }

        // Deliberately unequal. The wait before showing is what keeps the dock
        // from flashing every time the pointer crosses the bottom edge on its
        // way somewhere else; the wait before hiding is what lets the pointer
        // leave the dock briefly - on its way to the menu - without losing it.
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

        // Which slot the highlight and the label are parked at. It holds the
        // last tile the pointer was on rather than following `hoveredIndex`
        // back to -1, so leaving the dock fades them out where they stand
        // instead of sliding them home first.
        property int restingIndex: 0
        onHoveredIndexChanged: if (dock.hoveredIndex >= 0) dock.restingIndex = dock.hoveredIndex;

        // --------------------------------------------------------------- dock

        Item {
            id: body

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: dock.plateWidth
            height: Theme.dockFloat + dock.plateHeight

            // A negative margin hangs the whole thing off the bottom of the
            // surface. The mask follows this item, so hiding also gives the
            // desktop its clicks back rather than leaving an invisible dock
            // catching them.
            anchors.bottomMargin: dock.revealed ? 0 : -(height - Theme.dockStrip)

            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: dock.revealed ? Theme.dockRevealMs : Theme.dockHideMs
                    easing.type: dock.revealed ? Easing.OutCubic : Easing.InCubic
                }
            }

            // A handler rather than a MouseArea: the tiles have MouseAreas of
            // their own, and a MouseArea here would have to win or lose the
            // hover against them. A handler sees the pointer either way.
            HoverHandler {
                id: bodyHover
            }

            Rectangle {
                id: plate

                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.dockFloat
                width: parent.width
                height: dock.plateHeight

                // The bar's ground, not the heavier one the popups use: the
                // dock sits over the desktop the whole time it is up, so it
                // has to be the same material as the bar rather than a slab.
                color: Theme.glass
                border.width: 1
                border.color: Theme.border

                // The one piece of gloss on an otherwise flat shell: a hairline
                // along the top inside edge, which is what keeps a large dark
                // rectangle from reading as a hole in the desktop.
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

                    // The whole of the dock's hover feedback: one box that
                    // travels to whichever slot the pointer is in. It is never
                    // rebuilt and never resizes, so moving along the row is a
                    // single slide rather than one fade out and another in.
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

                    // Pinned apps on one side, whatever else is running on the
                    // other. It lands in the gap between two slots, which is
                    // why tiles are a whole slot wide - the divider gets its
                    // room without a slot of its own.
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

            // One label that slides between icons rather than one per tile, so
            // it travels with the highlight instead of blinking from slot to
            // slot. Drawn above the body and therefore outside the mask, so
            // the empty space it floats in never eats a click.
            Rectangle {
                id: label

                // Named off the resting slot, so it keeps naming the tile it
                // was last on while it fades out rather than going blank the
                // moment the pointer leaves.
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

                color: Theme.overlay
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

        // The one part of the dock that never moves: the sliver along the
        // screen edge that brings a hidden dock back. It stays in the mask
        // whether the dock is up or down, which is what makes the reveal
        // reachable at all.
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
