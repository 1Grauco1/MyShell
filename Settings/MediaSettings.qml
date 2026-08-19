pragma Singleton
import "."
import QtQuick

QtObject {
    property bool truncateTrackTitle: SettingsStore.get("media.truncateTrackTitle", true)
    onTruncateTrackTitleChanged: SettingsStore.set("media.truncateTrackTitle", truncateTrackTitle)
    property int maxTrackTitleLength: SettingsStore.get("media.maxTrackTitleLength", 40)
    onMaxTrackTitleLengthChanged: SettingsStore.set("media.maxTrackTitleLength", maxTrackTitleLength)
    property bool autoManageMediaFocus: SettingsStore.get("media.autoManageMediaFocus", true)
    onAutoManageMediaFocusChanged: SettingsStore.set("media.autoManageMediaFocus", autoManageMediaFocus)
    property int barMargins: SettingsStore.get("media.barMargins", 10)
    onBarMarginsChanged: SettingsStore.set("media.barMargins", barMargins)
    property bool showVolumeControl: SettingsStore.get("media.showVolumeControl", true)
    onShowVolumeControlChanged: SettingsStore.set("media.showVolumeControl", showVolumeControl)
    property bool showLoopControl: SettingsStore.get("media.showLoopControl", true)
    onShowLoopControlChanged: SettingsStore.set("media.showLoopControl", showLoopControl)
}
