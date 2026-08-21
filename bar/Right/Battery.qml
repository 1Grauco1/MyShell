pragma ComponentBehavior: Bound
import ".."
import "../.."
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property bool isFullyCharged: BatteryService.isFullyCharged
    readonly property bool isConservative: BatteryService.isConservative
    
    // Hide when fully charged, conservative mode is active, or in fullscreen
    visible: !isFullyCharged && !isConservative && !HyprlandService.isFullscreen
    
    // Ensure visibility is completely tied to this condition
    opacity: visible ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 400 } }

    readonly property int batPercent: Math.max(0, Math.min(100, BatteryService.percentage))
    readonly property string batState: BatteryService.status
    readonly property bool acOnline: BatteryService.acOnline
    height: Theme.pillHeight
    implicitHeight: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: pill.width

    Pill {
        id: pill
        height: Theme.pillHeight
        implicitHeight: Theme.pillHeight
        width: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
        clip: true
        border.width: 0

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                QuickSettingsService.toggle("battery");
        }
        
        Behavior on color { ColorAnimation { duration: 300 } }

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: Theme.scaled(4)

            // Vertical Battery Icon matching other cluster icons
            Text {
                text: Theme.batteryStatusIcon(root.batPercent, root.batState, root.acOnline)
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(Theme.iconSize + 1)
                color: Theme.batteryStatusColor(root.batPercent, root.batState, root.acOnline)
                Layout.alignment: Qt.AlignVCenter

                SequentialAnimation on opacity {
                    running: root.batState === "charging"
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.4; duration: 600 }
                    NumberAnimation { from: 0.4; to: 1.0; duration: 600 }
                }
            }

            // Percentage Text (Shown ONLY when battery <= 20% or on mouse hover)
            Text {
                visible: root.batPercent <= 20
                text: (root.batPercent >= 0 ? root.batPercent : 0) + "%"
                font.pixelSize: Theme.fontSize
                font.family: Constants.monoFont
                font.weight: Font.Bold
                color: Theme.batteryStatusColor(root.batPercent, root.batState, root.acOnline)
                Layout.alignment: Qt.AlignVCenter
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 500
                easing.type: Easing.InOutCubic
            }
        }
    }
}