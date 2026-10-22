import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.bar
import qs.services
import qs.ui

// Hand-built grid, not QtQuick.Controls MonthGrid: avoids pulling in a
// Controls style, and MonthGrid's `today` role never updates past midnight.
BarPopup {
    id: root

    // Fed by the bar clock so "today" rolls over at midnight without a timer of our own.
    property date today: new Date()

    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()
    property date selected: today

    readonly property var locale: Qt.locale()

    readonly property int cellWidth: 38
    readonly property int cellHeight: 30
    readonly property int cellGap: 2

    // Locale weekday order: Sunday-first for en_US/pt_BR, Monday-first elsewhere.
    readonly property var weekdays: {
        const out = [];
        for (let i = 0; i < 7; i++) out.push((root.locale.firstDayOfWeek + i) % 7);
        return out;
    }

    // Always six rows so the panel height never jumps between months.
    readonly property var cells: {
        const lead = (new Date(viewYear, viewMonth, 1).getDay() - root.locale.firstDayOfWeek + 7) % 7;
        const out = [];
        for (let i = 0; i < 42; i++) {
            // Built from components, not by adding milliseconds, so DST can't skip or repeat a day.
            const d = new Date(viewYear, viewMonth, 1 - lead + i);
            out.push({
                year: d.getFullYear(),
                month: d.getMonth(),
                day: d.getDate(),
                inMonth: d.getMonth() === viewMonth,
                weekend: root.locale.weekDays.indexOf(d.getDay()) < 0
            });
        }
        return out;
    }

    readonly property bool showingToday:
        viewYear === today.getFullYear() && viewMonth === today.getMonth()
        && sameDay(selected, today.getFullYear(), today.getMonth(), today.getDate())

    panelWidth: layout.implicitWidth + root.padding * 2
    contentHeight: layout.implicitHeight
    padding: 14

    // Every open starts on today.
    onVisibleChanged: if (root.visible) root.goToday(false)

    function sameDay(date, year, month, day) {
        return date.getFullYear() === year && date.getMonth() === month && date.getDate() === day;
    }

    // UTC from components so a DST shift can't turn a day into 23 or 25 hours.
    function dayNumber(date) {
        return Math.round(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) / 86400000);
    }

    function isoWeek(date) {
        const t = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        // ISO weeks belong to the year of their Thursday.
        t.setUTCDate(t.getUTCDate() + 3 - (t.getUTCDay() + 6) % 7);
        const jan4 = new Date(Date.UTC(t.getUTCFullYear(), 0, 4));
        return 1 + Math.round(((t - jan4) / 86400000 - 3 + (jan4.getUTCDay() + 6) % 7) / 7);
    }

    function dayOfYear(date) {
        return dayNumber(date) - dayNumber(new Date(date.getFullYear(), 0, 1)) + 1;
    }

    function relative(date) {
        const diff = dayNumber(date) - dayNumber(root.today);
        if (diff === 0) return "Today";
        if (diff === 1) return "Tomorrow";
        if (diff === -1) return "Yesterday";
        return diff > 0 ? "in " + diff + " days" : Math.abs(diff) + " days ago";
    }

    function showMonth(year, month, animate) {
        const target = new Date(year, month, 1);
        const delta = (target.getFullYear() - viewYear) * 12 + target.getMonth() - viewMonth;
        if (delta === 0) return;
        viewYear = target.getFullYear();
        viewMonth = target.getMonth();
        if (animate) {
            slide.from = delta > 0 ? 24 : -24;
            monthSwitch.restart();
        }
    }

    function shiftMonths(n) {
        showMonth(viewYear, viewMonth + n, true);
    }

    function select(year, month, day) {
        root.selected = new Date(year, month, day);
        showMonth(root.selected.getFullYear(), root.selected.getMonth(), true);
    }

    function moveSelection(days) {
        select(selected.getFullYear(), selected.getMonth(), selected.getDate() + days);
    }

    function goToday(animate) {
        root.selected = root.today;
        showMonth(today.getFullYear(), today.getMonth(), animate);
    }

    component Divider: Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 2
        Layout.bottomMargin: 2
        implicitHeight: 1
        color: Theme.divider
    }

    component NavButton: Rectangle {
        id: nav

        property string icon
        signal clicked

        implicitWidth: 26
        implicitHeight: 24
        color: navMouse.containsMouse ? Theme.hoverFill : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.animMs }
        }

        ShellText {
            anchors.centerIn: parent
            text: nav.icon
            color: navMouse.containsMouse ? Theme.fgAct : Theme.fg
            font.pixelSize: Theme.iconSize
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.clicked()
        }
    }

    onKeyPressed: event => {
        const years = event.modifiers & Qt.ShiftModifier ? 12 : 1;
        switch (event.key) {
        case Qt.Key_Left: root.moveSelection(-1); break;
        case Qt.Key_Right: root.moveSelection(1); break;
        case Qt.Key_Up: root.moveSelection(-7); break;
        case Qt.Key_Down: root.moveSelection(7); break;
        case Qt.Key_PageUp: root.shiftMonths(-years); break;
        case Qt.Key_PageDown: root.shiftMonths(years); break;
        case Qt.Key_Home:
        case Qt.Key_T: root.goToday(true); break;
        default: return;
        }
        event.accepted = true;
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                ShellText {
                    text: root.locale.toString(root.today, "dddd").toUpperCase()
                    color: Theme.subtle
                    font.pixelSize: Theme.fontSize - 2
                    font.letterSpacing: 1.5
                }

                RowLayout {
                    spacing: 8

                    ShellText {
                        text: root.locale.toString(root.today, "d MMMM")
                        color: Theme.fgAct
                        font.pixelSize: Theme.fontSize + 9
                        font.weight: Font.DemiBold
                    }

                    ShellText {
                        Layout.alignment: Qt.AlignBaseline
                        text: String(root.today.getFullYear())
                        color: Theme.subtle
                        font.pixelSize: Theme.fontSize + 2
                    }
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignBottom
                spacing: 2

                ShellText {
                    Layout.alignment: Qt.AlignRight
                    text: "Week " + root.isoWeek(root.today)
                    color: Theme.fg
                    font.pixelSize: Theme.fontSize - 2
                }

                ShellText {
                    Layout.alignment: Qt.AlignRight
                    text: "Day " + root.dayOfYear(root.today)
                    color: Theme.subtle
                    font.pixelSize: Theme.fontSize - 2
                }
            }
        }

        Divider {}

        RowLayout {
            Layout.fillWidth: true
            // Fixed so the panel doesn't grow when the taller Today chip appears.
            Layout.preferredHeight: 28
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                spacing: 6

                ShellText {
                    text: root.locale.standaloneMonthName(root.viewMonth, Locale.LongFormat)
                    color: Theme.fgAct
                    font.weight: Font.DemiBold
                }

                ShellText {
                    text: String(root.viewYear)
                    color: Theme.fg
                }
            }

            Chip {
                visible: !root.showingToday
                text: "Today"
                quiet: true
                onClicked: root.goToday(true)
            }

            NavButton {
                icon: Icons.chevronLeft
                onClicked: root.shiftMonths(-1)
            }

            NavButton {
                icon: Icons.chevronRight
                onClicked: root.shiftMonths(1)
            }
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: days.implicitWidth
            implicitHeight: weekdayRow.implicitHeight + 6 + days.implicitHeight
            clip: true

            Row {
                id: weekdayRow

                spacing: root.cellGap

                Repeater {
                    model: root.weekdays

                    ShellText {
                        required property int modelData

                        width: root.cellWidth
                        horizontalAlignment: Text.AlignHCenter
                        text: root.locale.dayName(modelData, Locale.ShortFormat)
                        color: root.locale.weekDays.indexOf(modelData) < 0 ? Theme.border : Theme.subtle
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }

            Grid {
                id: days

                y: weekdayRow.implicitHeight + 6
                columns: 7
                spacing: root.cellGap

                ParallelAnimation {
                    id: monthSwitch

                    NumberAnimation {
                        id: slide
                        target: days
                        property: "x"
                        to: 0
                        duration: Theme.animSlideMs
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        target: days
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Theme.animSlideMs
                        easing.type: Easing.OutCubic
                    }
                }

                Repeater {
                    model: root.cells

                    Rectangle {
                        id: cell

                        required property var modelData

                        readonly property bool isToday:
                            root.sameDay(root.today, modelData.year, modelData.month, modelData.day)
                        readonly property bool isSelected:
                            root.sameDay(root.selected, modelData.year, modelData.month, modelData.day)

                        width: root.cellWidth
                        height: root.cellHeight
                        color: isToday ? Theme.fgAct
                            : isSelected ? Theme.activeFill
                            : cellMouse.containsMouse ? Theme.hoverFill
                            : "transparent"
                        border.width: isSelected && !isToday ? 1 : 0
                        border.color: Theme.accentLine

                        Behavior on color {
                            ColorAnimation { duration: Theme.animMs }
                        }

                        ShellText {
                            anchors.centerIn: parent
                            text: String(cell.modelData.day)
                            color: cell.isToday ? Theme.bg
                                : cellMouse.containsMouse || cell.isSelected ? Theme.fgAct
                                : !cell.modelData.inMonth ? Theme.border
                                : cell.modelData.weekend ? Theme.subtle
                                : Theme.fg
                            font.weight: cell.isToday || cell.isSelected ? Font.DemiBold : Font.Normal
                        }

                        MouseArea {
                            id: cellMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.select(cell.modelData.year, cell.modelData.month, cell.modelData.day)
                        }
                    }
                }
            }

            // Below the cells so their hover still works; they don't take wheel
            // events, which fall through to here. Touchpads send many small deltas.
            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.NoButton

                property int pending: 0

                onWheel: event => {
                    pending += event.angleDelta.y;
                    while (Math.abs(pending) >= 120) {
                        root.shiftMonths(pending > 0 ? -1 : 1);
                        pending -= pending > 0 ? 120 : -120;
                    }
                }
            }
        }

        Divider {}

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 12

            ShellText {
                Layout.fillWidth: true
                text: root.locale.toString(root.selected, "dddd, d MMMM")
                color: Theme.fg
                font.pixelSize: Theme.fontSize - 1
                elide: Text.ElideRight
            }

            ShellText {
                text: root.relative(root.selected) + "  ·  W" + root.isoWeek(root.selected)
                color: Theme.subtle
                font.pixelSize: Theme.fontSize - 2
            }
        }
    }
}
