import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../ui"

PopupWindow {
    id: root

    property var player: null
    property var anchorItem: null

    readonly property bool hasPlayer: player !== null
    readonly property bool seekable:
        hasPlayer && player.positionSupported && player.length > 0
    // Right after a skip some players (Firefox) keep reporting the old
    // track's position until paused/resumed, so it can exceed the new length.
    readonly property bool stale: seekable && player.position > player.length + 1
    readonly property real fraction:
        seekable && !stale ? Math.max(0, Math.min(1, player.position / player.length)) : 0

    anchor.item: anchorItem
    anchor.edges: BarService.popupEdge
    anchor.gravity: BarService.popupEdge
    anchor.adjustment: PopupAdjustment.SlideX

    implicitWidth: 340
    implicitHeight: layout.implicitHeight + 28 + Theme.popupInset
    color: "transparent"

    onVisibleChanged: if (!root.visible) panel.opacity = 0

    // MPRIS position doesn't tick on its own; poke it while it matters.
    Timer {
        interval: 1000
        running: root.visible && root.hasPlayer && root.player.isPlaying
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    Connections {
        target: root.player
        ignoreUnknownSignals: true
        function onTrackChanged() { settle.restart(); }
    }

    // Let the new track's metadata land, then fix a stale position.
    Timer {
        id: settle
        interval: 400
        onTriggered: {
            if (!root.hasPlayer) return;
            if (root.stale && root.player.canSeek) root.player.position = 0;
            root.player.positionChanged();
        }
    }

    function fmt(secs) {
        const s = Math.max(0, Math.floor(secs));
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const r = String(s % 60).padStart(2, "0");
        return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + r : m + ":" + r;
    }

    Rectangle {
        id: panel

        anchors.fill: parent
        anchors.topMargin: BarService.top ? Theme.popupInset : 0
        anchors.bottomMargin: BarService.top ? 0 : Theme.popupInset
        color: Theme.glass
        border.width: 1
        border.color: Theme.border

        opacity: 0

        NumberAnimation on opacity {
            to: 1
            duration: Theme.animMs
            easing.type: Easing.OutCubic
            running: root.visible
        }

        focus: true
        Keys.onEscapePressed: root.visible = false
        Keys.onSpacePressed: if (root.hasPlayer) root.player.togglePlaying()

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    visible: art.status === Image.Ready
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.border

                    Image {
                        id: art
                        anchors.fill: parent
                        anchors.margins: 1
                        source: root.hasPlayer ? root.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 144
                        sourceSize.height: 144
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    ShellText {
                        Layout.fillWidth: true
                        text: root.hasPlayer ? (root.player.trackTitle || "Unknown") : ""
                        color: Theme.fgAct
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    ShellText {
                        Layout.fillWidth: true
                        text: root.hasPlayer ? root.player.trackArtist : ""
                        visible: text.length > 0
                        elide: Text.ElideRight
                    }

                    ShellText {
                        Layout.fillWidth: true
                        text: root.hasPlayer ? root.player.identity : ""
                        color: Theme.border
                        font.pixelSize: Theme.fontSize - 2
                        elide: Text.ElideRight
                    }
                }
            }

            Spectrum {
                Layout.fillWidth: true
                implicitHeight: 40
                visible: root.hasPlayer && root.player.isPlaying
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: root.seekable

                // Taller hit area than the 6px meter so seeking isn't fiddly.
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 14

                    Meter {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        fraction: root.fraction
                        fill: Theme.fgAct
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.hasPlayer && root.player.canSeek
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: event => {
                            root.player.position =
                                Math.max(0, Math.min(1, event.x / width)) * root.player.length;
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    ShellText {
                        text: root.hasPlayer ? root.fmt(root.stale ? 0 : root.player.position) : ""
                        color: Theme.border
                        font.pixelSize: Theme.fontSize - 2
                    }
                    Item { Layout.fillWidth: true }
                    ShellText {
                        text: root.hasPlayer ? root.fmt(root.player.length) : ""
                        color: Theme.border
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                Repeater {
                    model: [
                        { icon: "prev", enabled: "canGoPrevious" },
                        { icon: "toggle", enabled: "canTogglePlaying" },
                        { icon: "next", enabled: "canGoNext" }
                    ]

                    Rectangle {
                        id: btn
                        required property var modelData
                        readonly property bool usable:
                            root.hasPlayer && root.player[modelData.enabled]

                        implicitWidth: 40
                        implicitHeight: 32
                        color: btnMouse.containsMouse && usable ? Theme.hoverFill : "transparent"
                        opacity: usable ? 1 : Theme.dimmedOpacity

                        Behavior on color {
                            ColorAnimation { duration: Theme.animMs }
                        }

                        ShellText {
                            anchors.centerIn: parent
                            font.pixelSize: Theme.iconSize + 3
                            color: btnMouse.containsMouse ? Theme.fgAct : Theme.fg
                            text: btn.modelData.icon === "prev" ? Icons.skipPrevious
                                : btn.modelData.icon === "next" ? Icons.skipNext
                                : (root.hasPlayer && root.player.isPlaying
                                    ? Icons.pause : Icons.play)
                        }

                        MouseArea {
                            id: btnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: btn.usable
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (btn.modelData.icon === "prev") root.player.previous();
                                else if (btn.modelData.icon === "next") root.player.next();
                                else root.player.togglePlaying();
                            }
                        }
                    }
                }
            }
        }
    }
}
