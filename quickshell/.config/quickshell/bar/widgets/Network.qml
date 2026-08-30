import QtQuick
import Quickshell
import Quickshell.Networking
import "../.."
import "../../ui"

BarItem {
    id: root

    readonly property var wifiDevice: {
        const devices = Networking.devices.values;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi) return devices[i];
        }
        return null;
    }

    readonly property var wiredDevice: {
        const devices = Networking.devices.values;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wired && devices[i].connected) return devices[i];
        }
        return null;
    }

    readonly property var wifiNetwork: {
        if (!wifiDevice || !wifiDevice.connected) return null;
        const nets = wifiDevice.networks.values;
        for (let i = 0; i < nets.length; i++) {
            if (nets[i].connected) return nets[i];
        }
        return null;
    }

    readonly property bool wired: wiredDevice !== null
    readonly property bool connected: wired || wifiNetwork !== null

    onClicked: {
        if (root.wifiDevice) {
            Quickshell.execDetached([
                "ghostty",
                "--gtk-single-instance=false",
                "--class=org.dotfiles.impala",
                "--title=Impala",
                "-e", "impala"
            ]);
        }
    }

    ShellText {
        text: root.wired
            ? Icons.ethernet
            : root.wifiNetwork ? Icons.wifiIcon(root.wifiNetwork.signalStrength)
            : Icons.wifiOff
        color: root.hovered ? Theme.fgAct : Theme.fg
        font.pixelSize: Theme.iconSize
    }
}
