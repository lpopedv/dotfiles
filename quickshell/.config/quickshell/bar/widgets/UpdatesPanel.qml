import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../ui"

PopupWindow {
    id: root

    property var anchorItem: null

    readonly property int maxListHeight: 320

    anchor.item: root.anchorItem
    anchor.edges: BarService.popupEdge
    anchor.gravity: BarService.popupEdge
    anchor.adjustment: PopupAdjustment.SlideX

    implicitWidth: 320
    // Gap off the bar is transparent space inside the popup: the compositor
    // clamps an anchored popup to the bar's edge, so anchor.margins can't do it.
    implicitHeight: layout.implicitHeight + 20 + Theme.popupInset
    color: "transparent"

    // Resets the fade-in for next open; can close via focus grab too, not just the button.
    onVisibleChanged: if (!root.visible) panel.opacity = 0

    component Divider: Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 5
        Layout.bottomMargin: 5
        implicitHeight: 1
        color: Theme.divider
    }

    component PackageSection: ColumnLayout {
        id: section

        property string title
        property var packages: []

        Layout.fillWidth: true
        visible: section.packages.length > 0
        spacing: 0

        ShellText {
            Layout.leftMargin: 10
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            text: section.title + "  " + section.packages.length
            color: Theme.subtle
            font.pixelSize: Theme.fontSize - 2
        }

        Repeater {
            model: section.packages

            RowLayout {
                required property var modelData

                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: 24
                spacing: 12

                ShellText {
                    Layout.fillWidth: true
                    text: modelData.name
                    elide: Text.ElideRight
                }

                ShellText {
                    Layout.maximumWidth: 140
                    text: modelData.to
                    color: Theme.subtle
                    font.pixelSize: Theme.fontSize - 1
                    elide: Text.ElideMiddle
                }
            }
        }
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

        ColumnLayout {
            id: layout

            anchors.fill: parent
            anchors.margins: 10
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.bottomMargin: 4

                ShellText {
                    Layout.fillWidth: true
                    text: "Updates"
                    color: Theme.fgAct
                    font.weight: Font.DemiBold
                }

                ShellText {
                    text: UpdatesService.available
                        ? UpdatesService.count + " pending"
                        : UpdatesService.checked ? "Up to date" : ""
                    color: UpdatesService.available ? Theme.red : Theme.subtle
                    font.pixelSize: Theme.fontSize - 1
                }
            }

            ShellText {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.bottomMargin: 4
                visible: UpdatesService.failed
                text: "Couldn't reach the mirrors, showing the last result."
                color: Theme.amber
                font.pixelSize: Theme.fontSize - 2
                wrapMode: Text.WordWrap
            }

            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, root.maxListHeight)
                visible: UpdatesService.available
                contentHeight: sections.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                ColumnLayout {
                    id: sections

                    width: parent.width
                    spacing: 4

                    PackageSection {
                        title: "Official"
                        packages: UpdatesService.repo
                    }

                    PackageSection {
                        title: "AUR"
                        packages: UpdatesService.aur
                    }
                }
            }

            Divider {}

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                spacing: 6

                ShellText {
                    Layout.fillWidth: true
                    text: UpdatesService.checking ? "Checking…"
                        : UpdatesService.checked
                            ? "Checked " + Qt.formatTime(UpdatesService.lastChecked, "HH:mm")
                            : ""
                    color: Theme.subtle
                    font.pixelSize: Theme.fontSize - 2
                }

                Chip {
                    text: "Refresh"
                    quiet: true
                    onClicked: UpdatesService.refresh()
                }

                Chip {
                    visible: UpdatesService.available
                    text: "Update"
                    active: true
                    onClicked: {
                        UpdatesService.upgrade();
                        root.visible = false;
                    }
                }
            }
        }
    }
}
