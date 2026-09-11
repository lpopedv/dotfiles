pragma Singleton

import QtQuick

QtObject {
    id: root

    function cp(code) {
        return String.fromCodePoint(code);
    }

    readonly property string clock: cp(0xF0954)
    readonly property string robot: cp(0xF06A9)
    readonly property string volume: cp(0xF057E)
    readonly property string volumeMuted: cp(0xF075F)
    readonly property string memory: cp(0xF035B)
    readonly property string eyedropper: cp(0xF020B)
    readonly property string coffee: cp(0xF06CA)
    readonly property string bell: cp(0xF009A)
    readonly property string bellOutline: cp(0xF009C)
    readonly property string bellOffOutline: cp(0xF0A91)
    // FA range is 0xF186, not 0xF0186 - wrong one renders tofu.
    readonly property string moon: cp(0xF186)
    readonly property string power: cp(0xF0425)
    readonly property string ethernet: cp(0xF0002)
    readonly property string wifiOff: cp(0xF092E)
    readonly property string brightness: cp(0xF00DF)
    readonly property string charging: cp(0xF0084)
    readonly property string dock: cp(0xF10A9)

    readonly property string check: cp(0xF012C)
    readonly property string radioOn: cp(0xF0765)
    readonly property string radioOff: cp(0xF0130)
    readonly property string chevronRight: cp(0xF0142)

    readonly property string workspaceDot: "●"

    readonly property var wifi: [
        cp(0xF092F), cp(0xF091F), cp(0xF0922), cp(0xF0925), cp(0xF0928)
    ]

    readonly property var battery: [
        cp(0xF007A), cp(0xF007B), cp(0xF007C), cp(0xF007D), cp(0xF007E),
        cp(0xF007F), cp(0xF0080), cp(0xF0081), cp(0xF0082), cp(0xF0079)
    ]

    function pick(list, fraction) {
        const i = Math.floor(fraction * list.length);
        return list[Math.max(0, Math.min(list.length - 1, i))];
    }

    function wifiIcon(fraction) {
        return pick(root.wifi, fraction);
    }

    function batteryIcon(fraction) {
        return pick(root.battery, fraction);
    }
}
