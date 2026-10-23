pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import qs
import qs.services
import qs.ui

// The bar's "apple": waves by default, for Lethe's river; the glyph is picked
// in the bar settings. Left click opens the launcher (same as Super+Space),
// right click the bar settings.
BarItem {
    id: root

    padding: BarService.vertical ? 8 : 10
    // The ring is the hover cue; BarItem's square fill would fight it.
    color: "transparent"
    onClicked: button => {
        if (button === Qt.RightButton) panel.active = !panel.active;
        else Quickshell.execDetached(["rofi", "-show", "drun"]);
    }

    // Built on open, destroyed on close: a hidden popup still runs all its bindings.
    LazyLoader {
        id: panel

        BarSettingsPanel {
            anchorItem: root
            visible: true
            onDismissed: panel.active = false
        }
    }

    ShellText {
        text: BarService.logoGlyph
        color: Theme.fgAct
        font.pixelSize: 18
    }

    // Still where nobody would see it move: a fullscreen window covers this screen's bar.
    readonly property bool live: LogoService.running
        && !LogoService.covered(root.QsWindow.window ? root.QsWindow.window.screen : null)

    // A popup takes its place from its item once, when shown, and never follows it after.
    // After a change of side the bar slides in from the edge, so the orbit waits for it to
    // settle; leaving, it stays and fades out with the bar.
    readonly property bool orbitWanted: root.width > 0 && root.height > 0
        && (BarService.leaving === 0 || BarService.pending !== "")

    // And it is moved along whenever the logo itself moves or resizes (the layout settling
    // in a freshly built bar, another logo glyph).
    function reanchor() {
        if (orbitWindow.visible) orbitWindow.anchor.updateAnchor();
    }

    onXChanged: Qt.callLater(root.reanchor)
    onYChanged: Qt.callLater(root.reanchor)
    onWidthChanged: Qt.callLater(root.reanchor)
    onHeightChanged: Qt.callLater(root.reanchor)

    function restoreOrbit() {
        orbitWindow.visible = Qt.binding(() => root.orbitWanted);
    }

    // The hexagon and the streak of light orbiting it, in a surface of their own laid exactly
    // over this item. A Qt window redraws all of itself for any change, so a streak inside
    // the bar would redraw the whole bar - and have Hyprland re-blur all of it - every frame;
    // here a frame costs a logo-sized square. The empty mask passes input through to the
    // item underneath, so clicks and hover land on the bar as before.
    PopupWindow {
        id: orbitWindow

        anchor.item: root
        anchor.rect.width: root.width
        anchor.rect.height: root.height
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.adjustment: PopupAdjustment.None

        implicitWidth: Math.max(1, Math.round(root.width))
        implicitHeight: Math.max(1, Math.round(root.height))
        color: "transparent"
        mask: Region {}
        visible: root.orbitWanted

        onVisibleChanged: {
            // Ready to fade in again the next time it shows.
            if (!orbitWindow.visible) orbit.shown = 0;
            // A compositor may dismiss any popup of ours (say, a click outside another one);
            // this one has nothing to dismiss, so it comes straight back.
            if (!orbitWindow.visible && root.orbitWanted) Qt.callLater(root.restoreOrbit);
        }

        Shape {
            id: orbit

            anchors.fill: parent
            // Fades in once shown, and out with the rest of the bar when it changes side (a
            // separate surface, so the bar's own fade doesn't reach it).
            property real shown: 0
            opacity: orbit.shown * (1 - BarService.leaving)

            NumberAnimation on shown {
                to: 1
                duration: Theme.animSlideMs
                easing.type: Easing.OutCubic
                running: orbitWindow.visible
            }

            // Analytic antialiasing: multisampling broke the slanted 1px edges
            // of the faint outline into what looked like a dotted line.
            preferredRendererType: Shape.CurveRenderer

            // Flat-topped, so the height limit (sqrt(3) * r) still leaves a roomy hexagon;
            // the half pixel keeps the 1px stroke crisp.
            readonly property real radius: Math.max(0, Math.min(width / 2, height / Math.sqrt(3)) - 0.5)
            readonly property real perimeter: 6 * orbit.radius
            readonly property real streak: 14

            // Progress round one lap, 0 to 1; follows the shared clock only while live and
            // otherwise holds where it was, so a paused streak costs no frames at all.
            property real phase: 0

            Binding on phase {
                when: root.live
                value: LogoService.phase
                restoreMode: Binding.RestoreNone
            }

            // Six corners plus the first again to close it, starting at the top-left
            // corner so the streak starts its lap along the top edge.
            readonly property var corners: {
                const points = [];
                for (let i = 0; i <= 6; i++) {
                    const angle = Math.PI / 180 * (240 + 60 * i);
                    points.push(Qt.point(orbit.width / 2 + orbit.radius * Math.cos(angle),
                                         orbit.height / 2 + orbit.radius * Math.sin(angle)));
                }
                return points;
            }

            // Faint outline, so the streak reads as travelling along something.
            ShapePath {
                strokeColor: Qt.rgba(1, 1, 1, root.hovered ? 0.3 : 0.14)
                strokeWidth: 1
                fillColor: "transparent"
                joinStyle: ShapePath.MiterJoin
                PathPolyline { path: orbit.corners }
            }

            // Point `distance` along the outline from its first corner; each side is one radius long.
            function pointAt(distance) {
                const along = ((distance % orbit.perimeter) + orbit.perimeter) % orbit.perimeter;
                const side = Math.min(5, Math.floor(along / orbit.radius));
                const t = along / orbit.radius - side;
                const from = orbit.corners[side];
                const to = orbit.corners[side + 1];
                return Qt.point(from.x + (to.x - from.x) * t, from.y + (to.y - from.y) * t);
            }

            // The streak as its own short polyline (turning any corner it spans), recomputed
            // from the live size and phase. Not a dash on the outline: CurveRenderer's dashing
            // drew nothing in a bar rebuilt while hidden (after a change of side).
            readonly property var streakPoints: {
                if (orbit.radius <= 0) return [];
                const start = orbit.phase * orbit.perimeter;
                const end = start + orbit.streak;
                const points = [orbit.pointAt(start)];
                for (let k = Math.floor(start / orbit.radius) + 1; k * orbit.radius < end; k++)
                    points.push(orbit.corners[k % 6]);
                points.push(orbit.pointAt(end));
                return points;
            }

            ShapePath {
                strokeColor: Theme.fgAct
                strokeWidth: 1
                fillColor: "transparent"
                joinStyle: ShapePath.MiterJoin
                capStyle: ShapePath.FlatCap
                PathPolyline { path: orbit.streakPoints }
            }
        }
    }
}
