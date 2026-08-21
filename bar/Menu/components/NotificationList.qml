pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../../../services"
import "../../../"

Flickable {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    contentHeight: mainLayout.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: mainLayout
        width: parent.width
        spacing: Theme.scaled(16)

        // The List
        ColumnLayout {
            id: notificationsColumn
            Layout.fillWidth: true
            spacing: Theme.scaled(8)

            Repeater {
                model: NotificationService.notifications
                delegate: NotificationItem {
                    required property int index

                    notification: NotificationService.notifications.get(index)
                    Layout.fillWidth: true
                    enableAutoDismiss: false
                }
            }
        }

        // Empty State
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.scaled(200)
            visible: NotificationService.notifications.count === 0
            Layout.alignment: Qt.AlignHCenter 
            spacing: Theme.scaled(8)
            opacity: 0.5
            
            Text {
                text: "󰂚"
                font.pixelSize: Theme.scaled(80)
                color: Colors.surface_variant
                Layout.alignment: Qt.AlignCenter
            }
            Text {
                text: "All caught up"
                color: Colors.outline
                font.pixelSize: Theme.scaled(13)
                Layout.alignment: Qt.AlignCenter
            }
        }

        Item { Layout.fillHeight: true }
    }

    function resetScroll() {
        root.contentY = 0;
    }
}