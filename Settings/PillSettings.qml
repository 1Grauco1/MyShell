pragma Singleton
import "."
import QtQuick

QtObject {
    property int height: SettingsStore.get("pill.height", 30)
    onHeightChanged: SettingsStore.set("pill.height", height)
    property int radius: SettingsStore.get("pill.radius", 16)
    onRadiusChanged: SettingsStore.set("pill.radius", radius)
    property int padding: SettingsStore.get("pill.padding", 16)
    onPaddingChanged: SettingsStore.set("pill.padding", padding)
    property int extraPadding: SettingsStore.get("pill.extraPadding", 5)
    onExtraPaddingChanged: SettingsStore.set("pill.extraPadding", extraPadding)
    property int spacing: SettingsStore.get("pill.spacing", 4)
    onSpacingChanged: SettingsStore.set("pill.spacing", spacing)
    property int gap: SettingsStore.get("pill.gap", 6)
    onGapChanged: SettingsStore.set("pill.gap", gap)
    property int borderWidth: SettingsStore.get("pill.borderWidth", 1)
    onBorderWidthChanged: SettingsStore.set("pill.borderWidth", borderWidth)
    property int hoverBorderWidth: SettingsStore.get("pill.hoverBorderWidth", 2)
    onHoverBorderWidthChanged: SettingsStore.set("pill.hoverBorderWidth", hoverBorderWidth)
}
