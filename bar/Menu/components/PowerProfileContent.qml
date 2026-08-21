pragma ComponentBehavior: Bound
import "../../.."
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: Theme.scaled(20)
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

    // Header Row
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.scaled(5)
        Layout.rightMargin: Theme.scaled(5)

        Text {
            text: "POWER PROFILES"
            color: Colors.primary
            font.pixelSize: Theme.scaled(10)
            font.weight: Font.Black
            font.letterSpacing: 2
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            radius: Theme.scaled(10)
            color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.15)
            border.width: 1
            border.color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.3)
            implicitHeight: Theme.scaled(22)
            implicitWidth: activeLabel.implicitWidth + Theme.scaled(16)

            Text {
                id: activeLabel
                anchors.centerIn: parent
                text: PowerProfileService.currentProfile.toUpperCase()
                color: Theme.accentColor
                font.pixelSize: Theme.scaled(9)
                font.weight: Font.Bold
            }
        }
    }

    // 2x2 Grid of Power Profile Cards
    GridLayout {
        columns: (Theme.isSmallScreen && Theme.isPortrait) ? 1 : 2
        Layout.fillWidth: true
        rowSpacing: Theme.scaled(12)
        columnSpacing: Theme.scaled(12)

        Repeater {
            model: [
                { id: "performance", icon: "󰀦", color: Theme.powerRed, label: "PERFORMANCE", desc: "Max Speed & Power" },
                { id: "balanced",    icon: "󰏤", color: Colors.primary, label: "BALANCED", desc: "Optimal Performance" },
                { id: "powersave",   icon: "󰍛", color: Theme.powerGreen, label: "POWER SAVER", desc: "Extended Battery Life" },
                { id: "turbo",       icon: "󰞃", color: Theme.powerYellow, label: "TURBO", desc: "Peak Boost Mode" }
            ]

            delegate: Rectangle {
                id: profileCard
                required property var modelData

                Layout.fillWidth: true
                height: Theme.scaled(82)
                color: PowerProfileService.currentProfile === modelData.id ? 
                       Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.18) : 
                       Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.4)
                radius: Theme.scaled(18)
                border.width: PowerProfileService.currentProfile === modelData.id ? 2 : 1
                border.color: PowerProfileService.currentProfile === modelData.id ? modelData.color : Theme.glassBorder

                scale: m.pressed ? 0.96 : (m.containsMouse ? 1.015 : 1.0)
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Theme.elasticEasing } }
                Behavior on color { ColorAnimation { duration: 250 } }

                MouseArea {
                    id: m
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: PowerProfileService.setProfile(modelData.id)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.scaled(12)
                    spacing: Theme.scaled(12)

                    Rectangle {
                        width: Theme.scaled(44); height: Theme.scaled(44); radius: Theme.scaled(14)
                        color: PowerProfileService.currentProfile === modelData.id ? modelData.color : Qt.rgba(1,1,1,0.06)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(20)
                            color: PowerProfileService.currentProfile === modelData.id ? Colors.background : modelData.color
                        }
                    }

                    ColumnLayout {
                        spacing: Theme.scaled(2)
                        Layout.fillWidth: true

                        RowLayout {
                            spacing: Theme.scaled(6)
                            Text {
                                text: modelData.label
                                font.pixelSize: Theme.scaled(11)
                                font.weight: Font.Black
                                color: Colors.on_background
                            }

                            Rectangle {
                                visible: PowerProfileService.currentProfile === modelData.id
                                width: Theme.scaled(6); height: Theme.scaled(6); radius: 3
                                color: modelData.color
                            }
                        }

                        Text {
                            text: modelData.desc
                            font.pixelSize: Theme.scaled(9)
                            color: Colors.on_surface_variant
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    // Live System Resource Stats
    Rectangle {
        Layout.fillWidth: true
        height: Theme.scaled(166)
        radius: Theme.scaled(18)
        color: Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.4)
        border.width: 1
        border.color: Theme.glassBorder

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.scaled(14)
            spacing: Theme.scaled(10)

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(8)

                Text {
                    text: "LIVE SYSTEM"
                    color: Colors.primary
                    font.pixelSize: Theme.scaled(9)
                    font.weight: Font.Black
                    font.letterSpacing: 2
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: ResourceService.cpuModel + " · " + ResourceService.freq
                    color: Colors.on_surface_variant
                    font.pixelSize: Theme.scaled(8)
                    elide: Text.ElideRight
                    Layout.maximumWidth: Theme.scaled(200)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(12)

                StatBlock {
                    label: "CPU"; icon: ""
                    value: ResourceService.cpu; suffix: "%"
                    accent: Theme.powerRed
                    detail: "FREQ " + ResourceService.freq
                }
                StatBlock {
                    label: "RAM"; icon: "󰍛"
                    value: ResourceService.mem; suffix: "%"
                    accent: Theme.powerGreen
                    detail: ResourceService.memUsed + " / " + ResourceService.memTotal + " GB"
                }
                StatBlock {
                    label: "TEMP"; icon: ""
                    value: ResourceService.temp; suffix: "°C"
                    accent: ResourceService.temp > 70 ? Theme.powerRed : Theme.powerYellow
                    detail: ResourceService.temp > 75 ? "HOT" : (ResourceService.temp > 60 ? "WARM" : "NORMAL")
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.glassBorder
                opacity: 0.5
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(8)

                Text {
                    text: "CORES"
                    color: Colors.on_surface_variant
                    font.pixelSize: Theme.scaled(7)
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    Layout.alignment: Qt.AlignVCenter
                }

                Repeater {
                    model: ResourceService.coreUsages
                    delegate: Rectangle {
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredWidth: Theme.scaled(8)
                        Layout.minimumWidth: Theme.scaled(3)
                        height: Theme.scaled(24)
                        radius: Theme.scaled(3)
                        color: Qt.rgba(1, 1, 1, 0.06)

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            height: Math.max(Theme.scaled(3), parent.height * (modelData / 100))
                            radius: Theme.scaled(3)
                            color: modelData > 85 ? Theme.powerRed : (modelData > 50 ? Theme.powerYellow : Colors.primary)
                            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }

    // --- StatBlock Component ---
    component StatBlock: ColumnLayout {
        id: block
        property string label
        property string icon
        property int value
        property string suffix
        property color accent
        property string detail

        Layout.fillWidth: true
        spacing: Theme.scaled(5)

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(6)

            Text { text: block.icon; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(13); color: block.accent }
            Text {
                text: block.label
                color: Colors.on_surface_variant
                font.pixelSize: Theme.scaled(8)
                font.weight: Font.Bold
                font.letterSpacing: 1.5
                Layout.fillWidth: true
            }
            Text {
                text: block.value + block.suffix
                color: Colors.on_background
                font.pixelSize: Theme.scaled(16)
                font.weight: Font.Black
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: Theme.scaled(4)
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.08)

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * Math.min(block.value / 100, 1.0)
                height: parent.height
                radius: 2
                color: block.accent
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }

        Text {
            text: block.detail
            color: block.accent
            font.pixelSize: Theme.scaled(8)
            font.weight: Font.Medium
        }
    }
}