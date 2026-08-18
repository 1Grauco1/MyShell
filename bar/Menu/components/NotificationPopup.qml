import "../../../services"
import "../../../Settings"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../.."

PanelWindow {
    id: popupStack

    readonly property bool useFullscreenLayout: NotificationSettings.fullscreenNotification
    readonly property bool isFullscreen: HyprlandService.isFullscreen

    property var barRef: null
    property var osdRef: null


    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Standard popup position (top-right)
    anchors {
        top: true
        right: true
    }

    WlrLayershell.margins {
        top: popupStack.isFullscreen ? ((osdRef && osdRef.visible) ? Theme.scaled(40) : - (barRef ? barRef.height : Theme.barHeight)) : ((osdRef && osdRef.visible) ? Theme.scaled(105) : Theme.scaled(10))
        right: popupStack.isFullscreen ? Theme.scaled(5) : Theme.scaled(10)
    }

    implicitWidth: Theme.scaled(400)
    // Use a stable height to avoid Wayland resize overhead during hover expansion
    implicitHeight: activeNotifications.count > 0 ? Theme.scaled(800) : 0
    
    visible: activeNotifications.count > 0 && (!popupStack.isFullscreen || popupStack.useFullscreenLayout)
    color: "transparent"

    // Only capture input where notifications actually are
    mask: Region {
        item: mainColumn
    }

    ListModel {
        id: activeNotifications
    }

    // The layout remains "the same"
    ColumnLayout {
        id: mainColumn
        width: Theme.scaled(400)
        spacing: Theme.scaled(10)

        Repeater {
            model: activeNotifications
            delegate: NotificationItem {
                notification: activeNotifications.get(index)
                Layout.fillWidth: true
                onAutoDismissed: (id) => NotificationService.dismissNotification(id)
            }
        }
    }

    Connections {
        function upsert(notifData) {
            for (let i = 0; i < activeNotifications.count; i++) {
                if (activeNotifications.get(i).id === notifData.id) {
                    activeNotifications.set(i, notifData);
                    return;
                }
            }
            activeNotifications.append(notifData);
        }

        function onNotificationReceived(notifData) {
            upsert(notifData);
        }

        function onNotificationUpdated(notifData) {
            upsert(notifData);
        }

        function onNotificationDismissed(id) {
            for (let i = 0; i < activeNotifications.count; i++) {
                if (activeNotifications.get(i).id === id) {
                    activeNotifications.remove(i);
                    break;
                }
            }
        }

        target: NotificationService
    }
}
