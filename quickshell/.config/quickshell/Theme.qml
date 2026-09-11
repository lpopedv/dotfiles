pragma Singleton

import QtQuick

QtObject {
    readonly property color bg: "#000000"
    readonly property color fg: "#999999"
    readonly property color fgAct: "#ffffff"
    readonly property color border: "#333333"
    readonly property color warn: "#cccccc"

    readonly property color subtle: "#6b6b6b"

    readonly property color hoverFill: Qt.rgba(1, 1, 1, 0.08)
    readonly property color activeFill: Qt.rgba(1, 1, 1, 0.14)
    readonly property color accentLine: Qt.rgba(1, 1, 1, 0.35)
    readonly property color divider: Qt.rgba(1, 1, 1, 0.08)

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

    readonly property int barHeight: 34

    // Must clear hyprland's ignore_alpha (0.2) or the compositor skips
    // blurring it and it becomes a hole in the desktop.
    readonly property real glassOpacity: 0.55
    readonly property color glass: Qt.rgba(bg.r, bg.g, bg.b, glassOpacity)

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int iconSize: 15

    readonly property int animMs: 90
    readonly property int animSlideMs: 140

    readonly property int barItemInset: 5

    // Anchors to the bar item, already barItemInset above the bar, so
    // clearing the bar means insetting by both.
    readonly property int popupGap: 8
    readonly property int popupInset: popupGap + barItemInset

    readonly property real dimmedOpacity: 0.45

    // Icon size is user-configurable via the dock button; lives in DockService.
    readonly property int dockIconGap: 10

    readonly property int dockPad: 8
    // Matches hyprland's gaps_out so a maximised window keeps the same margin.
    readonly property int dockFloat: 4
    readonly property int dockStrip: 2
    readonly property int dockDot: 3

    // Asymmetric on purpose: fast reveal, slow hide so passing the edge
    // doesn't flicker.
    readonly property int dockRevealMs: 170
    readonly property int dockHideMs: 240
}
