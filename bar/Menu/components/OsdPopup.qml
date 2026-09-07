pragma ComponentBehavior: Bound
import "../../../services"
import "../../../Settings"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../.."

PanelWindow {
    id: osdWindow

    readonly property bool useFullscreenLayout: NotificationSettings.fullscreenOSD
    readonly property bool isFullscreen: HyprlandService.isFullscreen

    property string osdType: ""
    property real osdValue: 0
    property var barRef: null

    // Responsive sizing: tighter in fullscreen, compact elsewhere.
    readonly property bool compact: isFullscreen || osdWindow.width < Theme.scaled(200)
    readonly property real pad: Theme.scaled(compact ? 10 : 16)
    readonly property real barH: Theme.scaled(compact ? 4 : 6)

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Position (top-right)
    anchors {
        top: true
        right: true
    }

    WlrLayershell.margins {
        top: Theme.scaled(12)
        right: osdWindow.isFullscreen ? Theme.scaled(6) : Theme.scaled(12)
    }

    // Grows with the slider but never exceeds a cap.
    implicitWidth: Math.min(Theme.scaled(280), contentRow.implicitWidth + pad * 2)
    implicitHeight: Theme.scaled(compact ? 48 : 64)

    // Always appears, even in fullscreen.
    visible: osdTimer.running || contentWrapper.opacity > 0 || mainMouseArea.containsMouse
    color: "transparent"

    // Accessible contentRow height for width estimation
    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.margins: osdWindow.pad
        spacing: Theme.scaled(compact ? 8 : 12)
        visible: false
        Rectangle { width: Theme.scaled(28); height: Theme.scaled(28) }
        Item { width: Theme.scaled(40); height: 1 }
        Item { width: Theme.scaled(30); height: 1 }
    }

    Rectangle {
        id: contentWrapper
        anchors.fill: parent
        color: Theme.glassBackground
        radius: Theme.scaled(compact ? 12 : 18)
        border.color: Theme.glassBorder
        border.width: 1
        clip: true

        opacity: (osdTimer.running || mainMouseArea.containsMouse) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }

        MouseArea {
            id: mainMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: osdTimer.stop()
            onExited: osdTimer.restart()
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: osdWindow.pad
            spacing: Theme.scaled(compact ? 8 : 12)
            z: 2

            // Icon (no box, minimal)
            Text {
                id: osdIcon
                font.pixelSize: Theme.scaled(compact ? 16 : 20)
                font.family: Theme.iconFont
                color: (osdValue <= 0) ? Theme.powerRed
                       : (osdType === "volume" && osdValue > 1.0 ? Theme.powerYellow : Theme.powerGreen)
                text: {
                    if (osdType === "brightness") {
                        if (osdValue <= 0.33) return "󰃞"; if (osdValue <= 0.66) return "󰃟"; return "󰃠"
                    }
                    if (osdType === "volume") {
                        if (osdValue <= 0) return "󰝟"; if (osdValue <= 0.33) return "󰕿";
                        if (osdValue <= 0.66) return "󰖀"; if (osdValue <= 1.0) return "󰕾"; return "󰓃"
                    }
                    return "󰋽"
                }
            }

            // Track (thin bar, no box, no handle)
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: osdWindow.barH
                implicitHeight: osdWindow.barH

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Colors.surface_container_high
                }
                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: parent.width * osdWindow.osdValue
                    radius: height / 2
                    color: (osdValue > 1.0 ? Theme.powerYellow
                           : osdValue <= 0 ? Theme.powerRed : Theme.powerGreen)
                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => {
                        let v = mouse.x / width;
                        v = Math.max(0, Math.min(1, v));
                        osdWindow.osdValue = v;
                        NotificationService.updateOSDValue(osdWindow.osdType, v);
                        osdTimer.restart();
                    }
                }
            }

            // Percent label
            Text {
                text: Math.round(osdWindow.osdValue * 100) + "%"
                color: Colors.on_background
                font.family: Constants.monoFont
                font.weight: Font.Bold
                font.pixelSize: Theme.scaled(compact ? 11 : 13)
            }
        }
    }

    Timer {
        id: osdTimer
        interval: 1800 // snappier hide
    }

    Connections {
        target: NotificationService
        function onOsdReceived(type, value) {
            osdWindow.osdType = type
            osdWindow.osdValue = value
            osdTimer.restart()
        }
    }
}
