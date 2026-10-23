pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.bar
import qs.services
import qs.ui

BarPopup {
    id: root

    readonly property int maxListHeight: 320

    panelWidth: 320
    contentHeight: layout.implicitHeight

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
                id: row

                required property var modelData

                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: 24
                spacing: 12

                ShellText {
                    Layout.fillWidth: true
                    text: row.modelData.name
                    elide: Text.ElideRight
                }

                ShellText {
                    Layout.maximumWidth: 140
                    text: row.modelData.to
                    color: Theme.subtle
                    font.pixelSize: Theme.fontSize - 1
                    elide: Text.ElideMiddle
                }
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
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
                font.weight: Theme.weightMedium
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

                PackageSection {
                    title: "Lethe"
                    packages: UpdatesService.lethe
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
