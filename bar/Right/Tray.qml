// bar/Right/Tray.qml
import "../.."
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

Rectangle {
    id: trayContainer

    property var menuRef

    visible: SystemTray.items.values.length > 0

    height: Theme.pillHeight
    implicitHeight: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter
    width: trayRow.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
    implicitWidth: width
    color: trayHoverArea.containsMouse ? Theme.pillHoverColor : Theme.pillColor
    radius: Theme.pillRadius
    border.color: Theme.glassBorder
    border.width: 1
    scale: trayHoverArea.pressed ? 0.96 : (trayHoverArea.containsMouse ? 1.02 : 1.0)

    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    MouseArea {
        id: trayHoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    RowLayout {
        id: trayRow
        anchors.centerIn: parent
        spacing: Theme.scaled(4)

        Repeater {
            model: SystemTray.items

            delegate: TrayItem {
                item: modelData
                menuRef: trayContainer.menuRef
            }
        }
    }
}
