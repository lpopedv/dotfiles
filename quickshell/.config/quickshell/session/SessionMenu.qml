import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."
import "../ui"

PanelWindow {
    id: root

    // Order, actions and keybinds are the wlogout layout file this replaces.
    readonly property var entries: [
        { icon: "lock",      text: "Lock",      key: "l", action: ["loginctl", "lock-session"] },
        { icon: "hibernate", text: "Hibernate", key: "h", action: ["systemctl", "hibernate"] },
        { icon: "logout",    text: "Logout",    key: "e", action: ["loginctl", "terminate-user", Quickshell.env("USER")] },
        { icon: "shutdown",  text: "Shutdown",  key: "s", action: ["systemctl", "poweroff"] },
        { icon: "suspend",   text: "Suspend",   key: "u", action: ["systemctl", "suspend"] },
        { icon: "reboot",    text: "Reboot",    key: "r", action: ["systemctl", "reboot"] }
    ]

    readonly property int columns: 3

    visible: SessionState.open

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

    IpcHandler {
        target: "session"

        function toggle(): void { SessionState.toggle(); }
        function open(): void { SessionState.open = true; }
        function close(): void { SessionState.open = false; }
    }

    function run(entry) {
        SessionState.open = false;
        Quickshell.execDetached(entry.action);
    }

    Item {
        anchors.fill: parent
        focus: true

        // A fullscreen overlay whose only exit is a key is a trap if keyboard
        // focus ever fails to arrive. Clicking the background always closes it.
        MouseArea {
            anchors.fill: parent
            onClicked: SessionState.open = false
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                SessionState.open = false;
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
            // wlogout insets the grid rather than filling the screen, which is
            // what gives its buttons their wide, short proportion. Filling
            // edge to edge made them tall enough that an icon at 42% read as
            // floating near the top.
            anchors.margins: 230
            columns: root.columns
            columnSpacing: 16
            rowSpacing: 16

            Repeater {
                model: root.entries

                Rectangle {
                    id: button

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 6

                    color: mouse.containsMouse ? "#1a1a1a" : "#0d0d0d"
                    border.width: 1
                    border.color: mouse.containsMouse ? Theme.fgAct : Theme.border
                    // wlogout dimmed the whole button rather than recolouring the
                    // icon, which is why these svgs can stay a fixed #cccccc.
                    opacity: mouse.containsMouse ? 1.0 : 0.62

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutQuad }
                    }
                    Behavior on color {
                        ColorAnimation { duration: Theme.animMs }
                    }

                    Image {
                        source: Qt.resolvedUrl("icons/" + button.modelData.icon + ".svg")
                        // background-size: 22% is 22% of the width, and a
                        // background-position percentage aligns that point of
                        // the image with the same point of the box - so it is
                        // 0.38 * (free space), not 0.38 * height. That lands
                        // the icon centre at 42%, which is where wlogout's is.
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
                        // Measured off wlogout: the label sits low, not tucked
                        // under the icon.
                        y: parent.height * 0.87 - height / 2
                        text: button.modelData.text
                        color: mouse.containsMouse ? Theme.fgAct : Theme.fg
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.run(button.modelData)
                    }
                }
            }
        }
    }
}
