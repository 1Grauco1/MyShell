pragma ComponentBehavior: Bound
//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import "../" as Shell
import "../Settings" as Settings
import "./settings/tabs" as Tabs

Window {
    id: win
    width: Shell.Theme.scaled(900)
    height: Shell.Theme.scaled(650)
    visible: false
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Window

    property alias currentIndex: view.currentIndex

    Rectangle {
        id: container
        anchors.fill: parent
        radius: 24
        color: Shell.Theme.settingsBackground
        border.color: Shell.Theme.glassBorder
        border.width: 1
        
        // Drag handle — only consume position-change events for dragging;
        // propagate all other events so child buttons/switches receive clicks.
        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            property point lastMousePos
            onPressed: (mouse) => {
                lastMousePos = Qt.point(mouse.x, mouse.y);
                mouse.accepted = false;
            }
            onPositionChanged: (mouse) => {
                win.x += mouse.x - lastMousePos.x;
                win.y += mouse.y - lastMousePos.y;
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0
            
            // --- SIDEBAR ---
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 240
                color: Qt.rgba(0, 0, 0, 0.2)
                radius: 24
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 25
                    spacing: 12
                    
                    Text {
                        text: "G_ANT"
                        font.pixelSize: 28
                        font.weight: Font.Black
                        color: Shell.Colors.on_background
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 20
                    }
                    
                    Repeater {
                        model: [
                            { name: "General", icon: "󰘚" },
                            { name: "Bar", icon: "󰇄" },
                            { name: "Appearance", icon: "󰏘" },
                            { name: "Battery", icon: "󰁹" },
                            { name: "Media", icon: "󰎆" },
                            { name: "Hyprland", icon: "󱓞" },
                            { name: "Monitors", icon: "󰹫" }
                        ]
                        delegate: Rectangle {
                            required property int index
                            required property var modelData

                            Layout.fillWidth: true
                            height: 50
                            radius: 14
                            color: view.currentIndex === index ? Shell.Colors.surface_variant : "transparent"
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                spacing: 15
                                Text {
                                    text: modelData.icon
                                    font.family: Shell.Theme.iconFont
                                    font.pixelSize: 20
                                    color: view.currentIndex === index ? Shell.Colors.primary : Shell.Colors.on_surface_variant
                                }
                                Text {
                                    text: modelData.name
                                    font.pixelSize: 15
                                    font.weight: view.currentIndex === index ? Font.Bold : Font.Normal
                                    color: view.currentIndex === index ? Shell.Colors.on_background : Shell.Colors.on_surface_variant
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: view.currentIndex = index
                            }
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                    
                    Button {
                        text: "Close"
                        Layout.fillWidth: true
                        flat: true
                        contentItem: Text {
                            text: parent.text
                            color: parent.hovered ? "white" : Shell.Colors.on_surface_variant
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            radius: 12
                            color: parent.hovered ? Shell.Colors.error : "transparent"
                            border.color: parent.hovered ? "transparent" : Shell.Colors.surface_variant
                        }
                        onClicked: win.visible = false
                    }
                }
            }
            
            // --- MAIN CONTENT AREA ---
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                clip: true

                StackLayout {
                    id: view
                    anchors.fill: parent
                    anchors.margins: 10
                    currentIndex: 0
                    
                    Tabs.GeneralTab { }
                    Tabs.BarTab { }
                    Tabs.AppearanceTab { }
                    Tabs.BatteryTab { }
                    Tabs.MediaTab { }
                    Tabs.HyprlandTab { }
                    Tabs.MonitorsTab { }
                }
            }
        }
    }
}
