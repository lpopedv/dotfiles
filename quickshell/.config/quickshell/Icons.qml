pragma Singleton

import QtQuick

QtObject {
    id: root

    function cp(code) {
        return String.fromCodePoint(code);
    }

    readonly property string clock: cp(0xF0954)        // nf-md-clock_outline
    readonly property string robot: cp(0xF06A9)        // nf-md-robot
    readonly property string volume: cp(0xF057E)       // nf-md-volume_high
    readonly property string volumeMuted: cp(0xF075F)  // nf-md-volume_off
    readonly property string memory: cp(0xF035B)       // nf-md-memory
    readonly property string eyedropper: cp(0xF020B)   // nf-md-eyedropper
    readonly property string coffee: cp(0xF06CA)       // nf-md-coffee_outline
    readonly property string bell: cp(0xF009A)         // nf-md-bell
    readonly property string bellOutline: cp(0xF009C)  // nf-md-bell_outline
    readonly property string bellOffOutline: cp(0xF0A91) // nf-md-bell_off_outline
    // Font Awesome range: 0xF186, not 0xF0186. Wrong one renders tofu.
    readonly property string moon: cp(0xF186)          // nf-fa-moon_o
    readonly property string power: cp(0xF0425)        // nf-md-power
    readonly property string ethernet: cp(0xF0002)     // nf-md-access_point_network
    readonly property string wifiOff: cp(0xF092E)      // nf-md-wifi_strength_off_outline
    readonly property string brightness: cp(0xF00DF)   // nf-md-brightness_6
    readonly property string charging: cp(0xF0084)     // nf-md-battery_charging
    readonly property string dock: cp(0xF10A9)         // nf-md-dock_bottom

    // Menu marks. A tick for the independent switches, filled and hollow
    // circles for the one group where the options exclude each other.
    readonly property string check: cp(0xF012C)        // nf-md-check
    readonly property string radioOn: cp(0xF0765)      // nf-md-circle
    readonly property string radioOff: cp(0xF0130)     // nf-md-circle_outline

    readonly property string workspaceDot: "●"    // BLACK CIRCLE

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
