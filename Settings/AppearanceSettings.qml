pragma Singleton
import "."
import QtQuick

QtObject {
    id: appearanceSettings
    property real menuOpacity: SettingsStore.get("appearance.menuOpacity", 0.8)
    onMenuOpacityChanged: SettingsStore.set("appearance.menuOpacity", menuOpacity)
    property real settingsOpacity: SettingsStore.get("appearance.settingsOpacity", 0.8)
    onSettingsOpacityChanged: SettingsStore.set("appearance.settingsOpacity", settingsOpacity)
    property real glassBlur: SettingsStore.get("appearance.glassBlur", 200)
    onGlassBlurChanged: SettingsStore.set("appearance.glassBlur", glassBlur)
    property int fontSize: SettingsStore.get("appearance.fontSize", 13)
    onFontSizeChanged: SettingsStore.set("appearance.fontSize", fontSize)
    property int iconSize: SettingsStore.get("appearance.iconSize", 15)
    onIconSizeChanged: SettingsStore.set("appearance.iconSize", iconSize)
    property string iconFont: SettingsStore.get("appearance.iconFont", "JetBrainsMono Nerd Font")
    onIconFontChanged: SettingsStore.set("appearance.iconFont", iconFont)
    property int menuRadius: SettingsStore.get("appearance.menuRadius", 24)
    onMenuRadiusChanged: SettingsStore.set("appearance.menuRadius", menuRadius)
    property int menuPadding: SettingsStore.get("appearance.menuPadding", 20)
    onMenuPaddingChanged: SettingsStore.set("appearance.menuPadding", menuPadding)
    property int menuSpacing: SettingsStore.get("appearance.menuSpacing", 15)
    onMenuSpacingChanged: SettingsStore.set("appearance.menuSpacing", menuSpacing)
}
