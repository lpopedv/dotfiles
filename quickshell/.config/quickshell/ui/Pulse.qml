import QtQuick

// A few slow breaths of `target`'s opacity each time it is triggered, then stillness.
// Never endless: a looping animation redraws its window (and Hyprland re-blurs it) on every
// frame for as long as it runs, which for an "updates pending" badge can be all day.
SequentialAnimation {
    id: root

    required property Item target
    // Breathes when this turns true; call trigger() to breathe again while it stays true.
    property bool when: false
    property real low: 0.45
    property int halfMs: 900

    loops: 3

    function trigger() {
        root.restart();
    }

    function settle() {
        root.stop();
        root.target.opacity = 1;
    }

    onWhenChanged: root.when ? root.trigger() : root.settle()
    Component.onCompleted: if (root.when) root.trigger()

    NumberAnimation {
        target: root.target
        property: "opacity"
        to: root.low
        duration: root.halfMs
        easing.type: Easing.InOutQuad
    }
    NumberAnimation {
        target: root.target
        property: "opacity"
        to: 1
        duration: root.halfMs
        easing.type: Easing.InOutQuad
    }
}
