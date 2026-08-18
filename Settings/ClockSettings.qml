import QtQuick
import Quickshell
pragma Singleton
import "."

QtObject {
    // enable / disable
    property bool showClock: SettingsStore.get("clock.showClock", true)
    onShowClockChanged: SettingsStore.set("clock.showClock", showClock)
    property bool showDate: SettingsStore.get("clock.showDate", true)
    onShowDateChanged: SettingsStore.set("clock.showDate", showDate)
    // time format
    property bool use24Hour: SettingsStore.get("clock.use24Hour", false)
    onUse24HourChanged: SettingsStore.set("clock.use24Hour", use24Hour)
    // formats
    property string dateFormat: SettingsStore.get("clock.dateFormat", "ddd dd")
    onDateFormatChanged: SettingsStore.set("clock.dateFormat", dateFormat)
    property string timeFormat12h: SettingsStore.get("clock.timeFormat12h", "hh:mm AP")
    onTimeFormat12hChanged: SettingsStore.set("clock.timeFormat12h", timeFormat12h)
    property string timeFormat24h: SettingsStore.get("clock.timeFormat24h", "hh:mm")
    onTimeFormat24hChanged: SettingsStore.set("clock.timeFormat24h", timeFormat24h)
    // precision
    property int precision: SettingsStore.get("clock.precision", SystemClock.Minutes)
    onPrecisionChanged: SettingsStore.set("clock.precision", precision)
}
