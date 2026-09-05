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

    // Everything floating over the desktop shares these two grounds, so the
    // hyprland blur rule (ignore_alpha 0.2) reads the same behind all of them.
    readonly property color surface: Qt.rgba(bg.r, bg.g, bg.b, 0.94)
    readonly property color overlay: Qt.rgba(bg.r, bg.g, bg.b, 0.86)

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

    // The ground the bar and the dock share. Thin enough that the hyprland blur
    // rule (ignore_alpha 0.2) does the work of the background, which is why the
    // two read as the same material rather than as two dark rectangles.
    readonly property color glass: Qt.rgba(bg.r, bg.g, bg.b, barOpacity)

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int iconSize: 15

    // Deliberately short. These are feedback, not choreography: past about
    // 150ms a hover or a panel stops reading as responsive and starts reading
    // as the machine being slow.
    readonly property int animMs: 90
    readonly property int animSlideMs: 140

    // How far a bar item's box stops short of the bar's own top and bottom.
    readonly property int barItemInset: 5

    // Popups hang this far below the bar instead of butting up against it, so
    // they read as their own surface rather than as part of the bar. They
    // anchor to the bar *item*, whose bottom edge is already barItemInset above
    // the bar's, so clearing the bar means insetting by both.
    readonly property int popupGap: 8
    readonly property int popupInset: popupGap + barItemInset

    readonly property real dimmedOpacity: 0.45

    // ------------------------------------------------------------------- dock
    // The dock's icon size is not here: it is one of the things the bar's dock
    // button lets you change, so it lives in DockService with the rest of that
    // state. Everything below is fixed.
    readonly property int dockIconGap: 10

    // Icons on the dock never change size. Hover is answered by a highlight
    // that slides between slots, so the only thing that moves is the one box
    // following the pointer - see dock/Dock.qml.
    readonly property int dockPad: 8
    // How far the dock floats above the screen edge. Matches hyprland's
    // gaps_out, so a maximised window and the dock keep the same margin.
    readonly property int dockFloat: 4
    // Sliver of the hidden dock left on screen for the pointer to find.
    readonly property int dockStrip: 2
    readonly property int dockDot: 3

    // Asymmetric on purpose: coming back has to feel immediate, leaving has to
    // be slow enough that crossing the bottom edge on the way somewhere else
    // does not make the dock flicker.
    readonly property int dockRevealMs: 170
    readonly property int dockHideMs: 240
}
