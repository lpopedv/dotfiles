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

    panelWidth: 200
    contentHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: 2

        ShellText {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.bottomMargin: 4
            text: "Bar"
            color: Theme.fgAct
            font.weight: Theme.weightMedium
        }

        SectionLabel {
            text: "Position"
        }

        // Two by two: four chips side by side wouldn't fit the panel.
        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            columns: 2
            columnSpacing: 6
            rowSpacing: 6

            Repeater {
                model: BarService.positions

                Chip {
                    required property var modelData

                    Layout.fillWidth: true
                    text: modelData.text
                    active: BarService.position === modelData.id
                    onClicked: {
                        BarService.setPosition(modelData.id);
                        // The bar is about to move out from under this popup.
                        root.visible = false;
                    }
                }
            }
        }

        SectionLabel {
            text: "Logo"
        }

        // Stays open: the logo changes in place, right next to this panel.
        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            columns: BarService.logos.length
            columnSpacing: 6

            Repeater {
                model: BarService.logos

                Chip {
                    required property var modelData

                    Layout.fillWidth: true
                    text: modelData.glyph
                    active: BarService.logo === modelData.id
                    onClicked: BarService.setLogo(modelData.id)
                }
            }
        }

        SectionLabel {
            text: "Corners"
        }

        // Applies to the whole shell at once, this panel included, so the choice shows itself.
        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            columns: Theme.cornerStyles.length
            columnSpacing: 6

            Repeater {
                model: Theme.cornerStyles

                Chip {
                    required property var modelData

                    Layout.fillWidth: true
                    text: modelData.text
                    active: Theme.corners === modelData.id
                    onClicked: Theme.setCorners(modelData.id)
                }
            }
        }
    }
}
