pragma Singleton

import QtQuick

QtObject {
    readonly property color bg: "#000000"
    readonly property color fg: "#999999"
    readonly property color fgAct: "#ffffff"
    readonly property color border: "#333333"
    readonly property color warn: "#cccccc"

    readonly property color hoverFill: Qt.rgba(1, 1, 1, 0.08)
    readonly property color activeFill: Qt.rgba(1, 1, 1, 0.14)
    readonly property color accentLine: Qt.rgba(1, 1, 1, 0.35)

    readonly property color amber: "#d2a24c"
    readonly property color red: "#cc5f5f"

    readonly property real warnAt: 0.70
    readonly property real dangerAt: 0.90

    function alertColor(used, base) {
        if (used >= dangerAt) return red;
        if (used >= warnAt) return amber;
        return base;
    }

    function isAlert(used) {
        return used >= warnAt;
    }

    readonly property real barOpacity: 0.55
    readonly property int barHeight: 34

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int iconSize: 15

    readonly property int animMs: 150
}
