import QtQuick
import QtQuick.Layouts
import "../.."

Rectangle {
    id: root

    property alias hovered: mouse.containsMouse
    property bool active: false
    // Breathing room either side of the content, along the bar's axis.
    property int padding: BarService.vertical ? 8 : 11
    // Extra space before this item, on top of the usual gap (e.g. to set a group apart).
    property int leadGap: 0
    default property alias content: layout.data

    property bool collapsible: false
    property bool revealed: true
    // Position in the reveal ripple; see Theme.revealStaggerMs.
    property int order: 0
    readonly property bool collapsed: collapsible && !active && !revealed

    // 0 = tucked away, 1 = settled. Everything that changes on collapse derives from this
    // one value (instead of animating width, opacity and margins on their own clocks).
    property real shown: collapsed ? 0 : 1

    readonly property bool vertical: BarService.vertical
    // Size along the bar's axis, with and without the collapse.
    readonly property real fullExtent: (root.vertical ? layout.implicitHeight : layout.implicitWidth)
        + root.padding * 2
    readonly property real extent: root.fullExtent * root.shown

    signal clicked(int button)
    signal wheel(int delta)

    // Inset across the bar, a small gap between neighbours along it.
    readonly property real gap: 2 * root.shown
    readonly property real lead: root.leadGap * root.shown

    Layout.alignment: BarService.crossAlign
    Layout.topMargin: root.vertical ? root.gap + root.lead : Theme.barItemInset
    Layout.bottomMargin: root.vertical ? root.gap : Theme.barItemInset
    Layout.leftMargin: root.vertical ? Theme.barItemInset : root.gap + root.lead
    Layout.rightMargin: root.vertical ? Theme.barItemInset : root.gap

    clip: true
    implicitWidth: root.vertical ? BarService.thickness - Theme.barItemInset * 2 : root.extent
    implicitHeight: root.vertical ? root.extent : BarService.thickness - Theme.barItemInset * 2
    // Collapsible items sit dimmed until switched on; eased so a toggle doesn't blink.
    property real emphasis: collapsible && !active ? Theme.dimmedOpacity : 1
    Behavior on emphasis {
        NumberAnimation { duration: Theme.animMs }
    }

    // Squared, so the fade trails the width on the way in and leads it on the way out.
    opacity: root.shown * root.shown * root.emphasis

    color: mouse.containsMouse ? Theme.hoverFill : "transparent"
    border.width: 1
    border.color: "transparent"

    Behavior on color {
        ColorAnimation { duration: Theme.animMs }
    }
    Behavior on shown {
        id: shownBehavior

        // Direction comes from the behavior's own target, not from `collapsed`: this
        // starts before bindings derived from `revealed` have updated, and reading
        // them here picked the opening animation for a collapse.
        readonly property bool collapsing: shownBehavior.targetValue < 0.5

        SequentialAnimation {
            PauseAnimation {
                duration: shownBehavior.collapsing ? 0 : root.order * Theme.revealStaggerMs
            }
            NumberAnimation {
                duration: shownBehavior.collapsing ? Theme.collapseMs : Theme.revealMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: shownBehavior.collapsing ? Theme.collapseCurve : Theme.revealCurve
            }
        }
    }

    // Content runs along the bar: a row on top/bottom bars, a stack on side bars.
    GridLayout {
        id: layout
        // Above the root mouse area so widgets can nest their own click targets.
        z: 1
        anchors.centerIn: parent
        // Content settles in as the item opens, rather than being uncovered by the clip.
        scale: 0.88 + 0.12 * root.shown
        columnSpacing: 6
        rowSpacing: 4
        flow: root.vertical ? GridLayout.LeftToRight : GridLayout.TopToBottom
        columns: root.vertical ? 1 : -1
        rows: root.vertical ? -1 : 1
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => root.clicked(event.button)
        onWheel: event => root.wheel(event.angleDelta.y)
    }
}
