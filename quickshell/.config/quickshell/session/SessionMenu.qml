pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.ui

// Built only while open: it covers a screen and takes the whole keyboard, so nothing of
// it should linger, and every open starts from a fresh, known state.
LazyLoader {
    active: SessionService.open

    PanelWindow {
        id: root

        // Order, actions and keybinds are the wlogout layout file this replaces.
        readonly property var entries: [
            { icon: "lock",      text: "Lock",      key: "l", action: ["loginctl", "lock-session"] },
            { icon: "hibernate", text: "Hibernate", key: "h", action: ["systemctl", "hibernate"], needs: "canHibernate" },
            { icon: "logout",    text: "Logout",    key: "e", action: ["loginctl", "terminate-user", Quickshell.env("USER")] },
            { icon: "shutdown",  text: "Shutdown",  key: "s", action: ["systemctl", "poweroff"] },
            { icon: "suspend",   text: "Suspend",   key: "u", action: ["systemctl", "suspend"] },
            { icon: "reboot",    text: "Reboot",    key: "r", action: ["systemctl", "reboot"] }
        ]

        readonly property int columns: 3

        screen: SessionService.screen

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: Qt.rgba(0, 0, 0, 0.92)

        // Entries naming a `needs` flag stay in place, dimmed, when SessionService says no.
        function available(entry) {
            return !entry.needs || SessionService[entry.needs] === true;
        }

        function run(entry) {
            if (!root.available(entry)) return;
            SessionService.close();
            Quickshell.execDetached(entry.action);
        }

        // A third way out after Esc and a click: if neither reaches the menu (input stuck
        // elsewhere, a half-broken reload), it gives the keyboard back on its own.
        Timer {
            id: idle
            interval: 30000
            running: true
            onTriggered: SessionService.close()
        }

        Item {
            anchors.fill: parent
            focus: true

            // Backstop: a keyboard-only exit is a trap if focus ever fails to arrive.
            MouseArea {
                anchors.fill: parent
                onClicked: SessionService.close()
            }

            // A handler, not the MouseArea above: it sees the pointer over the buttons too.
            HoverHandler {
                onPointChanged: idle.restart()
            }

            Keys.onPressed: event => {
                idle.restart();
                if (event.key === Qt.Key_Escape) {
                    SessionService.close();
                    event.accepted = true;
                    return;
                }
                for (const entry of root.entries) {
                    if (event.text.toLowerCase() === entry.key) {
                        root.run(entry);
                        event.accepted = true;
                        return;
                    }
                }
            }

            GridLayout {
                anchors.fill: parent
                // Insets like wlogout does, for the same wide/short button proportion.
                anchors.margins: 230
                columns: root.columns
                columnSpacing: 16
                rowSpacing: 16

                Repeater {
                    model: root.entries

                    Rectangle {
                        id: button

                        required property var modelData
                        readonly property bool available: root.available(modelData)

                        radius: Theme.radiusCard

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 6

                        color: mouse.containsMouse ? "#1a1a1a" : "#0d0d0d"
                        border.width: 1
                        border.color: mouse.containsMouse ? Theme.fgAct : Theme.border
                        // Dims the whole button rather than recolouring the icon; svgs stay fixed #cccccc.
                        opacity: !button.available ? 0.22 : mouse.containsMouse ? 1.0 : 0.62

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutQuad }
                        }
                        Behavior on color {
                            ColorAnimation { duration: Theme.animMs }
                        }

                        Image {
                            source: Qt.resolvedUrl("icons/" + button.modelData.icon + ".svg")
                            // y = 0.38 * free space (not height) matches wlogout's icon centre at 42%.
                            width: button.width * 0.22
                            height: width
                            sourceSize.width: width * 2
                            sourceSize.height: height * 2
                            smooth: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: (parent.height - height) * 0.38
                        }

                        ShellText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            // Measured off wlogout.
                            y: parent.height * 0.87 - height / 2
                            text: button.modelData.text
                            color: mouse.containsMouse ? Theme.fgAct : Theme.fg
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: button.available
                            onClicked: root.run(button.modelData)
                        }
                    }
                }
            }
        }
    }
}
