import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import ".."
import "../ui"

Scope {
    id: root

    property string icon: ""
    property real fraction: 0
    property bool muted: false

    function show(icon, fraction, muted) {
        root.icon = icon;
        root.fraction = fraction;
        root.muted = muted || false;
        hideTimer.restart();
        window.visible = true;
    }

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: window.visible = false
    }

    // Bindings fire once on startup with whatever the current value is. Without
    // this the OSD flashes on login for a volume nobody touched.
    property bool settled: false
    Timer {
        interval: 1500
        running: true
        onTriggered: root.settled = true
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinkAudio: sink ? sink.audio : null

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Connections {
        target: root.sinkAudio
        enabled: root.settled

        function onVolumeChanged() {
            root.show(root.sinkAudio.muted ? Icons.volumeMuted : Icons.volume,
                      root.sinkAudio.volume, root.sinkAudio.muted);
        }

        function onMutedChanged() {
            root.show(root.sinkAudio.muted ? Icons.volumeMuted : Icons.volume,
                      root.sinkAudio.volume, root.sinkAudio.muted);
        }
    }

    // The backlight is not always intel_backlight, and a desktop has none at
    // all - hardcoding a path means a failed read logged on every start. Empty
    // until the lookup answers, which leaves the FileViews below idle.
    property string backlight: ""

    Process {
        running: true
        command: ["sh", "-c", "ls -1 /sys/class/backlight 2>/dev/null | head -n1"]

        stdout: StdioCollector {
            onStreamFinished: {
                const name = this.text.trim();
                if (name) root.backlight = "/sys/class/backlight/" + name;
            }
        }
    }

    // FileView.text is a method, not a property, and watchChanges only reports
    // that the file changed - it does not re-read it. Hence reload() on
    // fileChanged and reading the value in onLoaded.
    FileView {
        id: brightness
        path: root.backlight ? root.backlight + "/brightness" : ""
        watchChanges: root.backlight !== ""
        preload: root.backlight !== ""

        onFileChanged: reload()
        onLoaded: {
            const max = parseInt(maxBrightness.text());
            if (!root.settled || !max) return;
            root.show(Icons.brightness, parseInt(brightness.text()) / max, false);
        }
    }

    FileView {
        id: maxBrightness
        path: root.backlight ? root.backlight + "/max_brightness" : ""
        preload: root.backlight !== ""
    }

    PanelWindow {
        id: window

        visible: false
        anchors.bottom: true
        margins.bottom: 120

        implicitWidth: 220
        implicitHeight: 64
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: false

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.82)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.10)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ShellText {
                        text: root.icon
                        color: root.muted ? Theme.fg : Theme.fgAct
                        font.pixelSize: Theme.iconSize
                    }

                    Item { Layout.fillWidth: true }

                    ShellText {
                        text: root.muted ? "mudo" : Math.round(root.fraction * 100) + "%"
                        color: root.muted ? Theme.fg : Theme.fgAct
                        font.weight: Font.DemiBold
                    }
                }

                Meter {
                    Layout.fillWidth: true
                    fraction: root.muted ? 0 : root.fraction
                }
            }
        }
    }
}
