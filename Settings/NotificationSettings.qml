pragma Singleton
import "."
import QtQuick

QtObject {
    property bool enableNotifications: SettingsStore.get("notifications.enableNotifications", true)
    onEnableNotificationsChanged: SettingsStore.set("notifications.enableNotifications", enableNotifications)
    property bool fullscreenNotification: SettingsStore.get("notifications.fullscreenNotification", true)
    onFullscreenNotificationChanged: SettingsStore.set("notifications.fullscreenNotification", fullscreenNotification)
    property bool fullscreenOSD: SettingsStore.get("notifications.fullscreenOSD", true)
    onFullscreenOSDChanged: SettingsStore.set("notifications.fullscreenOSD", fullscreenOSD)
}
