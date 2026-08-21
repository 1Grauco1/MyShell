pragma ComponentBehavior: Bound
// bar/Right/QuickSettingsCluster.qml
import ".."
import "../.."
import "../../services"
import "../../Settings"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root

    height: Theme.pillHeight
    implicitHeight: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: outerContainer.implicitWidth

    readonly property int batPercent: Math.max(0, Math.min(100, BatteryService.percentage))
    readonly property string batState: BatteryService.status
    readonly property bool acOnline: BatteryService.acOnline

    Rectangle {
        id: outerContainer
        height: Theme.pillHeight
        implicitHeight: Theme.pillHeight
        width: clusterRow.implicitWidth + Theme.scaled(8) + Theme.scaled(14)
        implicitWidth: width
        radius: height / 2
        color: Theme.pillColor
        border.color: Theme.glassBorder
        border.width: 1
        clip: true

        Behavior on width {
            NumberAnimation { duration: 450; easing.type: Easing.InOutCubic }
        }

        RowLayout {
            id: clusterRow
            anchors.left: parent.left
            anchors.leftMargin: Theme.scaled(8)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.scaled(4)

            ClusterSubWidget {
                visible: VolumeService.micActive
                iconText: VolumeService.micMuted ? "\uf131" : "\uf130"
                iconColor: VolumeService.micMuted ? Colors.error : Theme.accentColor
                onClicked: {
                    micMuteExec.running = false;
                    micMuteExec.running = true;
                    VolumeService.update();
                }
            }

            ClusterSubWidget {
                id: volSubBtn
                property bool showVolText: false

                iconText: Theme.volumeIcon(VolumeService.outputVolume, VolumeService.muted)
                iconColor: VolumeService.btActive ? Theme.bluetoothColor : Theme.fontColor
                labelVisible: showVolText
                label: VolumeService.muted ? "Muted" : VolumeService.outputVolume + "%"
                labelColor: VolumeService.btActive ? Theme.bluetoothColor : Theme.fontColor

                Timer {
                    id: volTextTimer
                    interval: Constants.volumeTextTimeout
                    onTriggered: volSubBtn.showVolText = false
                }

                Connections {
                    target: VolumeService
                    function onOutputVolumeChanged() {
                        volSubBtn.showVolText = true;
                        volTextTimer.restart();
                    }
                    function onMutedChanged() {
                        volSubBtn.showVolText = true;
                        volTextTimer.restart();
                    }
                }

                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        muteExec.running = false;
                        muteExec.running = true;
                    } else {
                        QuickSettingsService.toggle("volume");
                    }
                }
            }

            ClusterSubWidget {
                iconText: BluetoothService.powered ? Theme.btIcon : "󰂲"
                iconColor: BluetoothService.connected ? Theme.bluetoothColor : (BluetoothService.powered ? Theme.fontColor : Theme.inactiveTextColor)
                onClicked: (mouse) => QuickSettingsService.toggle("bluetooth")
            }

            ClusterSubWidget {
                id: batSubBtn
                visible: WidgetSettings.enableBattery && !HyprlandService.isFullscreen
                iconText: Theme.batteryStatusIcon(root.batPercent, root.batState, root.acOnline)
                iconColor: Theme.batteryStatusColor(root.batPercent, root.batState, root.acOnline)
                labelVisible: root.batPercent <= 20
                label: (root.batPercent >= 0 ? root.batPercent : 0) + "%"
                labelColor: Theme.batteryStatusColor(root.batPercent, root.batState, root.acOnline)
                labelFont.weight: Font.Bold

                SequentialAnimation on opacity {
                    running: root.batState === "charging" && root.batPercent < 100
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.4; duration: 600 }
                    NumberAnimation { from: 0.4; to: 1.0; duration: 600 }
                }

                onClicked: QuickSettingsService.toggle("battery")
            }

            ClusterSubWidget {
                iconText: "󰐥"
                hoverIconColor: Theme.powerRed
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        QuickSettingsService.toggle("power");
                    } else if (mouse.button === Qt.RightButton) {
                        powerExec.running = false;
                        powerExec.running = true;
                    }
                }
            }
        }
    }

    Process {
        id: micMuteExec
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
    }

    Process {
        id: muteExec
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
    }

    Process {
        id: powerExec
        command: ["wlogout"]
    }
}
