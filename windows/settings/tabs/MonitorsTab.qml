import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../Settings"
import "../components"
import "../../../" as Shell

ColumnLayout {
    id: root
    spacing: 0

    property var monitors: []
    readonly property var resolutions: [
        "Native", "1920x1080", "2560x1440", "3840x2160", "3440x1440",
        "2560x1080", "1920x1200", "1680x1050", "1600x900", "1440x900",
        "1366x768", "1360x768", "1280x1024", "1280x800", "1280x720", "1024x768"
    ]

    function reload() {
        listProc.running = false;
        listProc.running = true;
    }

    // Header
    Rectangle {
        Layout.fillWidth: true
        height: Shell.Theme.scaled(60)
        color: "transparent"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Shell.Theme.scaled(20)
            anchors.rightMargin: Shell.Theme.scaled(20)
            Text {
                text: "Monitors"
                font.pixelSize: Shell.Theme.scaled(20)
                font.weight: Font.Bold
                color: Shell.Theme.text
                Layout.fillWidth: true
            }
            Rectangle {
                width: Shell.Theme.scaled(80)
                height: Shell.Theme.scaled(32)
                radius: Shell.Theme.scaled(8)
                color: refreshMouse.containsMouse ? Shell.Theme.blue : Shell.Theme.surface1
                Text {
                    anchors.centerIn: parent
                    text: "Refresh"
                    color: "white"
                    font.bold: true
                    font.pixelSize: Shell.Theme.scaled(12)
                }
                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.reload()
                }
            }
        }
    }

    // Monitor list
    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: Shell.Theme.scaled(4)

            Repeater {
                model: root.monitors

                delegate: SettingRow {
                    id: monitorRow
                    readonly property var mon: modelData
                    readonly property string savedRes: SettingsStore.get("monitor." + mon.name + ".resolution", "Native")
                    label: mon.name + "   " + mon.width + "x" + mon.height + "@" + mon.refreshRate + (mon.focused ? "   ●" : "")

                    RowLayout {
                        spacing: Shell.Theme.scaled(8)

                        SelectionBox {
                            id: sel
                            readonly property var choices: root.resolutions
                            model: choices
                            Component.onCompleted: {
                                let idx = choices.indexOf(monitorRow.savedRes);
                                currentIndex = idx >= 0 ? idx : 0;
                            }
                            Layout.preferredWidth: Shell.Theme.scaled(170)
                        }

                        Rectangle {
                            width: Shell.Theme.scaled(64)
                            height: Shell.Theme.scaled(32)
                            radius: Shell.Theme.scaled(8)
                            color: applyMouse.containsMouse ? Shell.Theme.blue : Shell.Theme.surface1
                            Text {
                                anchors.centerIn: parent
                                text: "Apply"
                                color: "white"
                                font.bold: true
                                font.pixelSize: Shell.Theme.scaled(12)
                            }
                            MouseArea {
                                id: applyMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    let choice = root.resolutions[sel.currentIndex];
                                    if (choice === "Native") {
                                        SettingsStore.set("monitor." + monitorRow.mon.name + ".resolution", "Native");
                                    } else {
                                        applyProc.command = ["bash", PathSettings.scriptsDir + "/monitors.sh", "apply", monitorRow.mon.name, choice];
                                        applyProc.running = false;
                                        applyProc.running = true;
                                        SettingsStore.set("monitor." + monitorRow.mon.name + ".resolution", choice);
                                    }
                                }
                            }
                        }

                        Process { id: applyProc }
                    }
                }
            }

            // Empty state
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Shell.Theme.scaled(120)
                visible: root.monitors.length === 0
                color: "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "No monitors detected (hyprctl missing?)"
                    color: Shell.Theme.subtext1
                    font.pixelSize: Shell.Theme.scaled(14)
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    Process {
        id: listProc
        command: ["bash", PathSettings.scriptsDir + "/monitors.sh", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    let parsed = JSON.parse(text);
                    if (Array.isArray(parsed)) root.monitors = parsed;
                } catch (e) {}
            }
        }
    }

    Component.onCompleted: root.reload()
}
