pragma Singleton
import "."
import QtQuick

QtObject {
    // Configurable intervals for recurring & repeating tasks (ms)
    property int fastPollInterval: SettingsStore.get("task.fastPollInterval", 1500)
    onFastPollIntervalChanged: SettingsStore.set("task.fastPollInterval", fastPollInterval)
    property int mediumPollInterval: SettingsStore.get("task.mediumPollInterval", 4000)
    onMediumPollIntervalChanged: SettingsStore.set("task.mediumPollInterval", mediumPollInterval)
    property int slowPollInterval: SettingsStore.get("task.slowPollInterval", 15000)
    onSlowPollIntervalChanged: SettingsStore.set("task.slowPollInterval", slowPollInterval)
    property int lazyPollInterval: SettingsStore.get("task.lazyPollInterval", 60000)
    onLazyPollIntervalChanged: SettingsStore.set("task.lazyPollInterval", lazyPollInterval)
    property int idlePollInterval: SettingsStore.get("task.idlePollInterval", 600000)
    onIdlePollIntervalChanged: SettingsStore.set("task.idlePollInterval", idlePollInterval)
}
