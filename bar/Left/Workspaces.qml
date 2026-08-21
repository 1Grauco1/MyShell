pragma ComponentBehavior: Bound
import ".."
import "../.."
import "../../Settings"
import "../../services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: workspaceBar

    height: Theme.pillHeight
    implicitHeight: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: mainPill.width

    readonly property HyprlandMonitor monitor: (QsWindow.window && QsWindow.window.monitor) ? QsWindow.window.monitor : null
    property var workspaceIds: {
        let ids = [1, 2, 3, 4, 5];
        const values = Hyprland.workspaces.values;
        for (let i = 0; i < values.length; i++) {
            const w = values[i];
            const isActive = w.id > 5 && w.id > 0 && ((Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === w.id) || (workspaceBar.monitor && workspaceBar.monitor.focusedWorkspace && workspaceBar.monitor.focusedWorkspace.id === w.id));
            if (isActive || (w.toplevels.values.length > 0 && w.id > 0 && ids.indexOf(w.id) === -1)) {
                ids.push(w.id);
            }
        }
        return ids;
    }

    // Solid pill container matching the rest of the bar
    Rectangle {
        id: mainPill
        anchors.centerIn: parent
        height: Theme.pillHeight
        implicitHeight: Theme.pillHeight
        width: row.implicitWidth + Theme.scaled(20)
        color: pillHoverArea.containsMouse ? Theme.pillHoverColor : Theme.pillColor
        border.width: 1
        border.color: Theme.glassBorder
        radius: height / 2

        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        MouseArea {
            id: pillHoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.scaled(8)

            Repeater {
                model: workspaceBar.workspaceIds

                delegate: Item {
                    id: wsIcon

                    required property var modelData

                    readonly property int workspaceId: modelData
                    readonly property real dotSize: Theme.scaled(16)

                    // Look up the live Hyprland workspace for this id (null when it doesn't exist yet)
                    readonly property var wsObject: {
                        const list = Hyprland.workspaces.values;
                        for (let i = 0; i < list.length; i++) {
                            if (list[i].id === workspaceId) return list[i];
                        }
                        return null;
                    }

                    readonly property bool isOccupied: wsObject ? (wsObject.toplevels.values.length > 0) : false
                    readonly property bool isCurrentActive: {
                        let focusedId = -1;
                        if (workspaceBar.monitor && workspaceBar.monitor.focusedWorkspace) focusedId = workspaceBar.monitor.focusedWorkspace.id;
                        else if (Hyprland.focusedWorkspace) focusedId = Hyprland.focusedWorkspace.id;
                        return focusedId === workspaceId;
                    }

                    readonly property string wsIconText: isCurrentActive ? "\u{F0BAF}" : (isOccupied ? "\u{F444}" : "\u{F4C3}")
                    readonly property color iconColor: isCurrentActive ? Theme.accentColor : (isOccupied ? Theme.fontColor : Theme.inactiveTextColor)

                    width: dotSize
                    height: dotSize

                    Text {
                        anchors.centerIn: parent
                        text: wsIcon.wsIconText
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(14)
                        color: wsIcon.iconColor
                    }

                    scale: wsMouse.pressed ? 0.8 : (wsMouse.containsMouse ? 1.2 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Theme.elasticEasing } }

                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        anchors.margins: -Theme.scaled(4)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (wsObject && typeof wsObject.activate === "function") {
                                wsObject.activate();
                            } else {
                                Hyprland.dispatch("workspace " + workspaceId);
                            }
                        }
                    }
                }
            }
        }
    }

    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0) {
                Hyprland.dispatch("workspace", "e+1");
            } else if (event.angleDelta.y > 0) {
                Hyprland.dispatch("workspace", "e-1");
            }
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }
}
