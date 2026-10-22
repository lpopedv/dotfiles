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

    panelWidth: 250
    contentHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: 2

        ShellText {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.bottomMargin: 4
            text: "Dock"
            color: Theme.fgAct
            font.weight: Theme.weightMedium
        }

        // Radio circles, not ticks: the three modes are mutually exclusive.
        Repeater {
            model: DockService.modes

            MenuRow {
                required property var modelData

                text: modelData.text
                gutter: true
                mark: DockService.mode === modelData.id
                    ? Icons.radioOn : Icons.radioOff
                onTriggered: DockService.setMode(modelData.id)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 5
            Layout.bottomMargin: 5
            implicitHeight: 1
            color: Theme.divider
        }

        MenuRow {
            enabled: DockService.mode === "auto"
            opacity: enabled ? 1 : Theme.dimmedOpacity
            text: "Show on empty workspace"
            gutter: true
            mark: DockService.showOnDesktop ? Icons.check : ""
            onTriggered: DockService.toggleShowOnDesktop()
        }

        MenuRow {
            text: "Only running apps"
            gutter: true
            mark: DockService.runningOnly ? Icons.check : ""
            onTriggered: DockService.toggleRunningOnly()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 5
            Layout.bottomMargin: 5
            implicitHeight: 1
            color: Theme.divider
        }

        ShellText {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.bottomMargin: 4
            text: "Position"
            color: Theme.subtle
            font.pixelSize: Theme.fontSize - 2
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            spacing: 6

            Repeater {
                model: DockService.positions

                Chip {
                    required property var modelData

                    Layout.fillWidth: true
                    text: modelData.text
                    active: DockService.position === modelData.id
                    onClicked: DockService.setPosition(modelData.id)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 5
            Layout.bottomMargin: 5
            implicitHeight: 1
            color: Theme.divider
        }

        ShellText {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.bottomMargin: 4
            text: "Icon size"
            color: Theme.subtle
            font.pixelSize: Theme.fontSize - 2
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            spacing: 6

            Repeater {
                model: DockService.sizes

                Chip {
                    required property var modelData

                    Layout.fillWidth: true
                    text: modelData.text
                    active: DockService.iconSize === modelData.size
                    onClicked: DockService.setIconSize(modelData.size)
                }
            }
        }
    }
}
