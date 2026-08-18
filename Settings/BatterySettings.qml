pragma Singleton
import "."
import QtQuick

QtObject {
    property int high: SettingsStore.get("battery.high", 80)
    onHighChanged: SettingsStore.set("battery.high", high)
    property int midHigh: SettingsStore.get("battery.midHigh", 60)
    onMidHighChanged: SettingsStore.set("battery.midHigh", midHigh)
    property int mid: SettingsStore.get("battery.mid", 40)
    onMidChanged: SettingsStore.set("battery.mid", mid)
    property int low: SettingsStore.get("battery.low", 20)
    onLowChanged: SettingsStore.set("battery.low", low)
    property int critical: SettingsStore.get("battery.critical", 10)
    onCriticalChanged: SettingsStore.set("battery.critical", critical)
    property int barMargins: SettingsStore.get("battery.barMargins", 10)
    onBarMarginsChanged: SettingsStore.set("battery.barMargins", barMargins)
}
