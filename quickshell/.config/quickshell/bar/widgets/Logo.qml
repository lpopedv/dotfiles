import QtQuick
import QtQuick.Shapes
import Quickshell
import "../.."
import "../../ui"

// The bar's "apple": an atom. Left click opens the launcher (same as
// Super+Space), right click the bar settings.
BarItem {
    id: root

    horizontalPadding: 10
    // The ring is the hover cue; BarItem's square fill would fight it.
    color: "transparent"
    onClicked: button => {
        if (button === Qt.RightButton) panel.visible = !panel.visible;
        else Quickshell.execDetached(["rofi", "-show", "drun"]);
    }

    BarSettingsPanel {
        id: panel
        anchorItem: root
        visible: false
        grabFocus: true
    }

    ShellText {
        text: Icons.atom
        color: Theme.fgAct
        font.pixelSize: 18
    }

    // A short streak of light orbiting a hexagon round the glyph. Reparented
    // out of the content row so it can span the whole item instead of being laid out.
    Shape {
        id: orbit

        parent: root
        anchors.fill: parent

        // Analytic antialiasing: multisampling broke the slanted 1px edges
        // of the faint outline into what looked like a dotted line.
        preferredRendererType: Shape.CurveRenderer

        // Flat-topped, so the height limit (sqrt(3) * r) still leaves a roomy hexagon;
        // the half pixel keeps the 1px stroke crisp.
        readonly property real radius: Math.max(0, Math.min(width / 2, height / Math.sqrt(3)) - 0.5)
        readonly property real perimeter: 6 * orbit.radius
        readonly property real streak: 14

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

        // One dash the length of the streak, one gap the rest of the way round.
        ShapePath {
            strokeColor: Theme.fgAct
            strokeWidth: 1
            fillColor: "transparent"
            joinStyle: ShapePath.MiterJoin
            strokeStyle: ShapePath.DashLine
            dashPattern: [orbit.streak, Math.max(1, orbit.perimeter - orbit.streak)]
            capStyle: ShapePath.FlatCap
            PathPolyline { path: orbit.corners }

            NumberAnimation on dashOffset {
                from: orbit.perimeter
                to: 0
                duration: 3000
                loops: Animation.Infinite
                running: orbit.perimeter > 0
            }
        }
    }
}
