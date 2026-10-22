pragma Singleton

import QtQuick
import Quickshell

Singleton {
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

    // A side bar is thicker than a top/bottom one: stacked text (clock, battery) needs the room.
    readonly property int barHeight: 34
    readonly property int barWidth: 44

    // Must clear hyprland's ignore_alpha (0.2) or the compositor skips
    // blurring it and it becomes a hole in the desktop.
    readonly property real glassOpacity: 0.55
    readonly property color glass: Qt.rgba(bg.r, bg.g, bg.b, glassOpacity)

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int iconSize: 15
    // A monospace face goes heavy fast at UI sizes: emphasis is Medium, and the strong weight
    // is kept for large display figures.
    readonly property int weightMedium: Font.Medium
    readonly property int weightStrong: Font.DemiBold

    readonly property int animMs: 90
    readonly property int animSlideMs: 140
    // Bar popups ease in from the bar by this much as they fade in.
    readonly property int popupSlide: 6

    // Curves are [cx1, cy1, cx2, cy2, 1, 1] for `easing.type: Easing.BezierSpline`.
    // Reveal/collapse of the bar's items: one long, decelerating curve (ease-out-quint)
    // on a single progress value, so width, fade and scale all move as one gesture.
    readonly property int revealMs: 340
    readonly property var revealCurve: [0.22, 1, 0.36, 1, 1, 1]
    // Neighbours follow each other this far apart, so a reveal ripples instead of snapping.
    readonly property int revealStaggerMs: 22
    // Collapsing is quicker and all at once: a long decelerating tail reads as a hitch
    // on the way out, and a ripple leaves the last item lagging behind the rest.
    readonly property int collapseMs: 220
    // Symmetric ease-in-out (sine): no long tail at the end.
    readonly property var collapseCurve: [0.45, 0, 0.55, 1, 1, 1]
    // Fading out when the bar changes side: accelerates away, nothing to linger.
    readonly property var leaveCurve: [0.4, 0, 1, 1, 1, 1]

    readonly property int barItemInset: 5

    // Anchors to the bar item, already barItemInset inside the bar, so
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
