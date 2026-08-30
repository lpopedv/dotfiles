import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../.."
import "../../ui"

BarItem {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property bool muted: audio ? audio.muted : false

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    onClicked: button => {
        if (button === Qt.RightButton && root.audio) root.audio.muted = !root.audio.muted;
        else Quickshell.execDetached([
            "ghostty",
            "--gtk-single-instance=false",
            "--class=org.dotfiles.wiremix",
            "--title=Wiremix",
            "-e", "wiremix"
        ]);
    }

    onWheel: delta => {
        if (!root.audio) return;
        root.audio.volume = Math.max(0, Math.min(1, root.audio.volume + (delta > 0 ? 0.02 : -0.02)));
    }

    ShellText {
        text: root.muted ? Icons.volumeMuted : Icons.volume
        color: root.hovered ? Theme.fgAct : Theme.fg
        font.pixelSize: Theme.iconSize
    }
}
