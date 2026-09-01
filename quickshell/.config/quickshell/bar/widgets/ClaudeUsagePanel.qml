import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../ui"

PopupWindow {
    id: root

    // Not `data`: every QObject has one, and shadowing it stops the popup mapping.
    property var record: null
    property var anchorItem: null

    property date now: new Date()

    readonly property var limits: record && record.limits ? record.limits : []
    readonly property var days: record && record.recentDays ? record.recentDays : []

    readonly property var models: {
        if (!record || !record.modelUsage) return [];
        const out = [];
        for (const name in record.modelUsage) {
            const usage = record.modelUsage[name];
            let total = 0;
            for (const key in usage) total += usage[key];
            out.push({ name: name, total: total });
        }
        return out.sort((a, b) => b.total - a.total);
    }

    readonly property real dayPeak: {
        let max = 1;
        for (const day of days) max = Math.max(max, day.messageCount || 0);
        return max;
    }
    readonly property real modelPeak: models.length ? models[0].total : 1
    readonly property string today: Qt.formatDate(now, "yyyy-MM-dd")

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX

    implicitWidth: 360
    implicitHeight: layout.implicitHeight + 28
    color: "transparent"

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }

    function countdown(iso) {
        if (!iso) return "-";
        let secs = Math.floor((new Date(iso) - root.now) / 1000);
        if (secs <= 0) return "now";
        const days = Math.floor(secs / 86400); secs -= days * 86400;
        const hours = Math.floor(secs / 3600); secs -= hours * 3600;
        const mins = Math.floor(secs / 60);
        if (days) return days + "d " + hours + "h";
        if (hours) return hours + "h " + String(mins).padStart(2, "0") + "m";
        return mins + "m";
    }

    function humanize(n) {
        if (n >= 1e9) return (n / 1e9).toFixed(1) + "B";
        if (n >= 1e6) return (n / 1e6).toFixed(1) + "M";
        if (n >= 1e3) return (n / 1e3).toFixed(1) + "k";
        return String(Math.round(n));
    }

    function shortModel(name) {
        let s = name.startsWith("claude-") ? name.substring(7) : name;
        const cut = s.lastIndexOf("-");
        if (cut > 0 && /^\d{8}$/.test(s.substring(cut + 1))) s = s.substring(0, cut);
        return s;
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.94)
        border.width: 1
        border.color: Theme.border

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            ShellText {
                text: "Claude Code"
                    + (root.record && root.record.tierLabel
                        ? "   ·   " + root.record.tierLabel : "")
                color: Theme.fgAct
                font.weight: Font.DemiBold
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: root.limits.length > 0

                ShellText {
                    text: "LIMITS"
                    color: Theme.border
                    font.pixelSize: Theme.fontSize - 2
                }

                Repeater {
                    model: root.limits

                    RowLayout {
                        id: limitRow
                        required property var modelData

                        Layout.fillWidth: true
                        spacing: 8

                        ShellText {
                            text: limitRow.modelData.label.indexOf("5-hour") >= 0
                                ? "Session" : "Weekly"
                            Layout.preferredWidth: 54
                        }

                        Meter {
                            Layout.fillWidth: true
                            fraction: limitRow.modelData.percent || 0
                        }

                        ShellText {
                            text: Math.round((limitRow.modelData.percent || 0) * 100) + "%"
                            color: Theme.fgAct
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: 34
                        }

                        ShellText {
                            text: root.countdown(limitRow.modelData.resetsAt)
                            color: Theme.border
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: 58
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: root.days.length > 0

                ShellText {
                    text: "TOKENS BY DAY"
                    color: Theme.border
                    font.pixelSize: Theme.fontSize - 2
                    Layout.bottomMargin: 2
                }

                Repeater {
                    model: root.days

                    RowLayout {
                        id: dayRow
                        required property var modelData
                        readonly property bool isToday: modelData.date === root.today
                        readonly property real tokens: modelData.messageCount || 0

                        Layout.fillWidth: true
                        spacing: 8

                        ShellText {
                            text: new Date(dayRow.modelData.date).toLocaleDateString(Qt.locale("en_US"), "ddd dd")
                            color: dayRow.isToday ? Theme.fgAct : Theme.fg
                            font.weight: dayRow.isToday ? Font.DemiBold : Font.Normal
                            Layout.preferredWidth: 54
                        }

                        Meter {
                            Layout.fillWidth: true
                            fraction: dayRow.tokens / root.dayPeak
                        }

                        ShellText {
                            text: root.humanize(dayRow.tokens)
                            color: dayRow.isToday ? Theme.fgAct : Theme.fg
                            font.weight: dayRow.isToday ? Font.DemiBold : Font.Normal
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: 58
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: root.models.length > 0

                ShellText {
                    text: "TOKENS BY MODEL"
                    color: Theme.border
                    font.pixelSize: Theme.fontSize - 2
                    Layout.bottomMargin: 2
                }

                Repeater {
                    model: root.models

                    RowLayout {
                        id: modelRow
                        required property var modelData

                        Layout.fillWidth: true
                        spacing: 8

                        ShellText {
                            text: root.shortModel(modelRow.modelData.name)
                            Layout.preferredWidth: 86
                            elide: Text.ElideRight
                        }

                        Meter {
                            Layout.fillWidth: true
                            fraction: modelRow.modelData.total / root.modelPeak
                        }

                        ShellText {
                            text: root.humanize(modelRow.modelData.total)
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: 58
                        }
                    }
                }
            }

            ShellText {
                Layout.topMargin: 2
                color: Theme.border
                font.pixelSize: Theme.fontSize - 2
                text: {
                    if (!root.record) return "";
                    const bits = [];
                    if (root.record.totalPrompts)
                        bits.push(root.record.totalPrompts + " prompts");
                    if (root.record.totalSessions)
                        bits.push(root.record.totalSessions + " sessions");
                    if (root.record.activeDays)
                        bits.push(root.record.activeDays + " active days");
                    return bits.join("  ·  ");
                }
            }
        }
    }
}
