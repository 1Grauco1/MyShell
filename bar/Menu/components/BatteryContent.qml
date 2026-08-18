import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: Theme.scaled(25)
    Layout.fillWidth: true

    opacity: 0
    scale: 0.98
    Component.onCompleted: {
        entryAnim.start();
    }
    ParallelAnimation {
        id: entryAnim
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: 400; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale"; to: 1; duration: 500; easing.type: Theme.elasticEasing }
    }

    readonly property bool isLimitActive: (BatteryService.status === "not charging" || BatteryService.status === "full") && BatteryService.acOnline
    readonly property real displayVoltage: BatteryService.voltage > 1000 ? BatteryService.voltage / 1000000 : BatteryService.voltage
    readonly property real displayWatts: BatteryService.energyRate > 1000 ? BatteryService.energyRate / 1000000 : BatteryService.energyRate

    Text {
        text: "ENERGY STATION"
        color: Theme.blue
        font.pixelSize: 10
        font.weight: Font.Black
        font.letterSpacing: 2
        Layout.leftMargin: Theme.scaled(5)
    }

    // Main Card
    Rectangle {
        Layout.fillWidth: true
        height: Theme.scaled(140)
        color: Qt.rgba(0,0,0,0.2)
        radius: Theme.scaled(24)
        border.color: Theme.glassBorder
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.scaled(20)
            spacing: Theme.scaled(25)

            Rectangle {
                width: Theme.scaled(80); height: Theme.scaled(80); radius: 40
                color: Qt.rgba(1,1,1,0.05)
                Text {
                    anchors.centerIn: parent
                    text: BatteryService.acOnline ? "󱐋" : "󰁹"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(32)
                    color: BatteryService.acOnline ? Theme.powerGreen : Theme.blue
                }
            }

            ColumnLayout {
                spacing: 5; Layout.fillWidth: true
                RowLayout {
                    spacing: 15
                    Text { text: BatteryService.percentage + "%"; font.pixelSize: Theme.scaled(38); font.weight: Font.Black; color: Theme.text }
                    Rectangle {
                        height: 22; width: pillText.implicitWidth + 30; radius: 11
                        color: BatteryService.acOnline ? Theme.powerGreen : Theme.surface1
                        Text { id: pillText; anchors.centerIn: parent; text: BatteryService.acOnline ? "PLUGGED" : "DISCHARGING"; color: BatteryService.acOnline ? Colors.background : Theme.text; font.weight: Font.Black; font.pixelSize: 9 }
                    }
                }
                Text { text: (root.isLimitActive ? "Conservative" : BatteryService.status).toUpperCase(); font.pixelSize: 10; font.weight: Font.Black; color: Theme.subtext1 }
                
                Rectangle {
                    Layout.fillWidth: true; Layout.topMargin: 10; height: 8; radius: 4; color: Qt.rgba(1,1,1,0.1)
                    Rectangle {
                        width: parent.width * (BatteryService.percentage / 100); height: parent.height; radius: 4
                        color: BatteryService.acOnline ? Theme.powerGreen : (BatteryService.percentage <= 20 ? Theme.red : Theme.accentColor)
                        Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }

    // Info Grid
    RowLayout {
        Layout.fillWidth: true; spacing: 15
        StatCard { label: "CYCLES"; value: BatteryService.cycleCount; icon: "󱂇"; accent: Theme.mauve }
        StatCard { label: "REMAINING"; value: root.isLimitActive ? "N/A" : (BatteryService.timeRemaining || "..."); icon: "󰥔"; accent: Theme.blue }
    }

    component StatCard: Rectangle {
        property string label; property var value; property string icon; property color accent
        Layout.fillWidth: true; height: 90; color: Qt.rgba(1,1,1,0.03); radius: 20; border.color: Theme.glassBorder
        ColumnLayout {
            anchors.centerIn: parent; spacing: 5
            Text { text: icon; font.family: Theme.iconFont; font.pixelSize: 24; color: accent; Layout.alignment: Qt.AlignHCenter }
            Text { text: value; color: Theme.text; font.weight: Font.Black; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }
            Text { text: label; color: Theme.subtext1; font.pixelSize: 8; font.weight: Font.Black; Layout.alignment: Qt.AlignHCenter }
        }
    }

    // Bottom Detailed Grid
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.scaled(64)
        color: Theme.surface0
        radius: Theme.scaled(18)
        border.color: Theme.surface1

        RowLayout {
            anchors.fill: parent
            spacing: 0

            StatItem {
                label: "VOLTAGE"
                value: root.displayVoltage.toFixed(1) + "V"
                valueColor: Theme.text
            }
            Divider {}
            StatItem {
                label: "WATTAGE"
                value: root.displayWatts.toFixed(1) + "W"
                valueColor: Theme.text
            }
            Divider {}
            StatItem {
                label: "HEALTH"
                value: BatteryService.health.toFixed(0) + "%"
                valueColor: BatteryService.health > 80 ? Theme.powerGreen : (BatteryService.health > 50 ? Theme.powerYellow : Theme.powerRed)
            }
            Divider {}
            StatItem {
                label: "TEMP"
                value: (BatteryService.temp > 0 ? BatteryService.temp.toFixed(1) : "35.0") + "°C"
                valueColor: BatteryService.temp > 45 ? Theme.powerRed : Theme.text
            }
        }
    }

    component StatItem: ColumnLayout {
        property string label; property string value; property color valueColor
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.scaled(2)

        Text {
            Layout.fillWidth: true
            text: value
            color: valueColor
            font.bold: true
            font.pixelSize: Theme.scaled(16)
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            Layout.fillWidth: true
            text: label
            color: Theme.subtext1
            font.pixelSize: Theme.scaled(8)
            font.weight: Font.Black
            font.letterSpacing: 1
            horizontalAlignment: Text.AlignHCenter
        }
    }

    component Divider: Rectangle {
        Layout.fillHeight: true
        Layout.topMargin: Theme.scaled(12)
        Layout.bottomMargin: Theme.scaled(12)
        implicitWidth: 1
        color: Qt.rgba(1, 1, 1, 0.08)
    }
}
